//
//  SettingsView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI
import StoreKit
import MessageUI
import WebKit
import RevenueCat

struct SettingsView: View {
    @EnvironmentObject private var itemController: ItemController
    
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
    
    private func openYouTubeSupport() {
        let webURL = URL(string: "https://youtu.be/IU6uj-rIe5s")! // TODO: Create support video
        
        let application = UIApplication.shared
        application.open(webURL)
        
    }
    
    private func rateAppRequest() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    var body: some View {
        VStack {
            VStack {
                Image("JFILogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black, radius: 3.0)
                    .frame(width: 128)
                
                HStack {
                    Text("App Version:")
                        .bold()
                    Text(appVersion ?? "Unknown")
                }
                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                .bold()
            }
            .padding(.top)
            
            Form {
                Section {
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
                }
                .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                
                Section {
                    HStack {
                        Text("Select a theme")
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                        
                        Picker("", selection: $itemController.selectedTheme) {
                            ForEach(ColorTheme.allCases, id: \.self) {
                                Text($0.rawValue)
                                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: itemController.selectedTheme) { newTheme in
                            itemController.selectedTheme = newTheme
                        }
                    }
                }
                .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
                
                Section {
                    Button(action: {
                        self.showingSubscribePage.toggle()
                    }, label: {
                        Text("💸 Subscribe")
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    })
                    
                    Button(action: {
                        self.showingTipJarAlert.toggle()
                    }, label: {
                        Text("🫙 Tip Jar")
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                    })
                    
                    Button(action: {
                        self.rateAppRequest()
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
                        self.openYouTubeSupport()
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
                    }, label: {
                        Text("⚠️ Delete Everything")
                            .bold()
                    })
                }
                .listRowBackground(Color("\(itemController.selectedTheme.rawValue)Foreground"))
            }
            .scrollContentBackground(.hidden)
        }
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
                .presentationDetents([.height(230)])
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

// MARK: - Supporting Sheet Views

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
            .padding()
        }
    }
}

struct TipJarView: View {
    @EnvironmentObject private var itemController: ItemController
    
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
                
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text("Small Tip")
                            .font(.title3)
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                        Text("Still very appreciated :)")
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                            .font(.caption)
                    }
                    
                    ProductView(id: "JFITierOneTip")
                        .productViewStyle(.compact)
                        .tint(.accentColor)
                }
                
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text("Big Tip")
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                            .font(.title3)
                        Text("For my biggest fans :D")
                            .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
                            .font(.caption)
                    }
                    
                    ProductView(id: "JFITierTwoTip")
                        .productViewStyle(.compact)
                        .tint(.accentColor)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct SubscribePage: View {
    @EnvironmentObject private var itemController: ItemController
    
    @State private var showingWhatsIncluded: Bool = false
    
    @Binding var currentOffering: Offering?
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color("\(itemController.selectedTheme.rawValue)Background")
                .ignoresSafeArea(.all)
            
            VStack {
                if let currentOffering = currentOffering {
                    VStack(alignment: .center) {
                        VStack(alignment: .leading) {
                            Text("Premium Subscription")
                                .font(.largeTitle)
                                .padding(.bottom)
                            
                            Text("Unlock everything Just Flip It has to offer for a small monthly fee and support an indie developer.")
                                .font(.headline)
                        }
                        .padding(.bottom)
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "photo")
                                Text("Attach images to items")
                            }
                            .padding(.bottom)
                            
                            HStack {
                                Image(systemName: "mappin.circle")
                                Text("Store item locations")
                            }
                            .padding(.bottom)
                            
                            HStack {
                                Image(systemName: "chart.bar.xaxis")
                                Text("See detailed stats")
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
                    
                    ForEach(currentOffering.availablePackages) { package in
                        Button {
                            Purchases.shared.purchase(package: package) { (transaction, customerInfo, error, userCancelled) in
                                if customerInfo?.entitlements["Pro"]?.isActive == true {
                                    log.info("Premium purchased. Setting hasPremium to true.")
                                    itemController.hasPremium = true
                                    self.isPresented = false
                              }
                            }
                        } label: {
                            ZStack {
                                Rectangle()
                                    .frame(height: 50)
                                    .foregroundStyle(Color.accentColor)
                                    .cornerRadius(12)
                                
                                Text("Monthly: \(package.storeProduct.localizedPriceString)")
                                    .foregroundStyle(.white)
                            }
                            .padding(.bottom)
                        }
                    }
                    
                    Button {
                        Purchases.shared.restorePurchases { customerInfo, error in
                            
                            if customerInfo?.entitlements.all["Pro"]?.isActive == true {
                                log.info("Restoring premium access to user.")
                                itemController.hasPremium = true
                                self.isPresented = false
                            }
                        }
                    } label: {
                        Text("Restore Purchases")
                    }
                    
                    Spacer()
                    
                    Text("Take your flipping potential to the next level for less than a cup of coffee. Cancel anytime.")
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
        
//        ZStack {
//            Color("\(itemController.selectedTheme.rawValue)Background")
//                .ignoresSafeArea(.all)
//            
//            VStack {
//                Text("✨ Premium ✨")
//                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
//                    .font(.title2)
//                    .padding(.top)
//                Text("Thank you for supporting me ❤️")
//                    .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
//                    .font(.headline)
//                    .padding(.bottom)
//                
//                SubscriptionStoreView(productIDs: ["justflipit.subscription.general"])
//                    .storeButton(.visible, for: .restorePurchases, .redeemCode)
//                    .subscriptionStoreButtonLabel(.price)
//                    .tint(.accentColor)
//                
//                VStack(alignment: .leading) {
//                    if showingWhatsIncluded {
//                        VStack(alignment: .center) {
//                            Text("⭐️ Attach images to items ⭐️")
//                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
//                            Text("⭐️ Store item locations ⭐️")
//                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
//                            Text("⭐️ See detailed stats ⭐️")
//                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
//                            Text("⭐️ Try out new themes ⭐️")
//                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
//                        }
//                        .font(.headline)
//                        .foregroundStyle(.cyan)
//                        .transition(.move(edge: .bottom))
//                    } else {
//                        Button(action: {
//                            withAnimation {
//                                self.showingWhatsIncluded = true
//                            }
//                        }, label: {
//                            Text("What's Included?")
//                                .foregroundStyle(Color("\(itemController.selectedTheme.rawValue)Text"))
//                                .font(.title3)
//                        })
//                    }
//                }
//            }
//            .padding()
//        }
    }
}

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

enum ColorTheme: String, CaseIterable, Equatable {
    case standard
    case minty
    case lavender
    case sunrise
    case stonks
    case monochrome
    case pastel
}
