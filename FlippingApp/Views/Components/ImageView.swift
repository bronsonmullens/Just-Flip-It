//
//  ImageView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 7/27/24.
//

import SwiftUI

struct ImageView: View {
    @EnvironmentObject private var itemController: ItemController
    
    @GestureState private var zoom = 1.0
    
    @Binding var isPresented: Bool
    @Binding var imageData: Data?
    
    var body: some View {
        ZStack {
            Color("\(itemController.selectedTheme.rawValue)Background")
                .ignoresSafeArea(.all)
            
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(zoom)
                    .gesture(
                        MagnifyGesture()
                            .updating($zoom) { value, gestureState, transaction in
                                gestureState = value.magnification
                            }
                    )
            } else {
                HStack {
                    Image(systemName: "camera.metering.unknown")
                    Text("Image missing")
                }
            }
            
            VStack {
                Spacer()
                
                Button {
                    self.isPresented.toggle()
                } label: {
                    Text("Dismiss")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}
