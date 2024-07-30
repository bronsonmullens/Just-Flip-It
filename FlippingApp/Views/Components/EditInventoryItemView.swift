//
//  EditInventoryItemView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 5/11/24.
//

import SwiftUI
import SwiftData
import PhotosUI
import RevenueCat
import Combine

struct EditInventoryItemView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var itemController: ItemController
    @Environment(\.presentationMode) private var presentationMode
    
    @Query private var items: [Item]
    
    @State private var tag: Tag?
    @State private var itemImage: PhotosPickerItem?
    @State private var purchaseDatePickerShown: Bool = false
    @State private var presentingTagPicker: Bool = false
    @State private var navigateToSellView = false
    @State private var showingTagInfoAlert: Bool = false
    @State private var currentOffering: Offering?
    @State private var showingSubscribeSheet: Bool = false
    @State private var showingEnlargedImage: Bool = false
    @State private var showingDeleteWarning: Bool = false
    
    @Bindable var item: Item
    
    var body: some View {
        VStack {
            ScrollView {
                Form {
                    Section {
                        TextField("Title", text: $item.title, prompt: Text("Title"))
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                        
                        HStack {
                            Text("Quantity")
                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                            
                            TextField("", value: $item.quantity, format: .number, prompt: Text("1"))
                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .onReceive(Just(item.quantity)) { _ in
                                    if item.quantity <= 0 && item.deleteWhenQuantityReachesZero {
                                        item.quantity = 1
                                    }
                                }
                        }
                        
                        Toggle(isOn: $item.deleteWhenQuantityReachesZero, label: {
                            Text("Delete when quantity is 0?")
                        })
                        .tint(.green)
                    }
                    .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                    
                    Section {
                        if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                            HStack(alignment: .center) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(10)
                                    .frame(width: 120)
                                    .onTapGesture {
                                        self.showingEnlargedImage.toggle()
                                    }
                                
                                Spacer()
                                
                                Text("Remove Image")
                                    .onTapGesture {
                                        self.item.imageData = nil
                                        self.itemImage = nil
                                    }
                            }
                        } else {
                            if itemController.hasPremium {
                                HStack {
                                    Text("Add a photo?")
                                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                                    Spacer()
                                    PhotosPicker(selection: $itemImage, matching: .images, photoLibrary: .shared()) {
                                        Text("Select an image")
                                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                                    }
                                    .onChange(of: itemImage) { newImage in
                                        Task {
                                            if let data = try? await newImage?.loadTransferable(type: Data.self) {
                                                self.item.imageData = data
                                            }
                                        }
                                    }
                                }
                            } else {
                                Text("Subscribe to edit item's photo")
                                    .foregroundStyle(Color.accentColor)
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
                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                            Spacer()
                            TextField("", value: $item.purchasePrice, format: .currency(code: Locale.current.currency?.identifier ?? "USD"), prompt: Text("$0.00"))
                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                        
                        if purchaseDatePickerShown {
                            HStack {
                                DatePicker(
                                    "Purchase Date",
                                    selection: $item.purchaseDate.toUnwrapped(defaultValue: .now),
                                    displayedComponents: [.date]
                                )

                                
                                Button {
                                    self.purchaseDatePickerShown.toggle()
                                    self.item.purchaseDate = nil
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
                                self.item.purchaseDate = .now
                            } label: {
                                Text("Tap to add a purchase date")
                                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                            }
                        }
                    }
                    .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                    
                    Section {
                        HStack {
                            Text("Price per item")
                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                            Spacer()
                            TextField("", value: $item.listedPrice, format: .currency(code: Locale.current.currency?.identifier ?? "USD"), prompt: Text("$0.00"))
                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
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
                            
                            Button {
                                self.presentingTagPicker.toggle()
                            } label: {
                                if let tag = item.tag {
                                    Text(tag.title)
                                } else {
                                    Text("Tap here")
                                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                                }
                            }
                        }
                        
                        TextEditor(text: $item.notes.toUnwrapped(defaultValue: ""))
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                            .frame(minHeight: 50)
                    }
                    .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                    
                }
                .scrollContentBackground(.hidden)
                .frame(height: UIScreen.main.bounds.height)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .popover(isPresented: $presentingTagPicker, content: {
            TagView(isPresented: $presentingTagPicker, tag: $item.tag)
        })
        .popover(isPresented: $showingEnlargedImage, content: {
            ImageView(isPresented: $showingEnlargedImage, imageData: $item.imageData)
        })
        .sheet(isPresented: $showingSubscribeSheet, content: {
            SubscribePage(currentOffering: $currentOffering, isPresented: $showingSubscribeSheet)
                .presentationDetents([.height(600)])
                .presentationDragIndicator(.hidden)
        })
        .onAppear {
            guard items.contains(item) else {
                // TODO: Could this be done a better way? The @Binding doesn't seem to be working here.
                log.info("Item could not be found to edit. Was it deleted or sold?")
                presentationMode.wrappedValue.dismiss()
                return
            }
            
            if item.purchaseDate != nil {
                self.purchaseDatePickerShown = true
            }
            
            if let tag = item.tag {
                self.tag = tag
            }
            
            if item.quantity <= 0 && item.deleteWhenQuantityReachesZero {
                log.info("Quantity exhausted. Dismissing edit page.")
                presentationMode.wrappedValue.dismiss()
            }
            
            Purchases.shared.getOfferings { offerings, error in
                if let offering = offerings?.current, error == nil {
                    self.currentOffering = offering
                } else {
                    log.error("Error: \(String(describing: error))")
                }
            }
        }
        .navigationTitle(Text("Edit Item"))
        .background(Color("\(itemController.selectedTheme.rawValue)Background"))
        .navigationDestination(isPresented: $navigateToSellView) {
            SellItemView(item: item)
        }
        .toolbar(content: {
            Menu("Options") {
                Button {
                    log.info("Navigating to SellItemView from edit page.")
                    navigateToSellView = true
                } label: {
                    Text("Sell")
                }
                
                Button {
                    let newItem = Item(title: item.title,
                                       imageData: item.imageData,
                                       quantity: item.quantity,
                                       deleteWhenQuantityReachesZero: item.deleteWhenQuantityReachesZero,
                                       purchaseDate: item.purchaseDate,
                                       purchasePrice: item.purchasePrice,
                                       listedPrice: item.listedPrice,
                                       tag: item.tag,
                                       notes: item.notes)
                    log.info("Added duplicated item to inventory.")
                    modelContext.insert(newItem)
                    log.info("Returning to inventory.")
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Duplicate")
                }
                
                Button {
                    self.showingDeleteWarning = true
                } label: {
                    Text("Delete")
                }
            }
        })
        .alert("Tags", isPresented: $showingTagInfoAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Tags are like categories for your items. Create as many as you'd like to organize your items however you like.")
        }
        .alert("Delete Item?", isPresented: $showingDeleteWarning) {
            Button("Yes", role: .destructive) {
                log.info("Deleting item from inventory.")
                modelContext.delete(item)
                log.info("Returning to inventory")
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this item? This is an action that cannot be undone and you will lose this item forever. This will impact stats tracked in the Stats tab.")
        }
    }
}
