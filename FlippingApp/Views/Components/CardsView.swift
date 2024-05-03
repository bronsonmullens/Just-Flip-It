//
//  CardsView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI
import SwiftData

enum CardType: CaseIterable {
    case profit
    case value
    case sales
    case otherInfo
}

struct CardsView: View {
    var body: some View {
        ScrollView {
            ForEach(CardType.allCases, id: \.self) { cardType in
                CardView(cardType: cardType)
            }
        }
    }
}

struct CardView: View {
    var cardType: CardType

    private var height: CGFloat {
        switch cardType {
        case .profit:
            return Theme.CardsView.Card.ProfitCardHeight
        case .value:
            return Theme.CardsView.Card.ValueCardHeight
        case .sales:
            return Theme.CardsView.Card.SalesCardHeight
        case .otherInfo:
            return Theme.CardsView.Card.OtherInfoCardHeight
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.CardsView.Card.CardCornerRadius)
                .frame(height: height)
                .foregroundStyle(Color.accentColor)
                .shadow(color: .black, radius: 4, x: -2, y: 2)
                .overlay(
                    ZStack {
                        switch cardType {
                        case .profit:
                            ProfitCardContent()
                        case .value:
                            TotalValueCardContent()
                        case .sales:
                            SoldItemsCardContent()
                        case .otherInfo:
                            OtherInfoCardContent()
                        }
                    }
                )
        }
        .padding()
    }
}

struct ProfitCardContent: View {
    @EnvironmentObject private var itemController: ItemController
    @Query private var items: [Item]

    private var profit: Double {
        return itemController.calculateProfit(using: items)
    }

    private var profitValueTextColor: Color {
        if profit > 0.0 {
            return .green
        } else if profit == 0.0 {
            return .white
        } else {
            return .red
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Profit")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(profit.formatted(.currency(code: "USD")))")
                    .font(.largeTitle)
                    .foregroundStyle(profitValueTextColor)
            }
            Spacer()
        }
        .padding()
    }
}

struct TotalValueCardContent: View {
    @EnvironmentObject private var itemController: ItemController
    @Query private var items: [Item]

    var totalValue: Double {
        return itemController.calculateTotalInventoryValue(for: items)
    }

    var totalInvestment: Double {
        return itemController.calculateTotalInvestment(for: items)
    }

    var inventoryCount: Int {
        return itemController.calculateTotalInventoryItems(for: items)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Total Value")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(totalValue.formatted(.currency(code: "USD")))")
                    .font(.title)
                    .foregroundStyle(.white)

                Spacer()

                Text("Total Investment")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(totalInvestment.formatted(.currency(code: "USD")))")
                    .font(.title)
                    .foregroundStyle(.white)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Spacer()
                Text("Item Count")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(inventoryCount)")
                    .font(.title)
                    .foregroundStyle(.white)
            }
        }
        .padding()
    }
}

struct SoldItemsCardContent: View {
    @EnvironmentObject private var itemController: ItemController
    @Query private var items: [Item]

    var totalSales: Int {
        return itemController.calculateTotalSoldItems(for: items)
    }

    var totalSoldItemValue: Double {
        return itemController.calculateTotalSoldItemValue(for: items)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Total Sales")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(totalSales)")
                    .font(.title)
                    .foregroundStyle(.white)

                Spacer()

                Text("Total Sold Value")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(totalSoldItemValue.formatted(.currency(code: "USD")))")
                    .font(.title)
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding()
    }
}

struct OtherInfoCardContent: View {
    @Query private var items: [Item]

    private var recentlyListedItemTitle: String {
        if let mostRecentItem = items.max(by: { ($0.purchaseDate ?? Date.distantPast) < ($1.purchaseDate ?? Date.distantPast) }) {
            return mostRecentItem.title
        } else {
            return "Add an item"
        }
    }

    private var oldestItemTitle: String {
        if let oldestItem = items.min(by: { $0.purchaseDate ?? Date() < $1.purchaseDate ?? Date() }) {
            return oldestItem.title
        } else {
            return "Add an item"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Recently Added")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(recentlyListedItemTitle)")
                    .font(.title3)
                    .foregroundStyle(.white)

                Spacer()

                Text("Oldest Item")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(oldestItemTitle)")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding()
    }
}
