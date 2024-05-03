//
//  Just_Flip_ItApp.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI
import SwiftData
import OSLog

@main
struct Just_Flip_It_App: App {
    @StateObject private var itemController: ItemController

    public let log = OSLog(subsystem: "com.bronsonmullens.Just-Flip-It", category: "game")
    var modelContainer: ModelContainer

    init() {
        do {
            let modelContainer = try ModelContainer(for: Item.self, Tag.self)
            self.modelContainer = modelContainer
            _itemController = StateObject(wrappedValue: ItemController(modelContainer: modelContainer))
        } catch {
            fatalError("Could not initialize ModelContainer")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(itemController)
                .modelContainer(modelContainer)
        }
    }
}