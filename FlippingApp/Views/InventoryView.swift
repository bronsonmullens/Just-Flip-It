//
//  InventoryView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 5/4/24.
//

import SwiftUI
import SwiftData

fileprivate enum ViewMode: String, CaseIterable, Equatable {
    case viewBasic = "Basic View"
    case viewDetailed = "Detailed View"
    case grid = "Grid View"
}

fileprivate enum SortMode: String, CaseIterable, Equatable {
    case alphabeticalAscending = "A to Z"
    case alphabeticalDescending = "Z to A"
    case listedPriceHighest = "Highest Price"
    case listedPriceLowest = "Lowest Price"
    case highestQuantity = "Highest Quantity"
    case lowestQuantity = "Lowest Quantity"
    case dateAddedMostRecent = "Most Recent"
    case dateAddedOldest = "Oldest"
}

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var itemController: ItemController
    
    @Query private var items: [Item]
    
    @AppStorage("viewMode") private var viewMode: ViewMode = .viewBasic
    @AppStorage("sortMode") private var sortMode: SortMode = .dateAddedMostRecent
    
    @State var searchMode: SearchMode
    @State private var searchByTag: Bool = false
    @State private var searchText: String = ""
    @State private var showingItemDeletionAlert: Bool = false
    @State private var itemToDelete: Item?
    @State private var editingItem: Bool = false
    @State var sellMode: Bool
    
    private var sortedItems: [Item] {
        return items.sorted(using: sortDescriptors)
    }
    
    private var columns: [GridItem] {
        Array(repeatElement(GridItem(.flexible()), count: 2))
    }
    
    private var filteredItems: [Item] {
        switch searchMode {
        case .inventory:
            if searchText.isEmpty {
                return sortedItems.filter({(item: Item) -> Bool in
                    return item.soldPrice == nil
                })
            }
            
            if searchByTag {
                return sortedItems.filter({(item: Item) -> Bool in
                    return item.tag?.title.range(of: searchText, options: .caseInsensitive) != nil && item.soldPrice == nil
                })
            } else {
                return sortedItems.filter({(item: Item) -> Bool in
                    return item.title.range(of: searchText, options: .caseInsensitive) != nil && item.soldPrice == nil
                })
            }
        case .receipts:
            if searchText.isEmpty {
                return sortedItems.filter({(item: Item) -> Bool in
                    return item.soldPrice != nil
                })
            }
            
            if searchByTag {
                return sortedItems.filter({(item: Item) -> Bool in
                    return item.tag?.title.range(of: searchText, options: .caseInsensitive) != nil && item.soldPrice != nil
                })
            } else {
                return sortedItems.filter({(item: Item) -> Bool in
                    return item.title.range(of: searchText, options: .caseInsensitive) != nil && item.soldPrice != nil
                })
            }
        }
    }
    
    private var sortDescriptors: [SortDescriptor<Item>] {
        switch sortMode {
        case .alphabeticalAscending:
            return [SortDescriptor(\Item.title, order: .forward)]
        case .alphabeticalDescending:
            return [SortDescriptor(\Item.title, order: .reverse)]
        case .listedPriceHighest:
            return [SortDescriptor(\Item.listedPrice, order: .reverse)]
        case .listedPriceLowest:
            return [SortDescriptor(\Item.listedPrice, order: .forward)]
        case .dateAddedMostRecent:
            return [SortDescriptor(\Item.dateAdded, order: .reverse)]
        case .dateAddedOldest:
            return [SortDescriptor(\Item.dateAdded, order: .forward)]
        case .highestQuantity:
            return [SortDescriptor(\Item.quantity, order: .reverse)]
        case .lowestQuantity:
            return [SortDescriptor(\Item.quantity, order: .forward)]
        }
    }
    
    private func deleteItem() {
        if let itemToDelete  {
            modelContext.delete(itemToDelete)
            log.info("Deleted \(itemToDelete.title): \(itemToDelete.id)")
            self.itemToDelete = nil
        } else {
            log.error("Could not find item to delete")
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    HStack(spacing: 0) {
                        Picker("", selection: $viewMode) {
                            ForEach(ViewMode.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: viewMode) { newViewMode in
                            self.viewMode = newViewMode
                        }
                    }
                    
                    Spacer()
                    
                    Text("Search by tag")
                    Toggle("Search by tag", isOn: $searchByTag)
                        .labelsHidden()
                        .padding(.trailing)
                    
                    Menu {
                        ForEach(SortMode.allCases, id: \.self) { sortMode in
                            Button(action: {
                                self.sortMode = sortMode
                            }, label: {
                                HStack {
                                    if self.sortMode == sortMode {
                                        Image(systemName: "checkmark")
                                    }
                                    Text(sortMode.rawValue)
                                }
                            })
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }

                }
                .padding(.horizontal)
                
                if viewMode == .viewBasic || viewMode == .viewDetailed {
                    List {
                        ForEach(filteredItems) { item in
                            InventoryRow(viewMode: $viewMode, item: item)
                                .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        self.showingItemDeletionAlert = true
                                        self.itemToDelete = item
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                    .tint(.red)
                                    
                                    if searchMode == .receipts {
                                        // TODO: Fix later
//                                        Button {
//                                            generateAndShareSellCard(for: item, quantity: item.quantity)
//                                        } label: {
//                                            Label("Sell Card", systemImage: "square.and.arrow.up.fill")
//                                        }
//                                        .tint(.green)
                                    } else {
                                        Button {
                                            itemController.duplicateItem(item)
                                        } label: {
                                            Label("Duplicate", systemImage: "doc.on.doc.fill")
                                        }
                                        .tint(.blue)
                                        
                                        NavigationLink(destination: SellItemView(item: item)) {
                                            Label("Sell", systemImage: "dollarsign.circle")
                                        }
                                        .tint(.green)
                                    }
                                }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .navigationDestination(for: Item.self) { item in
                        if sellMode {
                            SellItemView(item: item)
                        } else {
                            if item.soldPrice != nil {
                                ReceiptView(item: item)
                            } else {
                                EditInventoryItemView(item: item)
                            }
                        }
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            ForEach(filteredItems) { item in
                                InventoryGrid(item: item)
                            }
                        }
                        .navigationDestination(for: Item.self) { item in
                            
                            if sellMode {
                                SellItemView(item: item)
                            } else {
                                if item.soldPrice != nil {
                                    ReceiptView(item: item)
                                } else {
                                    EditInventoryItemView(item: item)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .background(Color("\(itemController.selectedTheme.rawValue)Background"))
        }
        .padding()
        .searchable(text: $searchText)
        .alert("Delete Item?", isPresented: $showingItemDeletionAlert) {
            Button("Yes", role: .destructive) {
                deleteItem()
            }
            
        } message: {
            Text("Are you sure you want to delete this item? This is an action that cannot be undone and you will lose this item forever.")
        }
        .background(Color("\(itemController.selectedTheme.rawValue)Background"))
    }
}

// MARK: - Inventory Views

fileprivate struct InventoryRow: View {
    @EnvironmentObject private var itemController: ItemController
    
    @Environment(\.modelContext) private var modelContext
    
    @Binding var viewMode: ViewMode
    
    private var estimatedProfit: Double {
        return itemController.calculateProfitForItem(item, quantity: item.quantity)
    }
    
    let item: Item
    
    var body: some View {
        NavigationLink(value: item) {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.headline)
                    Text("Quantity: \(item.quantity.formatted())")
                    if viewMode == .viewDetailed {
                        if let tag = item.tag {
                            Text(tag.title)
                        }
                        Text("Profit: \(estimatedProfit.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    }
                }
                
                Spacer()
                
                if let soldPrice = item.soldPrice {
                    Text("\(soldPrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))) per unit")
                } else {
                    Text("\(item.listedPrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))) per unit")
                }
            }
        }
    }
}

fileprivate struct InventoryGrid: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var itemController: ItemController
    
    let item: Item
    
    private var estimatedProfit: Double {
        return itemController.calculateProfitForItem(item, quantity: item.quantity)
    }
    
    var body: some View {
        NavigationLink(value: item) {
            VStack {
                if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                        Image(systemName: "shippingbox.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Background"))
                            .frame(width: 96)
                    }
                }
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("Quantity: \(item.quantity.formatted())")
                    .font(.caption)
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                if let soldPrice = item.soldPrice {
                    Text("\(soldPrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                } else {
                    VStack {
                        Text("\(item.listedPrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))) per unit")
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                        Text("Profit: \(estimatedProfit.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    }
                }
            }
        }
    }
}
