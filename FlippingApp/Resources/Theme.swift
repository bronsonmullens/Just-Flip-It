//
//  Theme.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import Foundation

enum Theme {
    enum HomeView {
        enum Button {
            static let ButtonWidth: CGFloat = 32
        }
    }
    
    enum CardsView {
        enum Card {
            static let ProfitCardHeight: CGFloat = 100
            static let ValueCardHeight: CGFloat = 180
            static let SalesCardHeight: CGFloat = 180
            static let OtherInfoCardHeight: CGFloat = 140

            static let CardCornerRadius: CGFloat = 12
        }
    }
}
