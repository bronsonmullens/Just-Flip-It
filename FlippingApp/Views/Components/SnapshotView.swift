//
//  SnapshotView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 8/2/24.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

// TODO: Fix Later

struct SnapshotView: View {
    let item: Item
    let quantity: Int
    
    let appStoreURL: String = "https://apps.apple.com/us/app/just-flip-it/id1553668128"
    
    private var profitMade: Double {
        if let soldPrice = item.soldPrice {
            let platformFees = soldPrice * (item.platformFees ?? 0.0)
            let profit = (soldPrice - item.purchasePrice) - platformFees - (item.otherFees ?? 0.0)
            return profit * Double(quantity)
        } else {
            return 0.0
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("I just flipped! 🎉")
                .font(.title3)
                .foregroundStyle(Color("standardText"))
            
            Text(item.title)
                .font(.title2)
                .foregroundStyle(Color("standardText"))
            
            HStack {
                Text("and made")
                    .font(.title3)
                    .foregroundStyle(Color("standardText"))
                
                Text("\(profitMade.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
            
            HStack {
                Spacer()
                
                AppStoreQRCodeView(appStoreURL: appStoreURL)
            }
        }
        .padding()
        .background(
            Color("standardBackground")
        )
        .cornerRadius(10)
        .shadow(radius: 10)
        .frame(width: 300, height: 300)
    }
}

// MARK: - Helpers

extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

extension InventoryView {
    func generateAndShareSellCard(for item: Item, quantity: Int) {
        let profit = itemController.calculateProfitForItem(item, quantity: quantity)
        let sellCardView = SnapshotView(item: item, quantity: quantity)
        let image = sellCardView.snapshot()

        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityViewController, animated: true, completion: nil)
        }
    }
}

extension UIImage {
    static func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

struct AppStoreQRCodeView: View {
    let appStoreURL: String
    
    var body: some View {
        VStack {
            Image(uiImage: UIImage.generateQRCode(from: appStoreURL))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
            
            Text("Download the app")
                .font(.caption2)
        }
    }
}
