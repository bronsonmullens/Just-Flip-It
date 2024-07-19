//
//  StatsView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var itemController: ItemController
    
    var body: some View {
        ZStack {
            // Background color
            Color("\(itemController.selectedTheme.rawValue)Background")
                .ignoresSafeArea()

            if itemController.hasPremium {
                Text("Premium ")
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
