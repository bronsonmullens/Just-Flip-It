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
    @EnvironmentObject private var itemController: ItemController
    
    var cardType: CardType

    private var height: CGFloat {
        switch cardType {
        case .profit:
            return Theme.CardsView.Card.ProfitCardHeight
        case .value:
            return Theme.CardsView.Card.ValueCardHeight
        case .sales:
            return Theme.CardsView.Card.SalesCardHeight
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.CardsView.Card.CardCornerRadius)
                .frame(height: height)
                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Foreground"))
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

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Net Profit")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(profit.formatted(.currency(code: "USD")))")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
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
                Text("Current Inventory Value")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(totalValue.formatted(.currency(code: "USD")))")
                    .font(.title)
                    .foregroundStyle(.white)

                Spacer()

                Text("Current Investment")
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
                Text("Sales to Date")
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
