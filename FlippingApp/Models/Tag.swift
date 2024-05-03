//
//  Tag.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import Foundation
import SwiftData

@Model
class Tag {
    var title: String = ""
    var id: String = UUID().uuidString
    var item: Item?

    init(title: String, id: String) {
        self.title = title
        self.id = id
    }
}
