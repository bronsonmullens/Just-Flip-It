//
//  SearchView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI
import SwiftData

fileprivate enum SearchMode: String, CaseIterable {
    case inventory = "Inventory"
    case sold = "Sold"
}

enum InventoryFunction {
    case browse
    case sell
}

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var items: [Item]
    @Query private var tags: [Tag]
    
    @State var inventoryFunction: InventoryFunction = .browse
    @State private var searchMode: SearchMode = .inventory
    @State private var searchText: String = ""
    @State private var searchByTag: Bool = false
    @State private var presentingReceiptView: Bool = false
    @State private var presentingEditItemView: Bool = false
    
    @Binding var selectedItem: Item?
    
    private var filteredItems: [Item] {
        if searchByTag {
            switch searchMode {
            case .inventory:
                return items.filter({(item: Item) -> Bool in
                    return item.tag?.title.range(of: searchText, options: .caseInsensitive) != nil && item.soldPrice == nil
                })
            case .sold:
                return items.filter({(item: Item) -> Bool in
                    return item.tag?.title.range(of: searchText, options: .caseInsensitive) != nil && item.soldPrice != nil
                })
            }
        } else {
            switch searchMode {
            case .inventory:
                if searchText.isEmpty {
                    return items.filter({(item: Item) -> Bool in
                        return item.soldPrice == nil
                    })
                } else {
                    return items.filter({(item: Item) -> Bool in
                        return item.title.range(of: searchText, options: .caseInsensitive) != nil && item.soldPrice == nil
                    })
                }
            case .sold:
                if searchText.isEmpty {
                    return items.filter({(item: Item) -> Bool in
                        return item.soldPrice != nil
                    })
                } else {
                    return items.filter({(item: Item) -> Bool in
                        return item.title.range(of: searchText, options: .caseInsensitive) != nil && item.soldPrice != nil
                    })
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    if inventoryFunction == .browse {
                        Picker("", selection: $searchMode) {
                            ForEach(SearchMode.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        EmptyView()
                    }
                    
                    Spacer()
                    
                    Text("Search by tag")
                    Toggle("", isOn: $searchByTag).labelsHidden()
                }
                .padding(.horizontal)
                
                List(filteredItems) { item in
                    if inventoryFunction == .sell {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .font(.headline)
                                Text("Quantity: \(item.quantity)")
                            }
                            
                            Spacer()
                            
                            Text("\(item.listedPrice.formatted(.currency(code: "USD")))")
                        }
                        .onTapGesture {
                            if inventoryFunction == .sell {
                                log.info("Selected \(item.title) (\(item.id) to sell.")
                                self.selectedItem = item
                            }
                        }
                    } else {
                        NavigationLink(value: item) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                        .font(.headline)
                                    Text("Quantity: \(item.quantity)")
                                }
                                
                                Spacer()
                                
                                Text("\(item.listedPrice.formatted(.currency(code: "USD")))")
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(item)
                                log.info("Deleted \(item.title)")
                                do {
                                    try modelContext.save()
                                } catch {
                                    log.error("Could not save modelContext")
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .navigationDestination(for: Item.self) { item in
                    if inventoryFunction == .browse {
                        switch searchMode {
                        case .inventory:
                            EditInventoryItemView(item: item)
                        case .sold:
                            ReceiptView(item: item)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .searchable(text: $searchText, prompt: "Search for \(searchMode.rawValue) items")
    }
}
