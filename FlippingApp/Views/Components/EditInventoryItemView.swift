//
//  EditInventoryItemView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 5/11/24.
//

import SwiftUI
import PhotosUI

struct EditInventoryItemView: View {
    @EnvironmentObject private var itemController: ItemController
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var tag: Tag?
    @State private var itemImage: PhotosPickerItem?
    @State private var purchaseDatePickerShown: Bool = false
    @State private var presentingTagPicker: Bool = false
    @State private var navigateToSellView = false
    
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
                        }
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
                                
                                Spacer()
                                
                                Button {
                                    self.item.imageData = nil
                                } label: {
                                    Text("Remove Image")
                                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
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
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                    
                    Section {
                        HStack {
                            Text("Cost per item")
                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                            Spacer()
                            TextField("", value: $item.purchasePrice, format: .currency(code: "USD"), prompt: Text("$0.00"))
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
                            TextField("", value: $item.listedPrice, format: .currency(code: "USD"), prompt: Text("$0.00"))
                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                    }
                    .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                    
                    Section {
                        HStack {
                            Text("Add a tag?")
                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                            
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
        .onAppear {
            if item.purchaseDate != nil {
                self.purchaseDatePickerShown = true
            }
            
            if let tag = item.tag {
                self.tag = tag
            }
            
            if item.quantity == 0 {
                log.info("Quantity exhausted. Dismissing edit page.")
                presentationMode.wrappedValue.dismiss()
            }
        }
        .navigationTitle(Text("Edit Item"))
        .background(Color("\(itemController.selectedTheme.rawValue)Background"))
        .navigationDestination(isPresented: $navigateToSellView) {
            SellItemView(item: item)
        }
        .toolbar(content: {
            Button {
                log.info("Navigating to SellItemView from edit page.")
                navigateToSellView = true
            } label: {
                Text("Sell")
            }
        })
    }
}
