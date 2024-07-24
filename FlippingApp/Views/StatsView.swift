//
//  StatsView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI
import SwiftData
import Charts

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
                            StatsCard()
                            StatsCard()
                            StatsCard()
                            StatsCard()
                            StatsCard()
                            StatsCard()
                        }
                    }
                }
            } else {
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
            }
        }
    }
}

fileprivate struct StatsCard: View {
    @EnvironmentObject private var itemController: ItemController
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .frame(height: 100)
            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Foreground"))
            .shadow(color: .black, radius: 4, x: -2, y: 2)
            .overlay(
            Text("Sample")
            )
    }
}
