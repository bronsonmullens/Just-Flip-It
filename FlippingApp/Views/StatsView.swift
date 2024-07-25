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
    
    @State private var showingSubscribeSheet: Bool = false
    @State private var currentOffering: Offering?
    
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
                        }
                        .frame(width: 200, height: 200)
                    }
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    
                    VStack {
                        Spacer()
                        
                        Button {
                            self.showingSubscribeSheet.toggle()
                        } label: {
                            Text("Subscribe")
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                                        .frame(width: 160, height: 40)
                                        .shadow(color: .black, radius: 4, x: -2, y: 2)
                                )
                        }
                        
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
        .sheet(isPresented: $showingSubscribeSheet, content: {
            SubscribePage(currentOffering: $currentOffering, isPresented: $showingSubscribeSheet)
                .presentationDetents([.height(600)])
                .presentationDragIndicator(.hidden)
        })
        .onAppear {
            Purchases.shared.getOfferings { offerings, error in
                if let offering = offerings?.current, error == nil {
                    self.currentOffering = offering
                } else {
                    log.error("Error: \(error)")
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
    
    @AppStorage("timeFilter") private var timeFilter: TimeFilter = .month
    
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
                
                HStack {
                    Text("View sales by ")
                        .font(.title)
                        .foregroundStyle(.white)
                    
                    Picker("", selection: $timeFilter) {
                        ForEach(TimeFilter.allCases, id: \.self) { timeFilter in
                            Text("\(timeFilter.rawValue)")
                                .font(.title)
                                .foregroundStyle(.white)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: timeFilter) { newTimeFilter in
                        self.timeFilter = newTimeFilter
                    }
                }
                
                SalesChartView(timeFilter: $timeFilter)
                    .padding(.bottom)
                
                Spacer()
            }
            
            Spacer()
        }
        .padding()
    }
    
    fileprivate enum TimeFilter: String, CaseIterable, Equatable {
        case week = "Week"
        case month = "Month"
    }
    
    fileprivate struct SalesChartView: View {
        @Query private var items: [Item]
        @Binding var timeFilter: TimeFilter
        
        var body: some View {
            let salesData = salesData(for: timeFilter)
            
            if salesData.isEmpty {
                Text("Sell some items to view this data.")
                    .foregroundStyle(.white)
            } else {
                Chart(salesData, id: \.date) { data in
                    BarMark(
                        x: .value("Date", data.date, unit: timeFilter == .week ? .day : .month),
                        y: .value("Total Sales", data.totalSales)
                    )
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: timeFilter == .week ? .day : .month)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: timeFilter == .week ? .dateTime.day() : .dateTime.month(), centered: true)
                    }
                }
            }
        }
        
        private func salesData(for timeFilter: TimeFilter) -> [(date: Date, totalSales: Int)] {
            let soldItems = items.filter { $0.soldDate != nil && $0.soldPrice != nil }
            
            let calendar = Calendar.current
            let now = Date()
            let startDate: Date
            let dateComponent: Calendar.Component
            
            switch timeFilter {
            case .week:
                startDate = calendar.date(byAdding: .day, value: -7, to: now)!
                dateComponent = .day
            case .month:
                startDate = calendar.date(byAdding: .month, value: -12, to: now)!
                dateComponent = .month
            }
            
            let filteredItems = soldItems.filter { $0.soldDate! >= startDate }
            
            let groupedData = Dictionary(grouping: filteredItems) { item in
                if timeFilter == .week {
                    return calendar.startOfDay(for: item.soldDate!)
                } else {
                    return calendar.date(from: calendar.dateComponents([.year, .month], from: item.soldDate!))!
                }
            }
            
            return calendar.generateDates(
                inside: DateInterval(start: startDate, end: now),
                matching: DateComponents(hour: 0, minute: 0, second: 0)
            ).map { date in
                let totalSales = groupedData[date]?.count ?? 0
                return (date: date, totalSales: totalSales)
            }
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
        if recentlyListedItem != nil || oldestItem != nil {
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
}
