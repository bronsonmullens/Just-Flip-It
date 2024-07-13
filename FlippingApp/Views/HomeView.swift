//
//  HomeView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var itemController: ItemController

    @State private var presentingAddToInventorySheet: Bool = false
    @State private var presentingSellItemSheet: Bool = false

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Menu {
                    Button {
                        presentingAddToInventorySheet.toggle()
                    } label: {
                        Text("Add to inventory")
                    }

                    Button {
                        presentingSellItemSheet.toggle()
                    } label: {
                        Text("Report a sale")
                    }
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .frame(
                            width: Theme.HomeView.Button.ButtonWidth,
                            height: Theme.HomeView.Button.ButtonWidth
                        )
                }
            }
            .padding(.horizontal)

            CardsView()

            Spacer()
        }
        .sheet(isPresented: $presentingAddToInventorySheet) {
            AddInventoryItemView(isPresented: $presentingAddToInventorySheet)
        }
        .sheet(isPresented: $presentingSellItemSheet) {
            InventoryView(searchMode: .inventory, sellMode: true)
        }
    }
}
