//
//  Item.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import Foundation
import SwiftData

@Model
class Item: Identifiable {
    // Inventory Properties
    var title: String = ""
    var id: String = UUID().uuidString
    var dateAdded: Date? = Date()
    var imageData: Data?
    var quantity: Int = 1
    var automaticallyDeleteWhenStockDepleted: Bool = false
    var purchaseDate: Date?
    var purchasePrice: Double = 0.00
    var listedPrice: Double = 0.00
    @Relationship(inverse: \Tag.item) var tag: Tag?
    var notes: String?

    // Sold Item Properties
    var soldDate: Date?
    var platformFees: Double?
    var otherFees: Double?
    var soldPrice: Double?

    init(title: String, id: String = UUID().uuidString, imageData: Data?, quantity: Int, purchaseDate: Date?, purchasePrice: Double, listedPrice: Double, tag: Tag? = nil, notes: String?, soldDate: Date? = nil, platformFees: Double? = nil, otherFees: Double? = nil, soldPrice: Double? = nil) {
        self.title = title
        self.id = id
        self.imageData = imageData
        self.quantity = quantity
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.listedPrice = listedPrice
        self.tag = tag
        self.notes = notes
        self.soldDate = soldDate
        self.platformFees = platformFees
        self.otherFees = otherFees
        self.soldPrice = soldPrice
    }
}
