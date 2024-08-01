//
//  AddInventoryItemView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 5/9/24.
//

import SwiftUI
import SwiftData
import PhotosUI
import RevenueCat

struct AddInventoryItemView: View {
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject private var itemController: ItemController
    
    @Binding var isPresented: Bool
    
    @State private var title: String?
    @State private var quantity: Int?
    @State private var deleteWhenQuantityReachesZero: Bool = true
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
    @State private var currentOffering: Offering?
    @State private var showingSubscribeSheet: Bool = false
    @State private var showingEnlargedImage: Bool = false
    
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
        
        if purchasePrice < 0 || purchasePrice > 99_999.99 {
            inputError = InputError.invalidPurchasePrice
            return false
        }
        
        if listedPrice < 0 || listedPrice > 99_999.99 {
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
                               deleteWhenQuantityReachesZero: deleteWhenQuantityReachesZero,
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
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                
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
                                .onChange(of: quantity ?? 0) { newValue in
                                    if newValue > 9_999 {
                                        quantity = 9_999
                                    }
                                }
                        }
                        
                        Toggle(isOn: $deleteWhenQuantityReachesZero, label: {
                            Text("Delete when quantity is 0?")
                        })
                        .tint(.green)
                    }
                    .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                    
                    Section {
                        if let imageData, let uiImage = UIImage(data: imageData) {
                            HStack(alignment: .center) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 120)
                                    .onTapGesture {
                                        self.showingEnlargedImage.toggle()
                                    }
                                Spacer()
                                Text("Remove Image")
                                    .onTapGesture {
                                        self.imageData = nil
                                        self.itemImage = nil
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
                                Text("Attach a photo")
                                    .onTapGesture {
                                        self.showingSubscribeSheet.toggle()
                                    }
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
                                .onChange(of: purchasePrice ?? 0.0) { newValue in
                                    if newValue ?? 0.0 > 99_999.99 {
                                        purchasePrice = 99_999.99
                                    }
                                }
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
                                .onChange(of: listedPrice ?? 0.0) { newValue in
                                    if newValue ?? 0.0 > 99_999.99 {
                                        listedPrice = 99_999.99
                                    }
                                }
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
                        .popover(isPresented: $presentingTagPicker, content: {
                            TagView(isPresented: $presentingTagPicker, tag: $tag)
                        })
                        
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
        }
        .popover(isPresented: $showingEnlargedImage, content: {
            ImageView(isPresented: $showingEnlargedImage, imageData: $imageData)
        })
        .sheet(isPresented: $showingSubscribeSheet, content: {
            SubscribePage(currentOffering: $currentOffering, isPresented: $showingSubscribeSheet)
                .presentationDetents([.height(600)])
                .presentationDragIndicator(.hidden)
        })
        .onAppear {
            Purchases.shared.getOfferings { offerings, error in
                if let offering = offerings?.current, error == nil {
                    self.currentOffering = offering
                } else {
                    log.error("Error: \(String(describing: error))")
                }
            }
        }
        .background(Color("\(itemController.selectedTheme.rawValue)Background"))
    }
}
