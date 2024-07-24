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
                                VStack {
                                    Text("Hello")
                                    Text("Hello")
                                    Text("Hello")
                                    Text("Hello")
                                    Text("Hello")
                                    Text("Hello")
                                }
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
                
                Text("Lifetime sales :\(itemController.calculateTotalSoldItems(for: items))")
                    .font(.title)
                    .foregroundStyle(.white)
                
                Text("Sales by month")
                    .font(.title)
                    .foregroundStyle(.white)
                
                Chart(items) { item in
                    BarMark(
                        x: .value("Date", item.soldDate ?? Date(), unit: .month),
                        y: .value("Total Count", item.quantity)
                    )
                }
                
                Spacer()
            }
            
            Spacer()
        }
        .padding()
    }
}
