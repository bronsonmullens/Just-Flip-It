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
    @State private var showingiCloudSyncInfoMessage: Bool = false

    var body: some View {
        VStack {
            HStack {
                Button {
                    self.showingiCloudSyncInfoMessage.toggle()
                } label: {
                    Image(systemName: "cloud.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 20)
                        .foregroundStyle(.accent)
                        .shadow(color: .black, radius: 2, x: -1, y: 1)
                }
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
                            width: 30,
                            height: 30
                        )
                }
            }
            .padding(.horizontal)

            CardsView()

            Spacer()
        }
        .background(Color("\(itemController.selectedTheme.rawValue)Background"))
        .sheet(isPresented: $presentingAddToInventorySheet) {
            AddInventoryItemView(isPresented: $presentingAddToInventorySheet)
        }
        .sheet(isPresented: $presentingSellItemSheet) {
            InventoryView(searchMode: .inventory, sellMode: true)
        }
        .alert("iCloud Sync", isPresented: $showingiCloudSyncInfoMessage) {
            //
        } message: {
            Text("Data stored in Just Flip It is synced to your personal iCloud. Visit Settings > iCloud > to ensure you have the space available. Storing images will greatly increase the space required. If you reinstalled the app, and had data previously, allow up to five minutes for data to automatically sync.")
        }

    }
}
