//
//  AddInventoryItemView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 5/9/24.
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddInventoryItemView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Binding var isPresented: Bool
    
    @State private var title: String?
    @State private var quantity: Int?
    @State private var itemImage: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var purchasePrice: Double?
    @State private var purchaseDate: Date?
    @State private var listedPrice: Double?
    @State private var tag: Tag?
    @State private var notes: String?
    
    @State private var inputError: InputError?
    @State private var presentingTagPicker: Bool = false
    @State private var purchaseDatePickerShown: Bool = false
    
    private func validateInputData() -> Bool {
        guard let quantity = quantity,
              let purchasePrice = purchasePrice,
              let listedPrice = listedPrice else {
            return false
        }
        
        if quantity < 0 || quantity > 9_999 {
            inputError = InputError.invalidQuantity
            return false
        }
        
        if purchasePrice < 0 || purchasePrice > 99_999 {
            inputError = InputError.invalidPurchasePrice
            return false
        }
        
        if listedPrice < 0 || listedPrice > 99_999 {
            inputError = InputError.invalidListedPrice
            return false
        }
        
        return true
    }
    
    private func createNewItem() {
        if validateInputData() {
            guard let title = title,
                  let quantity = quantity,
                  let purchasePrice = purchasePrice,
                  let listedPrice = listedPrice else {
                log.error("Data missing from text field.")
                return
            }
            
            let newItem = Item(title: title,
                               imageData: imageData,
                               quantity: quantity,
                               purchaseDate: purchaseDate,
                               purchasePrice: purchasePrice,
                               listedPrice: listedPrice,
                               notes: notes)
            
            modelContext.insert(newItem)
            log.info("\(title) inventory item created.")
            
            self.isPresented.toggle()
        } else {
            log.error("Could not validate item data during item creation.")
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    self.isPresented = false
                } label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                }
                Spacer()
                
                Text("New Item")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    createNewItem()
                } label: {
                    Text("Add")
                }
                .disabled(validateInputData() == false)
            }
            .padding()
            
            
            ScrollView {
                Form {
                    Section {
                        TextField("Title", text: $title.toUnwrapped(defaultValue: ""))
                        
                        HStack {
                            Text("Quantity")
                            
                            TextField("", value: $quantity, format: .number, prompt: Text("1"))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Section {
                        if let imageData, let uiImage = UIImage(data: imageData) {
                            HStack(alignment: .center) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 120)
                                Spacer()
                                Button {
                                    self.imageData = nil
                                    self.itemImage = nil
                                } label: {
                                    Text("Remove Image")
                                }
                            }
                        } else {
                            HStack {
                                Text("Add a photo?")
                                Spacer()
                                PhotosPicker(selection: $itemImage,
                                             matching: .images,
                                             photoLibrary: .shared()) {
                                    Text("Select an image")
                                }
                                             .onChange(of: itemImage) { newImage in
                                                 Task {
                                                     if let data = try? await newImage?.loadTransferable(type: Data.self) {
                                                         self.imageData = data
                                                     }
                                                 }
                                             }
                            }
                        }
                    }
                    
                    Section {
                        HStack {
                            Text("Cost per item")
                            Spacer()
                            TextField("", value: $purchasePrice, format: .currency(code: "USD"), prompt: Text("$0.00"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                        
                        if purchaseDatePickerShown {
                            HStack {
                                DatePicker(
                                    "Purchase Date",
                                    selection: $purchaseDate.toUnwrapped(defaultValue: .now),
                                    displayedComponents: [.date]
                                )
                                
                                Button {
                                    self.purchaseDatePickerShown.toggle()
                                    self.purchaseDate = nil
                                } label: {
                                    Image(systemName: "x.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)
                                }
                                
                            }
                        } else {
                            Button {
                                self.purchaseDatePickerShown.toggle()
                                self.purchaseDate = .now
                            } label: {
                                Text("Tap to add a purchase date")
                            }
                        }
                    }
                    
                    Section {
                        HStack {
                            Text("Price per item")
                            Spacer()
                            TextField("", value: $listedPrice, format: .currency(code: "USD"), prompt: Text("$0.00"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                    }
                    
                    Section {
                        HStack {
                            Text("Add a tag?")
                            
                            Spacer()
                            
                            Button {
                                self.presentingTagPicker.toggle()
                            } label: {
                                if let tag = tag {
                                    Text(tag.title)
                                } else {
                                    Text("Tap here")
                                }
                            }
                        }
                        
                        TextEditor(text: $notes.toUnwrapped(defaultValue: ""))
                            .frame(minHeight: 50)
                    }
                }
                .frame(height: UIScreen.main.bounds.height)
                .ignoresSafeArea(edges: .bottom)
            }
            .popover(isPresented: $presentingTagPicker, content: {
                TagView(isPresented: $presentingTagPicker, tag: $tag)
            })
        }
    }
}

// MARK: - Errors

enum InputError: String {
    case invalidQuantity = "Quantity must be between at least 1."
    case invalidPurchasePrice = "Purchase price must be at least $0."
    case invalidListedPrice = "Listed price must be at least $0."
}
