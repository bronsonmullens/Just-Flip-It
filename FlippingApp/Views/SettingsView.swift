//
//  SettingsView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI
import SwiftData
import MessageUI
import WebKit
import RevenueCat

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @EnvironmentObject private var itemController: ItemController
    @Query private var items: [Item]
    
    @State private var showingWhatsNewInfo: Bool = false
    @State private var showingMailView: Bool = false
    @State private var result: Result<MFMailComposeResult, Error>? = nil
    @State private var showingTipJarAlert: Bool = false
    @State private var showingSubscribePage: Bool = false
    @State private var showingPrivacyPolicyPage: Bool = false
    @State private var showingDeletionAlert: Bool = false
    @State private var itemTypeToDelete: DeleteType?
    @State private var showingEmailUnavailableAlert: Bool = false
    @State private var currentOffering: Offering?
    @State private var showingHelpPage: Bool = false
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    private let supportVideoLink = "https://youtu.be/IU6uj-rIe5s"
    
    private var mailButtonEnabled: Bool {
        MFMailComposeViewController.canSendMail()
    }
    
    private func openTwitterSupport() {
        let screenName = "bronsonmullens"
        let appURL = URL(string: "twitter://user?screen_name=\(screenName)")!
        let webURL = URL(string: "https://twitter.com/\(screenName)")!
        
        let application = UIApplication.shared
        
        if application.canOpenURL(appURL as URL) {
            application.open(appURL)
        } else {
            application.open(webURL)
        }
    }
    
    private func presentReview() {
        Task {
            // Delay for two seconds to avoid interrupting the person using the app.
            try await Task.sleep(for: .seconds(1))
            await requestReview()
        }
    }
    
    // MARK: - CSV Support
    
    private func generateCSVForInventory() -> URL {
        var fileURL: URL!
        
        let inventoryItems = items.filter { $0.soldPrice == nil }
        
        let heading = "Item, Quantity, Purchase Date, Purchase Price, Listed Price, Tag, Notes\n"
        let rows = inventoryItems.map {"\($0.title), \($0.quantity.formatted()), \($0.purchaseDate?.formatted(date: .numeric, time: .omitted) ?? ""), \($0.purchasePrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))), \($0.listedPrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))), \($0.tag?.title ?? ""), \($0.notes ?? "")" }
        
        let stringData = heading + rows.joined(separator: "\n")
        
        do {
            let path = try FileManager.default.url(
                for: .documentDirectory,
                in: .allDomainsMask,
                appropriateFor: nil,
                create: false)
            
            fileURL = path.appendingPathComponent("Inventory-Items.csv")
            
            try stringData.write(to: fileURL, atomically: true, encoding: .utf8)
            log.info("Wrote string data to \(fileURL)")
        } catch {
            log.error("Could not export CSV: \(error)")
        }
        
        return fileURL
    }
    
    private func generateCSVForSoldItems() -> URL {
        var fileURL: URL!
        
        let soldItems = items.filter { $0.soldPrice != nil }
        
        let heading = "Item, Quantity, Purchase Date, Purchase Price, Listed Price, Tag, Notes, Sold Date, Sold Price, Platform Fees, Other Fees\n"
        let rows = soldItems.map {"\($0.title), \($0.quantity.formatted()), \($0.purchaseDate?.formatted(date: .numeric, time: .omitted) ?? ""), \($0.purchasePrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))), \($0.listedPrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))), \($0.tag?.title ?? ""), \($0.notes ?? ""), \($0.soldDate?.formatted(date: .numeric, time: .omitted) ?? ""), \($0.soldPrice?.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")) ?? ""), \($0.platformFees?.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")) ?? ""), \($0.otherFees?.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")) ?? "")" }
        
        let stringData = heading + rows.joined(separator: "\n")
        
        do {
            let path = try FileManager.default.url(
                for: .documentDirectory,
                in: .allDomainsMask,
                appropriateFor: nil,
                create: false)
            
            fileURL = path.appendingPathComponent("Sold-Items.csv")
            
            try stringData.write(to: fileURL, atomically: true, encoding: .utf8)
            log.info("Wrote string data to \(fileURL)")
        } catch {
            log.error("Could not export CSV: \(error)")
        }
        
        return fileURL
    }
    
    var body: some View {
        Form {
            Section {
                Text("👨🏼‍💻 App Version: \(appVersion ?? "Unknown")")
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                
                Button(action: {
                    self.showingWhatsNewInfo.toggle()
                }, label: {
                    Text("📢 What's New?")
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                })
                
                Button(action: {
                    self.openTwitterSupport()
                }, label: {
                    Text("🐦 Social Media")
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                })
                
                Button(action: {
                    self.showingPrivacyPolicyPage.toggle()
                }, label: {
                    Text("⚖️ Privacy Policy")
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                })
                
                Link("💼 Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            }
            .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
            
            Section {
                Picker("🎨 Select a Theme", selection: $itemController.selectedTheme) {
                    ForEach(ColorTheme.allCases, id: \.self) {
                        Text($0.rawValue)
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    }
                    .pickerStyle(.menu)
                    .onChange(of: itemController.selectedTheme) { newTheme in
                        itemController.selectedTheme = newTheme
                    }
                }
                .foregroundStyle(itemController.hasPremium == false ? .gray : Color("\(itemController.selectedTheme.rawValue)Text"))
                .disabled(itemController.hasPremium == false)
                
                ShareLink(item: generateCSVForInventory()) {
                    Text("📄 Export Inventory")
                        .foregroundStyle(itemController.hasPremium ? Color("\(itemController.selectedTheme.rawValue)Text") : .gray)
                }
                .disabled(itemController.hasPremium == false)
                
                ShareLink(item: generateCSVForSoldItems()) {
                    Text("📄 Export Sales")
                        .foregroundStyle(itemController.hasPremium ? Color("\(itemController.selectedTheme.rawValue)Text") : .gray)
                }
                .disabled(itemController.hasPremium == false)
            }
            .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
            
            Section {
                Button(action: {
                    self.showingSubscribePage.toggle()
                }, label: {
                    Text("✨ Premium Subscription")
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                })
                
                Button(action: {
                    self.showingTipJarAlert.toggle()
                }, label: {
                    Text("🫙 Tip Jar")
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                })
                
                Button(action: {
                    self.presentReview()
                }, label: {
                    Text("⭐️ Rate the App")
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                })
                
                Button(action: {
                    if mailButtonEnabled {
                        self.showingMailView.toggle()
                    } else {
                        self.showingEmailUnavailableAlert.toggle()
                    }
                }, label: {
                    if mailButtonEnabled {
                        Text("📧 Email Feedback")
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    } else {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Email Feedback Unavailable")
                        }
                        .foregroundStyle(.gray)
                    }
                })
                
                Button(action: {
                    self.showingHelpPage.toggle()
                }, label: {
                    Text("🛟 Help")
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                })
            }
            .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
            
            Section {
                Button(action: {
                    self.itemTypeToDelete = .inventory
                    self.showingDeletionAlert.toggle()
                }, label: {
                    Text("🗑️ Delete Inventory")
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                })
                
                Button(action: {
                    self.itemTypeToDelete = .soldItems
                    self.showingDeletionAlert.toggle()
                }, label: {
                    Text("🗑️ Delete Sold Items")
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                })
                
                Button(action: {
                    self.itemTypeToDelete = .tags
                    self.showingDeletionAlert.toggle()
                }, label: {
                    Text("🗑️ Delete Tags")
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                })
                
                Button(action: {
                    self.itemTypeToDelete = .everything
                    self.showingDeletionAlert.toggle()
                    try? modelContext.save()
                }, label: {
                    Text("⚠️ Delete Everything")
                        .bold()
                })
            }
            .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
        }
        .scrollContentBackground(.hidden)
        .sheet(isPresented: $showingWhatsNewInfo, content: {
            WhatsNewView()
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.hidden)
                .background {
                    (Color("\(itemController.selectedTheme.rawValue)Background"))
                        .ignoresSafeArea(.all)
                }
        })
        .sheet(isPresented: $showingMailView, content: {
            MailView(isPresented: $showingMailView, result: $result)
        })
        .sheet(isPresented: $showingTipJarAlert, content: {
            TipJarView()
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.hidden)
        })
        .sheet(isPresented: $showingSubscribePage, content: {
            SubscribePage(currentOffering: $currentOffering, isPresented: $showingSubscribePage)
                .presentationDetents([.height(600)])
                .presentationDragIndicator(.hidden)
        })
        .sheet(isPresented: $showingPrivacyPolicyPage, content: {
            PrivacyPolicyPage()
        })
        .sheet(isPresented: $showingHelpPage, content: {
            HelpPage()
        })
        .alert("Delete \(itemTypeToDelete?.rawValue ?? "Unknown")?", isPresented: $showingDeletionAlert) {
            Button("Yes", role: .destructive) {
                self.itemController.delete(itemTypeToDelete ?? .error)
            }
            Button("Nevermind", role: .cancel) { }
        } message: {
            Text("This will permanently delete the chosen data. Are you sure you want to proceed?")
        }
        .alert("Email Unavailable", isPresented: $showingEmailUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("If you would like to get into contact with me, find me on X @bronsonmullens or email me at bronsonmullens@icloud.com")
        }
        .background(Color("\(itemController.selectedTheme.rawValue)Background"))
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

// MARK: - What's New

struct WhatsNewView: View {
    @EnvironmentObject private var itemController: ItemController
    
    var body: some View {
        ZStack {
            Color("\(itemController.selectedTheme.rawValue)Background")
                .ignoresSafeArea(.all)
            
            VStack(alignment: .leading) {
                Text("🎉 MASSIVE UPDATE!")
                    .font(.title3)
                    .padding(.bottom)
                Text("- A new, modern UI")
                Text("- Automatic cloud backups with iCloud")
                Text("- Changes to listing, editing, and selling items")
                Text("- Support for item & platform fees")
                Text("- Premium features added")
                Text("- Automated migration for old item data")
                Text("- Various bug fixes")
            }
            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
            .padding()
        }
    }
}

// MARK: - Tip Jar

struct TipJarView: View {
    @EnvironmentObject private var itemController: ItemController
    @State private var tipPackages: [Package]?
    @State private var showingTipThankYouAlert: Bool = false
    
    var body: some View {
        ZStack {
            Color("\(itemController.selectedTheme.rawValue)Background")
                .ignoresSafeArea(.all)
            
            VStack {
                Text("🫙 Tip Jar 🫙")
                    .font(.title2)
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    .padding(.top)
                Text("Thank you for supporting me ❤️")
                    .font(.headline)
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    .padding(.bottom)
                Text("Keep in mind this is simply you tipping me as a way to thank me for the work I put into the app. You will not receive anything for tipping except my gratitude.")
                    .font(.caption)
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
                
                if let tipPackages {
                    ForEach(tipPackages) { package in
                        HStack {
                            if package.identifier == "small-tip" {
                                VStack(alignment: .leading) {
                                    Text("Small Tip")
                                        .font(.title3)
                                    Text("Still very appreciated :)")
                                        .font(.caption)
                                }
                                
                                Spacer()
                                
                                Button {
                                    Purchases.shared.purchase(package: package) { (transaction, customerInfo, error, userCancelled) in
                                        if let customerInfo, error == nil {
                                            log.info("User tipped: \(transaction?.productIdentifier)")
                                            self.showingTipThankYouAlert.toggle()
                                        }
                                    }
                                } label: {
                                    Text("\(package.storeProduct.localizedPriceString)")
                                        .foregroundStyle(.white)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.accentColor)
                                        )
                                }
                                
                            } else if package.identifier == "big-tip" {
                                VStack(alignment: .leading) {
                                    Text("Big Tip")
                                        .font(.title3)
                                    Text("Legendary support! :o")
                                        .font(.caption)
                                }
                                
                                Spacer()
                                
                                Button {
                                    Purchases.shared.purchase(package: package) { (transaction, customerInfo, error, userCancelled) in
                                        if let customerInfo, error == nil {
                                            log.info("User tipped: \(transaction?.productIdentifier)")
                                            self.showingTipThankYouAlert.toggle()
                                        }
                                    }
                                } label: {
                                    Text("\(package.storeProduct.localizedPriceString)")
                                        .foregroundStyle(.white)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.accentColor)
                                        )
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .alert("Email Unavailable", isPresented: $showingTipThankYouAlert) {
                Button("You're welcome!", role: .cancel) { }
            } message: {
                Text("Thank you so much! ❤️❤️❤️")
            }
            .onAppear {
                Purchases.shared.getOfferings { (offerings, error) in
                    if let packages = offerings?.offering(identifier: "Tips")?.availablePackages {
                        log.info("Fetched tips packages")
                        self.tipPackages = packages
                    }
                }
            }
        }
    }
}

// MARK: - Subscribe Page

struct SubscribePage: View {
    @EnvironmentObject private var itemController: ItemController
    
    @Binding var currentOffering: Offering?
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color("\(itemController.selectedTheme.rawValue)Background")
                .ignoresSafeArea(.all)
            
            ScrollView {
                if let currentOffering = currentOffering {
                    VStack(alignment: .center) {
                        VStack(alignment: .center) {
                            Text("✨ Premium Subscription ✨")
                                .font(.title)
                                .padding(.bottom)
                            
                            Text("Unlock everything Just Flip It has to offer for a small monthly fee and support an indie developer.")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.bottom)
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "photo")
                                Text("Attach images to items")
                            }
                            .padding(.bottom)
                            
                            HStack {
                                Image(systemName: "doc")
                                Text("Export data as CSV")
                            }
                            .padding(.bottom)
                            
                            HStack {
                                Image(systemName: "chart.bar.xaxis")
                                Text("See detailed stats*")
                            }
                            .padding(.bottom)
                            
                            HStack {
                                Image(systemName: "paintbrush")
                                Text("Apply various themes")
                            }
                            .padding(.bottom)
                        }
                        .font(.title3)
                    }
                    
                    Spacer()
                    
                    if itemController.hasPremium {
                        Text("You're all set! 😊")
                            .font(.title)
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                            .padding(.bottom)
                    } else {
                        ForEach(currentOffering.availablePackages) { package in
                            Button {
                                Purchases.shared.purchase(package: package) { (transaction, customerInfo, error, userCancelled) in
                                    if customerInfo?.entitlements["Premium"]?.isActive == true {
                                        log.info("Premium purchased. Setting hasPremium to true.")
                                        itemController.hasPremium = true
                                        self.isPresented = false
                                    }
                                }
                            } label: {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading) {
                                        Text("1 Month")
                                        Text("Billed Monthly")
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(package.storeProduct.localizedPriceString)")
                                }
                                .padding(.horizontal)
                                .bold()
                                .foregroundStyle(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .foregroundStyle(Color.accentColor)
                                        .frame(minWidth: 250)
                                        .shadow(color: .black, radius: 4, x: -2, y: 2)
                                )
                            }
                        }
                    }
                    
                    Button {
                        Purchases.shared.restorePurchases { customerInfo, error in
                            
                            if customerInfo?.entitlements.all["Premium"]?.isActive == true {
                                log.info("Restoring premium access to user.")
                                itemController.hasPremium = true
                                self.isPresented = false
                            }
                        }
                    } label: {
                        Text("Restore Purchases")
                    }
                    .padding(.top)
                    
                    HStack {
                        Spacer()
                        Link("Privacy Policy", destination: URL(string: "https://github.com/bronsonmullens/Just-Flip-It/blob/main/Privacy%20Policy.MD")!)
                        
                        Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    Spacer()
                    
                    Text("* Data from older versions of the app, that has been migrated, may be missing properties from new data models. Missing data may need to be manually edited to ensure accuracy.")
                        .font(.caption)
                } else {
                    HStack(alignment: .bottom) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 60)
                        
                        VStack(alignment: .leading) {
                            Text("Something went wrong.")
                                .bold()
                            
                            Text("Please reach out to me at bronsonmullens@icloud.com.")
                        }
                    }
                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                }
            }
            .padding()
        }
    }
}

// MARK: - Privacy Policy

struct PrivacyPolicyPage: View {
    @EnvironmentObject private var itemController: ItemController
    
    var body: some View {
        ZStack {
            Color("\(itemController.selectedTheme.rawValue)Background")
                .ignoresSafeArea(.all)
            
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("I do not collect or store your data.")
                        .font(.largeTitle)
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    Text("Seriously.")
                        .font(.headline)
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                }
                .padding(.bottom)
                
                VStack(alignment: .leading) {
                    Text("For questions or comments please email me using the 'Email Feedback' feature in settings.\n")
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    
                    Text("All of your personal information, including item data, is initially stored locally on your device. For cloud backups, Just Flip It! uses Apple's CloudKit service which is entirely outside of my view and control. Item and tag data is automatically synced to their secure iCloud servers as you use the app.\n")
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    
                    Text("You can delete your data at any time by deleting individual items in your inventory and sold items view or by using the various deletion options found in settings.")
                        .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

fileprivate struct HelpPage: View {
    @EnvironmentObject private var itemController: ItemController
    
    var body: some View {
        ZStack {
            Color("\(itemController.selectedTheme.rawValue)Background")
                .ignoresSafeArea(.all)
            
            Form {
                Section("Creating Items") {
                    Text("Tap the + on the home screen and select 'Add to inventory' to bring up the add item sheet. Here you can specify details for your item before saving it to your inventory.")
                }
                .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                
                Section("Selling Items") {
                    Text("Just like adding an item, you may tap the + on the home screen and select 'Report a sale'. This will pull up a view of your inventory where you may select an item to sell.")
                    
                    Text("Alternatively, you may sell an item directly from the inventory after selecting an item to edit.")
                    
                    Text("After selling an item, your quantity for that item will be reduced by the sold amount. If that amount reaches 0, and you didn't toggle off auto-deletion for that item, the item will be deleted from your inventory.")
                }
                .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                
                Section("Viewing your Items") {
                    Text("Tap the Inventory tab to view your current active items and the Receipts tab to view your previously sold items.")
                    Text("You may change the way items are displayed - either as rows or in a grid.")
                }
                .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                
                Section("Providing Feedback") {
                    Text("Feel free to send me any feedback, suggestions, or report bugs to my email. You can find a link in settings. I'll be taking a more active approach to working on this app, so I hope I can make it the best it can be :)")
                }
                .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
            }
            .offset(y: 50)
            .padding(.bottom)
            .scrollContentBackground(.hidden)
        }
    }
}
