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
                                InventoryCardContent()
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
                        
                        HStack {
                            Spacer()
                            Link("Privacy Policy", destination: URL(string: "https://github.com/bronsonmullens/Just-Flip-It/blob/main/Privacy%20Policy.MD")!)
                            
                            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            
                            Spacer()
                        }
                        .padding(.top)
                        
                        Button {
                            Purchases.shared.restorePurchases { customerInfo, error in
                                
                                if customerInfo?.entitlements.all["Premium"]?.isActive == true {
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

// MARK: - Sales Data Card Content

fileprivate struct SalesDataCardContent: View {
    @EnvironmentObject private var itemController: ItemController
    @Query private var items: [Item]
    
    @AppStorage("salesDataDateFilter") private var salesDataDateFilter: DateFilter = .month
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Sales Data")
                    .font(.title)
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    .padding(.bottom)
                
                Text("Lifetime sales: \(itemController.calculateTotalSoldItems(for: items).formatted())")
                    .font(.headline)
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    .padding(.bottom)
                
                HStack {
                    Text("View sales by ")
                        .font(.headline)
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    
                    Picker("", selection: $salesDataDateFilter) {
                        ForEach(DateFilter.allCases, id: \.self) { dateFilter in
                            Text("\(dateFilter.rawValue)")
                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: salesDataDateFilter) { newDateFilter in
                        self.salesDataDateFilter = newDateFilter
                    }
                }
                
                SalesChartView(dateFilter: $salesDataDateFilter)
                    .padding(.bottom)
                
                Spacer()
            }
            
            Spacer()
        }
        .padding()
    }
    
    fileprivate struct SalesChartView: View {
        @EnvironmentObject private var itemController: ItemController
        @Query private var items: [Item]
        @Binding var dateFilter: DateFilter
        
        var body: some View {
            let salesData = salesData(for: dateFilter)
            
            if salesData.isEmpty {
                Text("Sell some items to view this data.")
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
            } else {
                ScrollView(.horizontal) {
                    Chart(salesData, id: \.date) { data in
                        BarMark(
                            x: .value("Date", data.date, unit: dateFilter == .week ? .day : .month),
                            y: .value("Total Sales", data.totalSales)
                        )
                    }
                    .frame(width: UIScreen.main.bounds.width)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: dateFilter == .week ? .day : .month)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: dateFilter == .week ? .dateTime.day() : .dateTime.month(), centered: true)
                        }
                    }
                }
                .defaultScrollAnchor(.trailing)
            }
        }
        
        private func salesData(for dateFilter: DateFilter) -> [(date: Date, totalSales: Int)] {
            let soldItems = items.filter { $0.soldDate != nil && $0.soldPrice != nil }
            
            let calendar = Calendar.current
            let now = Date()
            let startDate: Date
            let dateComponent: Calendar.Component
            
            switch dateFilter {
            case .week:
                startDate = calendar.date(byAdding: .day, value: -7, to: now)!
                dateComponent = .day
            case .month:
                startDate = calendar.date(byAdding: .month, value: -12, to: now)!
                dateComponent = .month
            }
            
            let filteredItems = soldItems.filter { $0.soldDate! >= startDate }
            
            let groupedData = Dictionary(grouping: filteredItems) { item in
                if dateFilter == .week {
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

// MARK: - Inventory Card Content

fileprivate struct InventoryCardContent: View {
    @EnvironmentObject private var itemController: ItemController
    @Query private var items: [Item]
    
    @AppStorage("inventoryDataDateFilter") private var inventoryDataDateFilter: DateFilter = .month
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Inventory Data")
                    .font(.title)
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    .padding(.bottom)
                
                Text("Inventory Size: \(itemController.calculateTotalInventoryItems(for: items).formatted())")
                    .font(.headline)
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    .padding(.bottom)
                
                HStack {
                    Text("View inventory by ")
                        .font(.headline)
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    
                    Picker("", selection: $inventoryDataDateFilter) {
                        ForEach(DateFilter.allCases, id: \.self) { dateFilter in
                            Text("\(dateFilter.rawValue)")
                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: inventoryDataDateFilter) { newDateFilter in
                        self.inventoryDataDateFilter = newDateFilter
                    }
                }
                
                InventoryChartView(dateFilter: $inventoryDataDateFilter)
                    .padding(.bottom)
                
                Spacer()
            }
            
            Spacer()
        }
        .padding()
    }
    
    fileprivate struct InventoryChartView: View {
        @EnvironmentObject private var itemController: ItemController
        @Query private var items: [Item]
        @Binding var dateFilter: DateFilter
        
        var body: some View {
            let inventoryData = inventoryData(for: dateFilter)
            
            if inventoryData.isEmpty {
                Text("Add some items to view this data.")
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
            } else {
                ScrollView(.horizontal) {
                    Chart(inventoryData, id: \.date) { data in
                        BarMark(
                            x: .value("Date", data.date, unit: dateFilter == .week ? .day : .month),
                            y: .value("Total Items", data.totalItems)
                        )
                    }
                    .frame(width: UIScreen.main.bounds.width)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: dateFilter == .week ? .day : .month)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: dateFilter == .week ? .dateTime.day() : .dateTime.month(), centered: true)
                        }
                    }
                }
                .defaultScrollAnchor(.trailing)
            }
        }
        
        private func inventoryData(for dateFilter: DateFilter) -> [(date: Date, totalItems: Int)] {
            let calendar = Calendar.current
            let now = Date()
            let endDate = calendar.startOfDay(for: now)
            var startDate: Date
            
            switch dateFilter {
            case .week:
                startDate = calendar.date(byAdding: .day, value: -6, to: endDate)!
            case .month:
                startDate = calendar.date(byAdding: .month, value: -11, to: endDate)!
                startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: startDate))!
            }
            
            let dateInterval = DateInterval(start: startDate, end: endDate)
            
            let inventoryItems = items.filter { $0.soldDate == nil }
            
            let groupedData = Dictionary(grouping: inventoryItems) { item in
                let itemDate = item.dateAdded ?? item.purchaseDate ?? now
                if dateFilter == .week {
                    return calendar.startOfDay(for: itemDate)
                } else {
                    return calendar.date(from: calendar.dateComponents([.year, .month], from: itemDate))!
                }
            }
            
            return calendar.generateDates(
                inside: dateInterval,
                matching: dateFilter == .week ? DateComponents(hour: 0, minute: 0, second: 0) : DateComponents(day: 1, hour: 0, minute: 0, second: 0)
            ).map { date in
                let itemsOnDate = groupedData[date]?.reduce(0) { $0 + $1.quantity } ?? 0
                return (date: date, totalItems: itemsOnDate)
            }
        }
    }
}

// MARK: - Top Selling Item Card Content

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
                count += itemController.calculateProfitForItem(soldItem, quantity: soldItem.quantity)
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
                        .font(.title)
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                        .padding(.bottom)
                    Text("\(topSellingItem.title)")
                        .font(.title3)
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    Text("Total sold: \(totalQuantitySoldForItem(topSellingItem))")
                        .font(.headline)
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    Text("Total profit: \(totalProfitMadeForItem(topSellingItem).formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                        .font(.headline)
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    Spacer()
                }
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Oldest-Newest Info Card Content

fileprivate struct OldestNewestInfoCardContent: View {
    @EnvironmentObject private var itemController: ItemController
    @Query private var items: [Item]
    
    private var inventoryItems: [Item] {
        return items.filter({ $0.soldPrice == nil })
    }
    
    private var recentlyListedItem: Item? {
        if let mostRecentItem = inventoryItems.max(by: { ($0.purchaseDate ?? Date.distantPast) < ($1.purchaseDate ?? Date.distantPast) }) {
            return mostRecentItem
        } else {
            return nil
        }
    }
    
    private var oldestItem: Item? {
        if let oldestItem = inventoryItems.min(by: { $0.purchaseDate ?? Date() < $1.purchaseDate ?? Date() }) {
            return oldestItem
        } else {
            return nil
        }
    }
    
    private func daysSince(_ start: Date) -> Int {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: start)
        let endDate = calendar.startOfDay(for: .now)
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return components.day ?? 0
    }
    
    var body: some View {
        if recentlyListedItem != nil || oldestItem != nil {
            HStack {
                VStack(alignment: .leading) {
                    if let recentlyListedItem {
                        Text("Recently Added")
                            .font(.title)
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                        Text("\(recentlyListedItem.title)")
                            .font(.title3)
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                        Text("Listed: \(recentlyListedItem.listedPrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                            .font(.headline)
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                            .padding(.bottom)
                    }
                    
                    Spacer()
                    
                    if let oldestItem {
                        Text("Oldest Item")
                            .font(.title)
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                        Text("\(oldestItem.title)")
                            .font(.title3)
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                        Text("Listed: \(oldestItem.listedPrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                            .font(.headline)
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                        if let purchaseDate = oldestItem.purchaseDate {
                            Text("Purchased: \(daysSince(purchaseDate).formatted()) days ago")
                                .font(.headline)
                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

fileprivate enum DateFilter: String, CaseIterable, Equatable {
    case week = "Week"
    case month = "Month"
}
