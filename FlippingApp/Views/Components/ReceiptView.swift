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

                    Button {
                        editMode.toggle()
                    } label: {
                        Text(editMode ? "Done" : "Edit")
                            .foregroundStyle(Color.accentColor)
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

                                    TextField("", value: $item.purchasePrice, format: .currency(code: "USD"))
                                        .multilineTextAlignment(.trailing)
                                        .keyboardType(.decimalPad)
                                }

                                HStack {
                                    Text("Listed Price")

                                    TextField("", value: $item.listedPrice, format: .currency(code: "USD"))
                                        .multilineTextAlignment(.trailing)
                                        .keyboardType(.decimalPad)
                                }

                                HStack {
                                    Text("Sold Price")

                                    TextField("", value: $item.soldPrice, format: .currency(code: "USD"))
                                        .multilineTextAlignment(.trailing)
                                        .keyboardType(.numberPad)
                                }
                            } else {
                                LabeledContent("Purchase Price") {
                                    Text("\(item.purchasePrice.formatted(.currency(code: "USD")))")
                                }

                                LabeledContent("Listed Price") {
                                    Text("\(item.listedPrice.formatted(.currency(code: "USD")))")
                                }

                                if let soldPrice = item.soldPrice {
                                    LabeledContent("Sold Price") {
                                        Text("\(soldPrice.formatted(.currency(code: "USD")))")
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

                                    TextField("", value: $item.platformFees, format: .currency(code: "USD"))
                                        .multilineTextAlignment(.trailing)
                                        .keyboardType(.decimalPad)
                                }

                                HStack {
                                    Text("Other Fees")

                                    TextField("", value: $item.otherFees, format: .currency(code: "USD"))
                                        .multilineTextAlignment(.trailing)
                                        .keyboardType(.decimalPad)
                                }
                            } else {
                                if let platformFees = item.platformFees {
                                    LabeledContent("Platform Fees") {
                                        Text("\(platformFees.formatted(.currency(code: "USD")))")
                                    }
                                }

                                if let otherFees = item.otherFees {
                                    LabeledContent("Other Fees") {
                                        Text("\(otherFees.formatted(.currency(code: "USD")))")
                                    }
                                }
                            }
                        }
                        .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))

                        if editMode == false {
                            Section {
                                LabeledContent("Profit") {
                                    Text("\(itemController.calculateProfitForItem(item, quantity: item.quantity).formatted(.currency(code: "USD")))")
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
    }
}
