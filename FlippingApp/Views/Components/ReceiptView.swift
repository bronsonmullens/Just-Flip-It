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

    @Bindable var item: Item

    @State private var editMode: Bool = false

    private func calculateProfit(for item: Item) -> Double {
        var profit: Double = 0.0

        if let soldPrice = item.soldPrice {
            if item.quantity > 1 {
                var count = item.quantity
                while count > 0 {
                    profit += soldPrice - (item.purchasePrice + (item.otherFees ?? 0.0) + (item.platformFees ?? 0.0))
                    count -= 1
                }
            } else {
                profit += soldPrice - (item.purchasePrice + (item.otherFees ?? 0.0) + (item.platformFees ?? 0.0))
            }
        }

        return profit
    }

    var body: some View {
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

                    if editMode == false {
                        Section {
                            LabeledContent("Profit") {
                                Text("\(calculateProfit(for: item).formatted(.currency(code: "USD")))")
                                    .bold()
                            }
                        }
                    }
                }
                .frame(height: UIScreen.main.bounds.height)
            }
        }
        .toolbar(.hidden)
    }
}
