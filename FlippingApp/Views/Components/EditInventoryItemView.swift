//
//  EditInventoryItemView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 5/11/24.
//

import SwiftUI

struct EditInventoryItemView: View {
    @State private var title: String?
    @State private var imageData: Data?
    @State private var quantity: Int?
    @State private var purchasePrice: Double?
    @State private var purchaseDate: Date?
    @State private var listedPrice: Double?
    @State private var tag: Tag?
    @State private var notes: String?
    
    @Bindable var item: Item
    
    var body: some View {
        VStack {
            TextField("Title", text: $title.toUnwrapped(defaultValue: ""), prompt: Text("Title"))
        }
        .onAppear {
            self.title = item.title
            self.imageData = item.imageData
            self.quantity = item.quantity
            self.purchasePrice = item.purchasePrice
            self.purchaseDate = item.purchaseDate
            self.listedPrice = item.listedPrice
            self.tag = item.tag
            self.notes = item.notes
        }
    }
}
