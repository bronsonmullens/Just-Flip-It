//
//  CardsView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI
import SwiftData

fileprivate enum CardType: CaseIterable {
    case profit
    case value
    case sales
}

struct CardsView: View {
    var body: some View {
        ScrollView {
            Card {
                ProfitCardContent()
            }
            
            Card {
                TotalValueCardContent()
            }
            
            Card {
                SoldItemsCardContent()
            }
        }
    }
}
// MARK: - Profit Card Content

fileprivate struct ProfitCardContent: View {
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
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                Spacer()
                Text("\(profit.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                    .font(.largeTitle)
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - Total Value Card Content

fileprivate struct TotalValueCardContent: View {
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
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                Text("\(totalValue.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                    .font(.title)
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))

                Spacer()

                Text("Current Investment")
                    .font(.headline)
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                Text("\(totalInvestment.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                    .font(.title)
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
            }

            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Item Count")
                    .font(.headline)
                Text("\(inventoryCount.formatted())")
                    .font(.title)
                
                Text("Total Listings")
                    .font(.headline)
                Text("\(items.count.formatted())")
                    .font(.title)
            }
            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
        }
        .padding()
    }
}

// MARK: - Sold Items Card Content

fileprivate struct SoldItemsCardContent: View {
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
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                Text("\(totalSales)")
                    .font(.title)
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))

                Spacer()

                Text("Total Sold Value")
                    .font(.headline)
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                Text("\(totalSoldItemValue.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                    .font(.title)
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
            }
            Spacer()
        }
        .padding()
    }
}
