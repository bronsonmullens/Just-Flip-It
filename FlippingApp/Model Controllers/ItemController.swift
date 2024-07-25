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
        migrateData()
        
        Purchases.shared.getCustomerInfo { customerInfo, error in
            self.hasPremium = customerInfo?.entitlements.all["Pro"]?.isActive == true
        }
    }

    // MARK: - Properties

    var modelContainer: ModelContainer
    
    @AppStorage("selectedTheme") var selectedTheme: ColorTheme = .standard
    @Published var hasPremium: Bool = false

    // MARK: - Calculation Methods
    
    func calculateProfitForItem(_ item: Item, quantity: Int) -> Double {
        if let soldPrice = item.soldPrice {
            let fee: Double = soldPrice * ((item.platformFees ?? 0.0) / 100)
            let itemValue: Double = (soldPrice - fee) - item.purchasePrice - (item.otherFees ?? 0.0)
            return itemValue * Double(quantity)
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
            } else {
                
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

    // MARK: - Migration

    func migrateData() {
        if let dataWasMigrated = UserDefaults.standard.value(forKey: "dataWasMigrated"), dataWasMigrated as! Bool == true {
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

            // TODO: Explicitly inserting tags here seems to create duplicates even though array size is correct

            try context.save()

        } catch {
            fatalError(">>> ERROR SAVING CONTENT: \(error)")
        }

        // Data migration complete - don't do it again
        UserDefaults.standard.setValue(true, forKey: "dataWasMigrated")
    }
    
    // MARK: - Dummy Data
    func createDummyItems() -> [Item] {
        let dummyTitles = ["Vintage Watch", "Antique Vase", "Rare Comic Book", "Collectible Action Figure", "Signed Baseball", "First Edition Book", "Retro Video Game Console", "Vinyl Record", "Vintage Camera", "Antique Furniture Piece", "Art Print", "Rare Coin", "Vintage Jewelry", "Classic Movie Poster", "Collectible Stamp"]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.date(from: "2024-01-01")!
        let endDate = dateFormatter.date(from: "2024-07-24")!
        
        var items: [Item] = []
        
        for _ in 1...50 {
            let title = dummyTitles.randomElement()!
            let purchaseDate = Date.random(in: startDate...endDate)
            let purchasePrice = Double.random(in: 10...500).rounded(to: 2)
            let listedPrice = purchasePrice * Double.random(in: 1.1...2.0).rounded(to: 2)
            let quantity = Int.random(in: 1...10)
            let notes = "This is a dummy item for \(title)"
            
            var soldDate: Date?
            var soldPrice: Double?
            
            // 50% chance of item being sold
            if Bool.random() {
                soldDate = Date.random(in: purchaseDate...endDate)
                soldPrice = listedPrice * Double.random(in: 0.8...1.2).rounded(to: 2)
            }
            
            let item = Item(
                title: title,
                imageData: nil,
                quantity: quantity,
                purchaseDate: purchaseDate,
                purchasePrice: purchasePrice,
                listedPrice: listedPrice,
                notes: notes,
                soldDate: soldDate,
                soldPrice: soldPrice
            )
            
            items.append(item)
        }
        
        return items
    }
}

enum DeleteType: String {
    case inventory = "Inventory"
    case soldItems = "Sold Items"
    case tags = "Tags"
    case everything = "Everything"
    case error = "Error"
}

// Helper extension for random date generation
extension Date {
    static func random(in range: ClosedRange<Date>) -> Date {
        let diff = range.upperBound.timeIntervalSinceReferenceDate - range.lowerBound.timeIntervalSinceReferenceDate
        let randomValue = Double.random(in: 0..<diff)
        return Date(timeIntervalSinceReferenceDate: range.lowerBound.timeIntervalSinceReferenceDate + randomValue)
    }
}

// Helper extension for rounding Doubles
extension Double {
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
