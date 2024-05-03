//
//  MainView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI

struct MainView: View {
    @State private var selectedItem: Item?
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(
                        title: { Text("Home") },
                        icon: { Image(systemName: "house") }
                    )
                }

            SearchView(selectedItem: $selectedItem)
                .tabItem {
                    Label(
                        title: { Text("Search") },
                        icon: { Image(systemName: "magnifyingglass") }
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
    }
}
