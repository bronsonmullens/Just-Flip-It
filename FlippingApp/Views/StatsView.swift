//
//  StatsView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI
import SwiftData
import Charts
import RevenueCat

struct StatsView: View {
    @EnvironmentObject private var itemController: ItemController
    @Query private var items: [Item]
    
    var body: some View {
        ZStack {
            // Background color
            Color("\(itemController.selectedTheme.rawValue)Background")
                .ignoresSafeArea()
            
            if itemController.hasPremium {
                ZStack {
                    Color("\(itemController.selectedTheme.rawValue)Background")
                        .ignoresSafeArea(.all)
                    
                    VStack {
                        ScrollView {
                            Card {
                                SalesDataCardContent()
                            }
                            
                            Card {
                                TopSellingItemCardContent()
                            }
                            
                            Card {
                                OldestNewestInfoCardContent()
                            }
                        }
                    }
                }
            } else {
                ZStack {
                    HStack(alignment: .center) {
                        Image(systemName: "cart")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 72)
                            .padding()
                        
                        VStack(alignment: .leading) {
                            Text("Oh no!")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("It looks like you haven't purchased a premium subscription yet.")
                                .padding(.bottom)
                            Text("Check out the settings tab to get started.")
                                .fontWeight(.medium)
                        }
                        .frame(width: 200, height: 200)
                    }
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    
                    VStack {
                        Spacer()
                        
                        Button {
                            Purchases.shared.restorePurchases { customerInfo, error in
                                
                                if customerInfo?.entitlements.all["Pro"]?.isActive == true {
                                    log.info("Restoring premium access to user.")
                                    itemController.hasPremium = true
                                }
                            }
                        } label: {
                            Text("Restore Purchases")
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

struct Card<Content: View>: View {
    @EnvironmentObject private var itemController: ItemController
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                    .shadow(color: .black, radius: 4, x: -2, y: 2)
            )
            .padding()
    }
}

fileprivate struct SalesDataCardContent: View {
    @EnvironmentObject private var itemController: ItemController
    @Query private var items: [Item]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Sales Data")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.bottom)
                
                Text("Lifetime sales: \(itemController.calculateTotalSoldItems(for: items).formatted())")
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding(.bottom)
                
                Text("Sales by month")
                    .font(.title)
                    .foregroundStyle(.white)
                
                SalesChartView()
                    .padding(.bottom)
                
                Spacer()
            }
            
            Spacer()
        }
        .padding()
    }
    
    fileprivate struct SalesChartView: View {
        @Query private var items: [Item]
        
        var body: some View {
            let salesData = monthlySalesData()
            
            Chart(salesData, id: \.month) { data in
                BarMark(
                    x: .value("Month", data.month, unit: .month),
                    y: .value("Total Sales", data.totalSales)
                )
            }
        }
        
        private func monthlySalesData() -> [(month: Date, totalSales: Int)] {
            let soldItems = items.filter { $0.soldDate != nil && $0.soldPrice != nil }
            
            let groupedByMonth = Dictionary(grouping: soldItems) { item in
                Calendar.current.startOfMonth(for: item.soldDate!)
            }
            
            return groupedByMonth.map { (month, items) in
                let totalSales = items.count
                return (month: month, totalSales: totalSales)
            }.sorted { $0.month < $1.month }
        }
    }
}

fileprivate struct TopSellingItemCardContent: View {
    @EnvironmentObject private var itemController: ItemController
    @Query private var items: [Item]
    
    private func totalQuantitySoldForItem(_ item: Item) -> Int {
        let soldItems = items.filter { $0.soldPrice != nil }
        var count = 0
        
        for soldItem in soldItems {
            if soldItem.title == item.title {
                count += soldItem.quantity
            }
        }
        
        return count
    }
    
    private func totalProfitMadeForItem(_ item: Item) -> Double {
        let soldItems = items.filter { $0.soldPrice != nil }
        var count = 0.0
        
        for soldItem in soldItems {
            if soldItem.title == item.title {
                count += itemController.calculateProfitForItem(soldItem)
            }
        }
        
        return count
    }
    
    private func topSellingItem() -> Item? {
        let soldItems = items.filter { $0.soldPrice != nil }
        
        guard !soldItems.isEmpty else {
            return nil
        }
        
        var topItem = soldItems[0] // Start with the first sold item
        
        for item in soldItems {
            if item.quantity > topItem.quantity {
                topItem = item
            } else if item.quantity == topItem.quantity {
                // If quantities are equal, compare by total revenue
                let itemRevenue = (item.soldPrice ?? 0) * Double(item.quantity)
                let topItemRevenue = (topItem.soldPrice ?? 0) * Double(topItem.quantity)
                
                if itemRevenue > topItemRevenue {
                    topItem = item
                }
            }
        }
        
        return topItem
    }
    
    var body: some View {
        if let topSellingItem = topSellingItem() {
            HStack {
                VStack(alignment: .leading) {
                    Text("Top selling item")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.bottom)
                    
                    Text("\(topSellingItem.title)")
                        .font(.title2)
                        .foregroundStyle(.white)
                    Text("Total sold: \(totalQuantitySoldForItem(topSellingItem))")
                        .font(.title3)
                        .foregroundStyle(.white)
                    Text("Total profit: \(totalProfitMadeForItem(topSellingItem).formatted(.currency(code: "USD")))")
                        .font(.title3)
                        .foregroundStyle(.white)
                    Spacer()
                }
                Spacer()
            }
            .padding()
        }
    }
}

fileprivate struct OldestNewestInfoCardContent: View {
    @Query private var items: [Item]

    private var recentlyListedItem: Item? {
        if let mostRecentItem = items.max(by: { ($0.purchaseDate ?? Date.distantPast) < ($1.purchaseDate ?? Date.distantPast) }) {
            return mostRecentItem
        } else {
            return nil
        }
    }

    private var oldestItem: Item? {
        if let oldestItem = items.min(by: { $0.purchaseDate ?? Date() < $1.purchaseDate ?? Date() }) {
            return oldestItem
        } else {
            return nil
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if let recentlyListedItem {
                    Text("Recently Added")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(recentlyListedItem.title)")
                        .font(.title3)
                        .foregroundStyle(.white)
                    Text("Listed: \(recentlyListedItem.listedPrice.formatted(.currency(code: "USD")))")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(.bottom)
                }
                
                Spacer()

                if let oldestItem {
                    Text("Oldest Item")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(oldestItem.title)")
                        .font(.title3)
                        .foregroundStyle(.white)
                    Text("Listed: \(oldestItem.listedPrice.formatted(.currency(code: "USD")))")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}
