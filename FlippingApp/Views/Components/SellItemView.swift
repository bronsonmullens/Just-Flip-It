//
//  SellItemView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 10/2/23.
//

import SwiftUI
import SwiftData
import Confetti

struct SellItemView: View {
    @EnvironmentObject private var itemController: ItemController
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) private var presentationMode
    
    let item: Item
    
    @State private var quantityToSell: Int = 0
    @State private var priceSoldAt: Double = 0.0
    @State private var saleDate: Date?
    @State private var platformFees: Double = 0.0
    @State private var otherFees: Double = 0.0
    @State private var notes: String?
    @State private var sellError: SellError?
    @State private var showingPlatformFeesInfo: Bool = false
    @State private var showingOtherFeesInfo: Bool = false
    
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
    
    private var estimatedProfit: Double {
        let platformFees = priceSoldAt * platformFees
        return ((priceSoldAt * Double(item.quantity)) - platformFees - otherFees)
    }
    
    private func processSale() {
        let soldItem = Item(title: item.title,
                            imageData: item.imageData,
                            quantity: quantityToSell,
                            deleteWhenQuantityReachesZero: item.deleteWhenQuantityReachesZero,
                            purchaseDate: item.purchaseDate,
                            purchasePrice: item.purchasePrice,
                            listedPrice: item.listedPrice,
                            tag: item.tag,
                            notes: notes,
                            soldDate: saleDate,
                            platformFees: platformFees,
                            otherFees: otherFees,
                            soldPrice: priceSoldAt)
        if saleDate == nil { soldItem.soldDate = .now }
        modelContext.insert(soldItem)
        self.item.quantity -= quantityToSell
        if item.quantity <= 0 && item.deleteWhenQuantityReachesZero {
            modelContext.delete(item)
            log.info("Deleted item with depleted stock: \(item.title)")
        }
        log.info("Created new soldItem: \(soldItem.title) (\(soldItem.id)")
        presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        ZStack {
            Color("\(itemController.selectedTheme.rawValue)Background")
                .ignoresSafeArea(.all)
            
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
                        .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                        
                        Section {
                            HStack {
                                Text("Purchase Price:")
                                Text("\(item.purchasePrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                            }
                            .foregroundStyle(.gray)
                            
                            HStack {
                                Text("Finale Sale Price:")
                                TextField("$0.00", value: $priceSoldAt, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                    .multilineTextAlignment(.trailing)
                                    .keyboardType(.decimalPad)
                            }
                            
                            HStack {
                                Text("Net Profit:")
                                Spacer()
                                Text("\(estimatedProfit.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                            }
                        }
                        .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                        
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
                        .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                        
                        Section {
                            HStack {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20)
                                    
                                    Text("Platform Fees:")
                                }
                                .onTapGesture {
                                    self.showingPlatformFeesInfo.toggle()
                                }
                                
                                TextField("%", value: $platformFees, format: .percent)
                                    .multilineTextAlignment(.trailing)
                                    .keyboardType(.decimalPad)
                            }
                            
                            if platformFees != 0.0 {
                                Text((priceSoldAt * platformFees), format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                    .foregroundStyle(.gray)
                            }
                            
                            HStack {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20)
                                    
                                    Text("Other Fees:")
                                }
                                .onTapGesture {
                                    self.showingOtherFeesInfo.toggle()
                                }
                                
                                TextField("$0.00", value: $otherFees, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                    .multilineTextAlignment(.trailing)
                                    .keyboardType(.decimalPad)
                            }
                        }
                        .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                        
                        Section {
                            Text("Notes")
                            TextEditor(text: $notes.toUnwrapped(defaultValue: ""))
                                .frame(minHeight: 50)
                        }
                        .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                    }
                    .frame(height: UIScreen.main.bounds.height)
                    .ignoresSafeArea(edges: .bottom)
                    .scrollContentBackground(.hidden)
                }
                
                Spacer()
            }
            .onAppear {
                
                self.quantityToSell = item.quantity
                self.priceSoldAt = item.listedPrice
                self.notes = item.notes
            }
            .alert("Platform Fees", isPresented: $showingPlatformFeesInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Platform fees are usually a % taken away from your sale by a service such as eBay or Mercari.")
            }
            .alert("Other Fees", isPresented: $showingOtherFeesInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Other fees can be shipping costs or any other cost taken from your profit.")
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
            
            ConfettiView(emissionDuration: 4.0)
        }
    }
}

fileprivate enum SellError: String {
    case invalidQuantity = "Make sure your quantity is greater than 0 and not greater than your available stock."
    case invalidSalePrice = "Make sure your sale price is greater than 0 and less than 100,000."
}
