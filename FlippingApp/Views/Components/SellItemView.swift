//
//  SellItemView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 10/2/23.
//

import SwiftUI
import SwiftData

struct SellItemView: View {
    @EnvironmentObject private var itemController: ItemController
    @Environment(\.modelContext) private var modelContext
    
    let item: Item
    
    @State private var quantityToSell: Int = 0
    @State private var priceSoldAt: Double = 0.0
    @State private var saleDate: Date?
    @State private var notes: String?
    @State private var sellError: SellError?
    
    private func validateInputData() -> Bool {
        if quantityToSell < 0 || quantityToSell > item.quantity {
            sellError = .invalidQuantity
            return false
        }
        
        if priceSoldAt < 0 || priceSoldAt > 99_999 {
            sellError = .invalidSalePrice
            return false
        }
        
        return true
    }
    
    private func processSale() {
        // TODO: Image
        let soldItem = Item(title: item.title,
                            imageData: nil,
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
            ScrollView {
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
                        
                        if saleDate != nil {
                            DatePicker(
                                "Sale Date",
                                selection: $saleDate.toUnwrapped(defaultValue: Date.now),
                                displayedComponents: [.date]
                            )
                        }
                        
                    }
                    
                    Section {
                        Text("Notes")
                        TextEditor(text: $notes.toUnwrapped(defaultValue: ""))
                            .frame(minHeight: 50)
                    }
                    
                    // TODO: Add support for fees
                }
                .frame(height: UIScreen.main.bounds.height)
                .ignoresSafeArea(edges: .bottom)
            }
            
            Spacer()
        }
        .onAppear {
            self.quantityToSell = item.quantity
            self.priceSoldAt = item.listedPrice
            self.notes = item.notes
        }
        .toolbar(content: {
            Button {
                processSale()
            } label: {
                Text("Sell")
            }
            .disabled(validateInputData() == false)
        })
        .navigationTitle(item.title)
    }
}

fileprivate enum SellError: String {
    case invalidQuantity = "Make sure your quantity is greater than 0 and not greater than your available stock."
    case invalidSalePrice = "Make sure your sale price is greater than 0 and less than 100,000."
}
