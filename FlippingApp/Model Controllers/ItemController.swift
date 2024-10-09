//
//  ItemController.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI
import SwiftData
import RevenueCat

class ItemController: ObservableObject {

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        compressImages()
        migrateData()
        
        Purchases.shared.getCustomerInfo { customerInfo, error in
            self.hasPremium = customerInfo?.entitlements.all["Premium"]?.isActive == true
        }
    }

    // MARK: - Properties

    var modelContainer: ModelContainer
    
    @AppStorage("selectedTheme") var selectedTheme: ColorTheme = .standard
    @Published var hasPremium: Bool = false

    // MARK: - Calculation Methods
    
    func calculateProfitForItem(_ item: Item, quantity: Int) -> Double {
        if let soldPrice = item.soldPrice {
            let platformFees = soldPrice * (item.platformFees ?? 0.0)
            let profit = (soldPrice - item.purchasePrice) - platformFees - (item.otherFees ?? 0.0)
            return profit * Double(quantity)
        } else {
            // We don't ask for fees when adding an item. This is an estimate.
            return (item.listedPrice - item.purchasePrice) * Double(quantity)
        }
    }

    func calculateProfit(using items: [Item]) -> Double {
        var profit: Double = 0.0

        for item in items {
            // If the item has a sold price, calculate the profit and add to the running total
            if item.soldPrice != nil {
                profit += calculateProfitForItem(item, quantity: item.quantity)
            }
        }

        return profit
    }

    func calculateTotalInventoryValue(for items: [Item]) -> Double {
        var totalValue: Double = 0.0

        for item in items {
            // If the item doesn't have a sold price, calculate the value and add to running total
            if item.soldPrice != nil {
                continue
            } else {
                totalValue += (Double(item.quantity) * item.listedPrice)
            }
        }

        return totalValue
    }

    func calculateTotalInvestment(for items: [Item]) -> Double {
        var totalInvestment: Double = 0.0

        for item in items {
            // If the item doesn't have a sold price, calculate the value and add to running total
            if item.soldPrice != nil {
                continue
            } else {
                totalInvestment += (Double(item.quantity) * item.purchasePrice)
            }
        }

        return totalInvestment
    }

    func calculateTotalInventoryItems(for items: [Item]) -> Int {
        var totalInventoryItems: Int = 0

        for item in items {
            if item.soldPrice != nil {
                continue
            } else {
                totalInventoryItems += item.quantity
            }
        }

        return totalInventoryItems
    }

    func calculateTotalSoldItems(for items: [Item]) -> Int {
        var totalSales: Int = 0

        for item in items {
            if item.soldPrice != nil {
                totalSales += 1
            }
        }

        return totalSales
    }

    func calculateTotalSoldItemValue(for items: [Item]) -> Double {
        var totalSoldItemValue: Double = 0.0

        for item in items {
            if let soldPrice = item.soldPrice {
                let itemValue = soldPrice - ((item.otherFees ?? 0.0) + (item.platformFees ?? 0.0))
                totalSoldItemValue += Double(item.quantity) * itemValue
            }
        }

        return totalSoldItemValue
    }
    
    // MARK: - Deletion
    
    func delete(_ deleteType: DeleteType) {
        do {
            let context = ModelContext(modelContainer)
            let inventoryItemsFetchDescriptor = FetchDescriptor<Item>(predicate: #Predicate { $0.soldPrice == nil })
            let soldItemsFetchDescriptor = FetchDescriptor<Item>(predicate: #Predicate { $0.soldPrice != nil })
            let tagsFetchDescriptor = FetchDescriptor<Tag>()
            let inventoryItems = try context.fetch(inventoryItemsFetchDescriptor)
            let soldItems = try context.fetch(soldItemsFetchDescriptor)
            let tags = try context.fetch(tagsFetchDescriptor)
            
            switch deleteType {
            case .inventory:
                for item in inventoryItems {
                    context.delete(item)
                    log.info("Deleted inventory item: \(item.title) (\(item.id)")
                }
            case .soldItems:
                for item in soldItems {
                    context.delete(item)
                    log.info("Deleted sold item: \(item.title) (\(item.id)")
                }
            case .tags:
                for tag in tags {
                    context.delete(tag)
                    log.info("Deleted tag: \(tag.title) (\(tag.id))")
                }
            case .everything:
                for item in inventoryItems {
                    context.delete(item)
                    log.info("Deleted inventory item: \(item.title) (\(item.id))")
                }
                
                for item in soldItems {
                    context.delete(item)
                    log.info("Deleted sold item: \(item.title) (\(item.id))")
                }
                
                for tag in tags {
                    context.delete(tag)
                    log.info("Deleted tag: \(tag.title) (\(tag.id))")
                }
            case .error:
                fatalError("Encountered an error when deleting items or tags.")
            }
        } catch {
            log.error("Could not delete inventory items")
        }
    }
    
    // MARK: - Other Data Methods
    
    func duplicateItem(_ item: Item) {
        let context = ModelContext(modelContainer)
        let newItem = Item(title: item.title,
                           imageData: item.imageData,
                           quantity: item.quantity,
                           deleteWhenQuantityReachesZero: item.deleteWhenQuantityReachesZero,
                           purchaseDate: item.purchaseDate,
                           purchasePrice: item.purchasePrice,
                           listedPrice: item.listedPrice,
                           tag: item.tag,
                           notes: item.notes)
        context.insert(newItem)
        log.info("Added duplicated item to inventory.")
    }
    
    func compressImages() {
        // TODO: Temporary fix because the app is running out of memory and crashing. Only fix at the moment is to compress the images.
        if let imagesWereCompressed = UserDefaults.standard.value(forKey: "imagesWereCompressed"), imagesWereCompressed as? Bool == true {
            log.debug("Aborting image compression - imagesWereCompressed")
            return
        } else {
            do {
                // 1. Fetch data
                let context = ModelContext(modelContainer)
                let inventoryItemsFetchDescriptor = FetchDescriptor<Item>(predicate: #Predicate { $0.soldPrice == nil })
                let soldItemsFetchDescriptor = FetchDescriptor<Item>(predicate: #Predicate { $0.soldPrice != nil })
                let inventoryItems = try context.fetch(inventoryItemsFetchDescriptor)
                let soldItems = try context.fetch(soldItemsFetchDescriptor)
                
                // 2. Loop through the items
                for item in inventoryItems {
                    // 3. If the item has an image, compress and replace it
                    if let imageData = item.imageData {
                        let compressedImageData = UIImage(data: imageData)?.jpegData(compressionQuality: 0.1)
                        item.imageData = compressedImageData
                        log.info("Updated \(item.title)'s image with compressed version")
                    }
                }
                
                for item in soldItems {
                    // 3. If the item has an image, compress and replace it
                    if let imageData = item.imageData {
                        let compressedImageData = UIImage(data: imageData)?.jpegData(compressionQuality: 0.2)
                        item.imageData = compressedImageData
                        log.info("Updated \(item.title)'s image with compressed version")
                    }
                }
                
                log.info("Finished image compression script.")
                
                // Image compression complete - don't do it again
                UserDefaults.standard.setValue(true, forKey: "imagesWereCompressed")
            } catch {
                log.error("Error compressing image data: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Migration

    func migrateData() {
        if let dataWasMigrated = UserDefaults.standard.value(forKey: "dataWasMigrated"), dataWasMigrated as? Bool == true {
            log.debug("Aborting data migration - dataWasMigrated is set to true")
            return
        }

        // 1. Get the URLs to fetch old data
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        log.info("Starting Data Migration in directory: \(directory)")

        let inventoryURL: URL = directory.appendingPathComponent("Inventory.plist")
        let soldItemsURL: URL = directory.appendingPathComponent("SoldItems.plist")
        let tagsURL: URL = directory.appendingPathComponent("Tags.plist")

        // 2. Decode the data
        let decoder = PropertyListDecoder()

        var oldInventory: [OldItem] = []
        var oldSoldItems: [OldItem] = []
        var oldTags: [String] = []

        do {
            let inventoryData = try Data(contentsOf: inventoryURL)
            let soldItemsData = try Data(contentsOf: soldItemsURL)
            let tagsData = try Data(contentsOf: tagsURL)

            let decodedInventory = try decoder.decode([OldItem].self, from: inventoryData)
            let decodedSoldItems = try decoder.decode([OldItem].self, from: soldItemsData)
            let decodedTags = try decoder.decode([String].self, from: tagsData)
            oldInventory = decodedInventory
            oldSoldItems = decodedSoldItems
            oldTags = decodedTags
        } catch {
            log.error("Failed to decode data: \(error)")
        }

        if oldInventory.isEmpty && oldSoldItems.isEmpty && oldTags.isEmpty {
            log.debug("No data found for migration")
            return
        }

        log.info("Finished unpacking old data. Migrating: \(oldInventory.count) inventory items, \(oldSoldItems.count) sold items, and \(oldTags.count) tags.")

        // 3. Convert to new models
        var newInventoryItems: [Item] = []
        var newSoldItems: [Item] = []
        var newTags: [Tag] = []

        for oldInventoryItem in oldInventory {
            let newItem = Item(title: oldInventoryItem.title,
                               imageData: nil,
                               quantity: oldInventoryItem.quantity,
                               deleteWhenQuantityReachesZero: true,
                               purchaseDate: oldInventoryItem.listedDate ?? nil,
                               purchasePrice: oldInventoryItem.purchasePrice,
                               listedPrice: oldInventoryItem.listingPrice,
                               tag: Tag(title: oldInventoryItem.tag ?? "", id: UUID().uuidString),
                               notes: oldInventoryItem.notes ?? "")

            newInventoryItems.append(newItem)
        }

        for oldSoldItem in oldSoldItems {
            let newItem = Item(title: oldSoldItem.title,
                               imageData: nil,
                               quantity: oldSoldItem.quantity,
                               deleteWhenQuantityReachesZero: true,
                               purchaseDate: nil,
                               purchasePrice: oldSoldItem.purchasePrice,
                               listedPrice: oldSoldItem.listingPrice,
                               tag: Tag(title: oldSoldItem.tag ?? "", id: UUID().uuidString),
                               notes: oldSoldItem.notes ?? "",
                               soldDate: oldSoldItem.soldDate,
                               platformFees: 0.0,
                               otherFees: 0.0,
                               soldPrice: oldSoldItem.soldPrice)

            newSoldItems.append(newItem)
        }

        for oldTag in oldTags {
            let newTag = Tag(title: oldTag, id: UUID().uuidString)
            newTags.append(newTag)
        }

        log.info(">>> Migrated data: \(newInventoryItems.count) inventory items, \(newSoldItems.count) sold items, and \(newTags.count) tags.")

        // 4. Save new arrays to SwiftData
        do {
            let context = ModelContext(modelContainer)

            for item in newInventoryItems {
                context.insert(item)
            }

            for item in newSoldItems {
                context.insert(item)
            }

            try context.save()

        } catch {
            fatalError(">>> ERROR SAVING CONTENT: \(error)")
        }

        // Data migration complete - don't do it again
        UserDefaults.standard.setValue(true, forKey: "dataWasMigrated")
    }
}
