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
                .foregroundStyle(.gray)
            }
            .padding(.top)
            
            Form {
                Section {
                    Button(action: {
                        self.showingWhatsNewInfo.toggle()
                    }, label: {
                        Text("📢 What's New?")
                    })
                    
                    Button(action: {
                        self.openTwitterSupport()
                    }, label: {
                        Text("🐦 Social Media")
                    })
                    
                    Button(action: {
                        self.showingPrivacyPolicyPage.toggle()
                    }, label: {
                        Text("⚖️ Privacy Policy")
                    })
                }
                
                Section {
                    Button(action: {
                        self.showingSubscribePage.toggle()
                    }, label: {
                        Text("💸 Subscribe")
                    })
                    
                    Button(action: {
                        self.showingTipJarAlert.toggle()
                    }, label: {
                        Text("🫙 Tip Jar")
                    })
                    
                    Button(action: {
                        self.rateAppRequest()
                    }, label: {
                        Text("⭐️ Rate the App")
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
                    })
                }
                
                Section {
                    Button(action: {
                        self.itemTypeToDelete = .inventory
                        self.showingDeletionAlert.toggle()
                    }, label: {
                        Text("🗑️ Delete Inventory")
                    })
                    
                    Button(action: {
                        self.itemTypeToDelete = .soldItems
                        self.showingDeletionAlert.toggle()
                    }, label: {
                        Text("🗑️ Delete Sold Items")
                    })
                    
                    Button(action: {
                        self.itemTypeToDelete = .tags
                        self.showingDeletionAlert.toggle()
                    }, label: {
                        Text("🗑️ Delete Tags")
                    })
                    
                    Button(action: {
                        self.itemTypeToDelete = .everything
                        self.showingDeletionAlert.toggle()
                    }, label: {
                        Text("⚠️ Delete Everything")
                            .foregroundStyle(.red)
                    })
                }
            }
        }
        .sheet(isPresented: $showingWhatsNewInfo, content: {
            WhatsNewView()
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.hidden)
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
            SubscribePage()
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
    }
}

// MARK: - Supporting Sheet Views

struct WhatsNewView: View {
    var body: some View {
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

struct TipJarView: View {
    var body: some View {
        VStack {
            Text("🫙 Tip Jar 🫙")
                .font(.title2)
                .padding(.top)
            Text("Thank you for supporting me 🩶")
                .foregroundStyle(.gray)
                .font(.headline)
                .padding(.bottom)
            
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text("Small Tip")
                        .font(.title3)
                    Text("Still very appreciated :)")
                        .foregroundStyle(.gray)
                        .font(.caption)
                }
                
                ProductView(id: "JFITierOneTip")
                    .productViewStyle(.compact)
            }
            
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text("Big Tip")
                        .font(.title3)
                    Text("For my biggest fans :D")
                        .foregroundStyle(.gray)
                        .font(.caption)
                }
                
                ProductView(id: "JFITierTwoTip")
                    .productViewStyle(.compact)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct SubscribePage: View {
    @State private var showingWhatsIncluded: Bool = false
    
    var body: some View {
        VStack {
            Text("✨ Premium ✨")
                .font(.title2)
                .padding(.top)
            Text("Thank you for supporting me 🩶")
                .foregroundStyle(.gray)
                .font(.headline)
                .padding(.bottom)
            
            SubscriptionStoreView(productIDs: ["justflipit.subscription.general"])
                .storeButton(.visible, for: .restorePurchases, .redeemCode)
                .subscriptionStoreButtonLabel(.price)
            
            VStack(alignment: .leading) {
                if showingWhatsIncluded {
                    VStack(alignment: .center) {
                        Text("⭐️ Attach images to items ⭐️")
                        Text("⭐️ Store item locations ⭐️")
                        Text("⭐️ See detailed stats ⭐️")
                        Text("⭐️ Try out new themes ⭐️")
                    }
                    .font(.headline)
                    .foregroundStyle(.cyan)
                    .transition(.move(edge: .bottom))
                } else {
                    Button(action: {
                        withAnimation {
                            self.showingWhatsIncluded = true
                        }
                    }, label: {
                        Text("What's Included?")
                            .font(.title3)
                    })
                }
            }
        }
        .padding()
    }
}

struct PrivacyPolicyPage: View {
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("I do not collect or store your data.")
                    .font(.largeTitle)
                Text("Seriously.")
                    .font(.headline)
                    .foregroundStyle(.gray)
            }
            .padding(.bottom)
            
            VStack(alignment: .leading) {
                Text("For questions or comments please email me using the 'Email Feedback' feature in settings.\n")
                
                Text("All of your personal information, including item data, is initially stored locally on your device. For cloud backups, Just Flip It! uses Apple's CloudKit service which is entirely outside of my view and control. Item and tag data is automatically synced to their secure iCloud servers as you use the app.\n")
                
                Text("You can delete your data at any time by deleting individual items in your inventory and sold items view or by using the various deletion options found in settings.")
            }
            
            Spacer()
        }
        .padding()
    }
}
