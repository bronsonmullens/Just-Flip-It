//
//  AddInventoryItemView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI
import SwiftData

fileprivate enum InputError: String {
    case excessiveQuantity = "Quantity must be between 1 and 9,999."
    case excessivePurchasePrice = "Purchase price must be between $0 and $99,999"
    case excessiveListedPrice = "Listed price must be between $0 and $99,999"
}

struct AddInventoryItemView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var items: [Item]

    @Binding var isPresented: Bool

    @State private var title: String = ""
    @State private var quantity: Int = 1
    @State private var purchasePrice: Double?
    @State private var purchaseDate: Date = Date()
    @State private var listedPrice: Double?
    @State private var tag: Tag?
    @State private var notes: String = ""
    @State private var inputError: InputError?
    @State private var presentingInputErrorAlert: Bool = false
    @State private var presentingTagView: Bool = false

    private var addButtonDisabled: Bool {
        if title.isEmpty == false &&
            quantity >= 1 &&
            purchasePrice ?? -1 >= 0.0 &&
            listedPrice ?? -1 >= 0.0 {
            return false
        }

        return true
    }

    private func validateInputData() -> Bool {
        if quantity > 9_999 {
            inputError = InputError.excessiveQuantity
            return false
        }

        if let purchasePrice = purchasePrice, purchasePrice > 99_999 {
            inputError = InputError.excessivePurchasePrice
            return false
        }

        if let listedPrice = listedPrice, listedPrice > 99_999 {
            inputError = InputError.excessiveListedPrice
        }

        return true
    }

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Button {
                        isPresented = false
                    } label: {
                        Text("Cancel")
                            .foregroundStyle(.red)
                    }

                    Spacer()

                    Text("New Item")
                        .font(.headline)

                    Spacer()

                    Button {
                        if validateInputData() {
                            let newItem = Item(title: title,
                                               id: UUID().uuidString,
                                               quantity: quantity,
                                               purchaseDate: purchaseDate,
                                               purchasePrice: purchasePrice ?? 0,
                                               listedPrice: listedPrice ?? 0,
                                               tag: tag,
                                               notes: notes)
                            modelContext.insert(newItem)
                            // Save?
                            isPresented = false
                        } else {
                            self.presentingInputErrorAlert = true
                        }

                    } label: {
                        Text("Add")
                            .foregroundStyle(Color.accentColor)
                    }
                    .disabled(addButtonDisabled)
                }
                .padding()

                Form {
                    Section {
                        TextField("Title", text: $title)

                        HStack {
                            Text("Quantity")

                            TextField("", value: $quantity, format: .number)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                        }
                    }

                    Section {
                        HStack {
                            Text("Purchase Price")

                            TextField("", value: $purchasePrice, format: .currency(code: "USD"), prompt: Text("$0.00"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }

                        DatePicker(
                            "Purchase Date",
                            selection: $purchaseDate,
                            displayedComponents: [.date]
                        )
                    }

                    Section {
                        HStack {
                            Text("Listed Price")

                            TextField("", value: $listedPrice, format: .currency(code: "USD"), prompt: Text("$0.00"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                    }

                    Section {
                        HStack {
                            Text("Add Tag")

                            Spacer()

                            Button {
                                presentingTagView.toggle()
                            } label: {
                                if let tag = tag {
                                    Text(tag.title)
                                } else {
                                    Text("None")
                                }
                            }

                        }

                        // TODO: Fix alignment
                        VStack(alignment: .leading) {
                            Text("Notes")

                            TextEditor(text: $notes)
                                .frame(minHeight: 50)
                        }
                    }
                }
                .frame(height: UIScreen.main.bounds.height)
                .ignoresSafeArea(edges: .bottom)

                Spacer()
            }
            .alert("Input Error", isPresented: $presentingInputErrorAlert, actions: {
                //
            }, message: {
                if let inputError = inputError {
                    Text("\(inputError.rawValue)")
                } else {
                    Text("An unknown error occured.")
                }
            })
        }
        .popover(isPresented: $presentingTagView) {
            TagView(isPresented: $presentingTagView, tag: $tag)
        }
    }
}

