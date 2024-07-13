//
//  EditInventoryItemView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 5/11/24.
//

import SwiftUI
import PhotosUI

struct EditInventoryItemView: View {
    
    @State private var tag: Tag?
    @State private var itemImage: PhotosPickerItem?
    @State private var purchaseDatePickerShown: Bool = false
    @State private var presentingTagPicker: Bool = false
    
    @Bindable var item: Item
    
    var body: some View {
        VStack {
            ScrollView {
                Form {
                    Section {
                        TextField("Title", text: $item.title, prompt: Text("Title"))
                        
                        HStack {
                            Text("Quantity")
                            
                            TextField("", value: $item.quantity, format: .number, prompt: Text("1"))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Section {
                        if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                            HStack(alignment: .center) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(12)
                                    .frame(width: 120)
                                
                                Spacer()
                                
                                Button {
                                    self.item.imageData = nil
                                } label: {
                                    Text("Remove Image")
                                }
                            }
                        } else {
                            HStack {
                                Text("Add a photo?")
                                Spacer()
                                PhotosPicker(selection: $itemImage, matching: .images, photoLibrary: .shared()) {
                                    Text("Select an image")
                                }
                                .onChange(of: itemImage) { newImage in
                                    Task {
                                        if let data = try? await newImage?.loadTransferable(type: Data.self) {
                                            self.item.imageData = data
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
                            TextField("", value: $item.purchasePrice, format: .currency(code: "USD"), prompt: Text("$0.00"))
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
                            }
                        }
                    }
                    
                    Section {
                        HStack {
                            Text("Price per item")
                            Spacer()
                            TextField("", value: $item.listedPrice, format: .currency(code: "USD"), prompt: Text("$0.00"))
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
                                if let tag = item.tag {
                                    Text(tag.title)
                                } else {
                                    Text("Tap here")
                                }
                            }
                        }
                        
                        TextEditor(text: $item.notes.toUnwrapped(defaultValue: ""))
                            .frame(minHeight: 50)
                    }
                    
                }
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
        }
    }
}
