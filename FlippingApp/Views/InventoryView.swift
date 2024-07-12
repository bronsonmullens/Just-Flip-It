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

enum SearchMode {
    case inventory
    case receipts
}

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @AppStorage("viewMode") private var viewMode: ViewMode = .viewBasic
    
    @State var searchMode: SearchMode
    @State private var searchByTag: Bool = false
    @State private var searchText: String = ""
    @State private var showingItemDeletionAlert: Bool = false
    @State private var indexSetOfItemsToDelete: IndexSet?
    @State private var editingItem: Bool = false
    
    private var columns: [GridItem] {
        Array(repeatElement(GridItem(.flexible()), count: 2))
    }
    
    private var filteredItems: [Item] {
        switch searchMode {
        case .inventory:
            if searchText.isEmpty {
                return items.filter({(item: Item) -> Bool in
                    return item.soldPrice == nil
                })
            }
            
            if searchByTag {
                return items.filter({(item: Item) -> Bool in
                    return item.tag?.title.range(of: searchText, options: .caseInsensitive) != nil && item.soldPrice == nil
                })
            } else {
                return items.filter({(item: Item) -> Bool in
                    return item.title.range(of: searchText, options: .caseInsensitive) != nil && item.soldPrice == nil
                })
            }
        case .receipts:
            if searchText.isEmpty {
                return items.filter({(item: Item) -> Bool in
                    return item.soldPrice != nil
                })
            }
            
            if searchByTag {
                return items.filter({(item: Item) -> Bool in
                    return item.tag?.title.range(of: searchText, options: .caseInsensitive) != nil && item.soldPrice != nil
                })
            } else {
                return items.filter({(item: Item) -> Bool in
                    return item.title.range(of: searchText, options: .caseInsensitive) != nil && item.soldPrice != nil
                })
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet?) {
        if let offsets = offsets {
            for offset in offsets {
                let itemToDelete = items[offset]
                modelContext.delete(itemToDelete)
                log.info("Deleted \(itemToDelete.title) (\(itemToDelete.id)")
            }
        } else {
            log.error("Did not find offsets for items to delete.")
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
                }
                .padding(.horizontal)
                
                if viewMode == .viewBasic || viewMode == .viewDetailed {
                    List {
                        ForEach(filteredItems) { item in
                            InventoryRow(viewMode: $viewMode, item: item)
                        }
                        .onDelete(perform: { indexSet in
                            self.indexSetOfItemsToDelete = indexSet
                            self.showingItemDeletionAlert = true
                        })
                    }
                    .navigationDestination(for: Item.self) { item in
                        if item.soldPrice != nil {
                            ReceiptView(item: item)
                        } else {
                            EditInventoryItemView(item: item)
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
                            if item.soldPrice != nil {
                                ReceiptView(item: item)
                            } else {
                                EditInventoryItemView(item: item)
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .searchable(text: $searchText)
        .alert("Delete Item?", isPresented: $showingItemDeletionAlert) {
            Button("Yes", role: .destructive) {
                deleteItems(at: self.indexSetOfItemsToDelete)
            }
            
        } message: {
            Text("Are you sure you want to delete this item? This is an action that cannot be undone and you will lose this item forever.")
        }
    }
}

// MARK: - Inventory Views

fileprivate struct InventoryRow: View {
    @EnvironmentObject private var itemController: ItemController
    
    @Environment(\.modelContext) private var modelContext
    
    @Binding var viewMode: ViewMode
    
    private var estimatedProfit: Double {
        return itemController.calculateProfitForItem(item)
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
                        Text("Estimated Profit: \(estimatedProfit.formatted(.currency(code: "USD")))")
                            .foregroundStyle(estimatedProfit > 0.00 ? .green : .red)
                    }
                }
                
                Spacer()
                
                if let soldPrice = item.soldPrice {
                    Text("\(soldPrice.formatted(.currency(code: "USD")))")
                } else {
                    Text("\(item.listedPrice.formatted(.currency(code: "USD")))")
                }
            }
        }
    }
}

fileprivate struct InventoryGrid: View {
    @Environment(\.modelContext) private var modelContext
    let item: Item
    
    var body: some View {
        NavigationLink(value: item) {
            VStack {
                if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(.gray)
                        Image(systemName: "shippingbox.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(.black)
                            .frame(width: 96)
                    }
                }
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.gray)
                Text("Quantity: \(item.quantity.formatted())")
                    .font(.caption)
                    .foregroundStyle(.gray)
                if let soldPrice = item.soldPrice {
                    Text("\(soldPrice.formatted(.currency(code: "USD")))")
                        .foregroundStyle(.gray)
                } else {
                    Text("\(item.listedPrice.formatted(.currency(code: "USD")))")
                        .foregroundStyle(.gray)
                }
            }
        }
        
    }
}