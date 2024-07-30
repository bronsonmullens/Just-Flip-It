//
//  ReceiptView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI
import SwiftData

struct ReceiptView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject private var itemController: ItemController

    @Bindable var item: Item

    @State private var editMode: Bool = false
    @State private var showingDeleteWarning: Bool = false
    @State private var showingRestoreWarning: Bool = false

    var body: some View {
        ZStack {
            Color("\(itemController.selectedTheme)Background")
                .ignoresSafeArea(.all)
            
            VStack {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Back")
                    }

                    Spacer()

                    if editMode {
                        TextField("", text: $item.title, prompt: Text(item.title))
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        Text("\(item.title)")
                            .font(.headline)
                    }

                    Spacer()

                    Menu("Options") {
                        Button("\(editMode ? "Done" : "Edit")") {
                            editMode.toggle()
                        }
                        
                        Button("Restore") {
                            showingRestoreWarning.toggle()
                        }
                        
                        Button("Delete") {
                            showingDeleteWarning.toggle()
                        }
                    }
                }
                .padding()

                ScrollView {
                    Form {
                        Section {
                            if editMode {
                                HStack {
                                    Text("Quantity Sold")

                                    TextField("", value: $item.quantity, format: .number)
                                        .multilineTextAlignment(.trailing)
                                        .keyboardType(.numberPad)
                                        .onChange(of: item.quantity) { newValue in
                                            if newValue > 9_999 {
                                                item.quantity = 9_999
                                            }
                                        }
                                }
                            } else {
                                LabeledContent("Quantity Sold") {
                                    Text("\(item.quantity)")
                                }
                            }
                        }
                        .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))

                        Section {
                            if editMode {
                                HStack {
                                    Text("Purchase Price")

                                    TextField("", value: $item.purchasePrice, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                        .multilineTextAlignment(.trailing)
                                        .keyboardType(.decimalPad)
                                        .onChange(of: item.purchasePrice) { newValue in
                                            if newValue > 99_999.99 {
                                                item.purchasePrice = 99_999.99
                                            }
                                        }
                                }

                                HStack {
                                    Text("Listed Price")

                                    TextField("", value: $item.listedPrice, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                        .multilineTextAlignment(.trailing)
                                        .keyboardType(.decimalPad)
                                        .onChange(of: item.listedPrice) { newValue in
                                            if newValue > 99_999.99 {
                                                item.listedPrice = 99_999.99
                                            }
                                        }
                                }

                                HStack {
                                    Text("Final Price Per Item")

                                    TextField("", value: $item.soldPrice, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                        .multilineTextAlignment(.trailing)
                                        .keyboardType(.numberPad)
                                        .onChange(of: item.soldPrice ?? 0.0) { newValue in
                                            if newValue > 99_999.99 {
                                                item.soldPrice = 99_999.99
                                            }
                                        }
                                }
                            } else {
                                LabeledContent("Purchase Price") {
                                    Text("\(item.purchasePrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                                }

                                LabeledContent("Listed Price") {
                                    Text("\(item.listedPrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                                }

                                if let soldPrice = item.soldPrice {
                                    LabeledContent("Final Price Per Item") {
                                        Text("\(soldPrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                                    }
                                }
                            }
                        }
                        .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))

                        Section {
                            if editMode {
                                DatePicker(
                                    "Purchase Date",
                                    selection: $item.purchaseDate.toUnwrapped(defaultValue: Date()),
                                    displayedComponents: [.date]
                                )

                                DatePicker(
                                    "Sold Date",
                                    selection: $item.soldDate.toUnwrapped(defaultValue: Date()),
                                    displayedComponents: [.date]
                                )
                            } else {
                                if let purchaseDate = item.purchaseDate {
                                    LabeledContent("Purchase Date") {
                                        Text("\(purchaseDate.formatted())")
                                    }
                                }

                                if let soldDate = item.soldDate {
                                    LabeledContent("Sold Date") {
                                        Text("\(soldDate.formatted())")
                                    }
                                }
                            }
                        }
                        .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))

                        Section {
                            if editMode {
                                HStack {
                                    Text("Platform Fees")

                                    TextField("%", value: $item.platformFees, format: .percent)
                                        .multilineTextAlignment(.trailing)
                                        .keyboardType(.decimalPad)
                                        .onChange(of: item.platformFees ?? 0.0) { newValue in
                                            if newValue > 99.99 {
                                                item.platformFees = 99.99
                                            }
                                        }
                                }

                                HStack {
                                    Text("Other Fees")

                                    TextField("", value: $item.otherFees, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                        .multilineTextAlignment(.trailing)
                                        .keyboardType(.decimalPad)
                                        .onChange(of: item.otherFees ?? 0.0) { newValue in
                                            if newValue > 99_999.99 {
                                                item.otherFees = 99_999.99
                                            }
                                        }
                                }
                            } else {
                                if let platformFees = item.platformFees, let soldPrice = item.soldPrice {
                                    let fee = soldPrice * platformFees
                                    LabeledContent("Platform Fees") {
                                        Text("\(fee.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                                    }
                                }

                                if let otherFees = item.otherFees {
                                    LabeledContent("Other Fees") {
                                        Text("\(otherFees.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                                    }
                                }
                            }
                        }
                        .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))

                        if editMode == false {
                            Section {
                                LabeledContent("Profit") {
                                    Text("\(itemController.calculateProfitForItem(item, quantity: item.quantity).formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                                        .bold()
                                }
                            }
                            .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                        }
                    }
                    .frame(height: UIScreen.main.bounds.height)
                    .scrollContentBackground(.hidden)
                }
            }
            .toolbar(.hidden)
        }
        .alert("Restore Item?", isPresented: $showingRestoreWarning) {
            Button("Yes", role: .destructive) {
                let newItem = Item(title: item.title,
                                   imageData: item.imageData,
                                   quantity: item.quantity,
                                   deleteWhenQuantityReachesZero: item.deleteWhenQuantityReachesZero,
                                   purchaseDate: item.purchaseDate,
                                   purchasePrice: item.purchasePrice,
                                   listedPrice: item.listedPrice,
                                   tag: item.tag,
                                   notes: item.notes)
                modelContext.delete(self.item)
                log.info("Deleted item from receipts.")
                modelContext.insert(newItem)
                log.info("Added item to inventory")
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("This will recreate this inventory item and delete this receipt. This is an action that cannot be undone and you will lose this sold item forever. This will impact stats tracked in the Stats tab. Are you sure?")
        }
        .alert("Delete Item?", isPresented: $showingDeleteWarning) {
            Button("Yes", role: .destructive) {
                modelContext.delete(self.item)
                log.info("Deleted item from receipts.")
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this sold item? This is an action that cannot be undone and you will lose this item forever. This will impact stats tracked in the Stats tab.")
        }
    }
}
