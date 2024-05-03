//
//  SellInventoryItemView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 10/2/23.
//

import SwiftUI
import SwiftData

fileprivate enum SellItemError: String {
    case invalidQuantity = "Make sure your quantity is greater than 0 and not greater than your available stock."
}

struct SellInventoryItemView: View {
    @Query private var items: [Item]
    @Query private var tags: [Tag]
    
    @Binding var isPresented: Bool
    
    @State private var selectedItem: Item?
    
    var body: some View {
        if let selectedItem = selectedItem {
            SellItemView(item: $selectedItem.toUnwrapped(defaultValue: Item(title: "", id: "", quantity: -1, purchaseDate: Date(), purchasePrice: 0.00, listedPrice: 0.00, notes: "")))
        } else {
            SearchView(inventoryFunction: .sell, selectedItem: $selectedItem)
        }
    }
}

struct SellItemView: View {
    @EnvironmentObject private var itemController: ItemController
    @Environment(\.modelContext) private var modelContext
    
    @Binding var item: Item // TODO: Change to binding
    
    @State private var quantityToSell: Int = 0
    @State private var priceSoldAt: Double = 0.0
    @State private var saleDate: Date = Date()
    @State private var notes: String = ""
    
    private var sellButtonEnabled: Bool {
        // Use similar item validation to editinventoryitem and maybe even combine logic in itemController
        if quantityToSell > item.quantity && quantityToSell > 0 {
            log.error("Invalid quantity")
            return false
        }
        
        return true
    }
    
    private func processSale() {
        let soldItem = Item(title: item.title,
                            id: UUID().uuidString,
                            quantity: quantityToSell,
                            purchaseDate: item.purchaseDate,
                            purchasePrice: item.purchasePrice,
                            listedPrice: item.listedPrice,
                            tag: item.tag,
                            notes: notes,
                            soldDate: saleDate,
                            soldPrice: priceSoldAt)
        modelContext.insert(soldItem)
        self.item.quantity -= quantityToSell
        if item.automaticallyDeleteWhenStockDepleted && item.quantity <= 0 {
            modelContext.delete(item)
            log.info("Deleted item with depleted stock: \(item.title)")
        }
        log.info("Created new soldItem: \(soldItem.title) (\(soldItem.id)")
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(item.title)
                    .font(.title)
                Spacer()
                Button(action: {
                    processSale()
                }, label: {
                    Text("Sell")
                })
            }
            
            Form {
                Section {
                    HStack {
                        Text("Quantity owned:")
                        Text("\(item.quantity)")
                    }
                    .foregroundStyle(.gray)
                    
                    HStack {
                        Text("Quantity to sell:")
                        TextField("", value: $quantityToSell, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section {
                    HStack {
                        Text("Purchase Price:")
                        Text("\(item.purchasePrice.formatted(.currency(code: "USD")))")
                    }
                    .foregroundStyle(.gray)
                    
                    HStack {
                        Text("Sold Price:")
                        TextField("$0.00", value: $priceSoldAt, format: .currency(code: "USD"))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        // TODO: Support quantities
                        Text("Net Profit:")
                        Text("\((priceSoldAt - item.purchasePrice).formatted(.currency(code: "USD")))")
                            .foregroundStyle(priceSoldAt - item.purchasePrice >= 0.0 ? .green : .red)
                    }
                }
                
                Section {
                    if let purchaseDate = item.purchaseDate {
                        HStack {
                            Text("Originally purchased:")
                            Text("\(purchaseDate.formatted(.dateTime.day().month().year()))")
                        }
                        .foregroundStyle(.gray)
                    }
                    
                    DatePicker(
                        "Sale Date",
                        selection: $saleDate,
                        displayedComponents: [.date]
                    )
                }
                
                Section {
                    Text("Notes")
                    TextEditor(text: $notes)
                        .frame(minHeight: 50)
                }
                
                // TODO: Add support for fees
            }
            
            Spacer()
        }
        .onAppear {
            self.quantityToSell = item.quantity
            self.priceSoldAt = item.listedPrice
            self.notes = item.notes
        }
        .padding()
    }
}
