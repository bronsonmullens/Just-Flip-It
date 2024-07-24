//
//  MainView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI

struct MainView: View {
    @AppStorage("firstLaunch") var firstLaunch: Bool = true // TODO: Remove
    @Environment(\.modelContext) private var modelContext // TODO: Remove
    @EnvironmentObject private var itemController: ItemController
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(
                        title: { Text("Home") },
                        icon: { Image(systemName: "house") }
                    )
                }

            InventoryView(searchMode: .inventory, sellMode: false)
                .tabItem {
                    Label(
                        title: { Text("Inventory") },
                        icon: { Image(systemName: "list.bullet.clipboard.fill") }
                    )
                }
            
            InventoryView(searchMode: .receipts, sellMode: false)
                .tabItem {
                    Label(
                        title: { Text("Receipts") },
                        icon: { Image(systemName: "dollarsign.circle.fill") }
                    )
                }

            StatsView()
                .tabItem {
                    Label(
                        title: { Text("Stats") },
                        icon: { Image(systemName: "chart.bar.fill") }
                    )
                }

            SettingsView()
                .tabItem {
                    Label(
                        title: { Text("Settings") },
                        icon: { Image(systemName: "gearshape") }
                    )
                }
        }
        .onAppear {
            UITabBar.appearance().backgroundColor = .clear
            UITabBar.appearance().barTintColor = UIColor(Color("\(itemController.selectedTheme.rawValue)Text"))
            
            if firstLaunch {
                firstLaunch = false
                let dummyData = itemController.createDummyItems()
                
                for item in dummyData {
                    modelContext.insert(item)
                }
                
                try? modelContext.save()
            }
        }
        .tint(Color("\(itemController.selectedTheme.rawValue)Text"))
    }
}
