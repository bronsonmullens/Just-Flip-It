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
    
    @EnvironmentObject private var itemController: ItemController
    
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
    @State private var showingTagInfoAlert: Bool = false
    
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
                    .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                    
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
                            if itemController.hasPremium {
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
                            } else {
                                Text("Subscribe to attach a photo")
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                    
                    Section {
                        HStack {
                            Text("Your cost per item")
                            Spacer()
                            TextField("", value: $purchasePrice, format: .currency(code: Locale.current.currency?.identifier ?? "USD"), prompt: Text("$0.00"))
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
                    .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                    
                    Section {
                        HStack {
                            Text("Price per item")
                            Spacer()
                            TextField("", value: $listedPrice, format: .currency(code: Locale.current.currency?.identifier ?? "USD"), prompt: Text("$0.00"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
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
                                    .onTapGesture {
                                        self.showingTagInfoAlert.toggle()
                                    }
                                
                                Text("Add a tag?")
                            }
                            
                            Spacer()
                            
                            Text("\(tag?.title ?? "Tap here")")
                                .onTapGesture {
                                    self.presentingTagPicker.toggle()
                                }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Notes?")
                            
                            TextEditor(text: $notes.toUnwrapped(defaultValue: ""))
                                .frame(minHeight: 50)
                        }
                    }
                    .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                }
                .scrollContentBackground(.hidden)
                .frame(height: UIScreen.main.bounds.height)
                .ignoresSafeArea(edges: .bottom)
            }
            .alert("Tags", isPresented: $showingTagInfoAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Tags are like categories for your items. Create as many as you'd like to organize your items however you like.")
            }
            .popover(isPresented: $presentingTagPicker, content: {
                TagView(isPresented: $presentingTagPicker, tag: $tag)
            })
        }
        .background(Color("\(itemController.selectedTheme.rawValue)Background"))
    }
}
