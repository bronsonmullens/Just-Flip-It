//
//  EditInventoryItemView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI
import SwiftData

struct EditInventoryItemView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @Bindable var item: Item
    
    @State private var presentingTagView: Bool = false
    @State private var sellingItem: Bool = false
    
    var body: some View {
        if sellingItem {
            //SellItemView(item: self.item)
        } else {
            VStack {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Back")
                    }
                    
                    Spacer()
                    
                    TextField("", text: $item.title, prompt: Text(item.title))
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.roundedBorder)
                    
                    
                    Spacer()
                    
                    Button {
                        self.sellingItem = true
                    } label: {
                        Text("Sell")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .padding()
                
                ScrollView {
                    Form {
                        Section {
                            HStack {
                                Text("Quantity")
                                
                                TextField("", value: $item.quantity, format: .number)
                                    .multilineTextAlignment(.trailing)
                                    .keyboardType(.numberPad)
                            }
                        }
                        
                        Section {
                            HStack {
                                Text("Purchase Price")
                                
                                TextField("", value: $item.purchasePrice, format: .currency(code: "USD"), prompt: Text("$0.00"))
                                    .multilineTextAlignment(.trailing)
                                    .keyboardType(.decimalPad)
                            }
                            
                            DatePicker(
                                "Purchase Date",
                                selection: $item.purchaseDate.toUnwrapped(defaultValue: Date()),
                                displayedComponents: [.date]
                            )
                        }
                        
                        Section {
                            HStack {
                                Text("Listed Price")
                                
                                TextField("", value: $item.listedPrice, format: .currency(code: "USD"), prompt: Text("$0.00"))
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
                                    if let tag = item.tag {
                                        Text(tag.title)
                                    } else {
                                        Text("None")
                                    }
                                }
                                
                            }
                            
                            // TODO: Fix alignment
                            VStack(alignment: .leading) {
                                Text("Notes")
                                
                                TextEditor(text: $item.notes)
                                    .frame(minHeight: 50)
                            }
                        }
                    }
                    .frame(height: UIScreen.main.bounds.height)
                    .ignoresSafeArea(edges: .bottom)
                    
                    Spacer()
                }
            }
            .toolbar(.hidden)
            .popover(isPresented: $presentingTagView) {
                TagView(isPresented: $presentingTagView, tag: $item.tag)
            }
        }
    }
}
