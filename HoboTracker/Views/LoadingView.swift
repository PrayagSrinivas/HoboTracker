//
//  LoadingView.swift
//  HoboTracker
//
//  Created by Srinivas Prayag Sahu on 14/03/26.
//

import SwiftUI

struct LoadingView: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Loading HUD
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.85))
            )
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        }
        .animation(.easeInOut(duration: 0.2), value: message)
    }
}

// Custom ViewModifier for showing loading
struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    let message: String?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isLoading {
                LoadingView(message: message)
                    .transition(.opacity)
            }
        }
    }
}

// Extension for easy use
extension View {
    func loading(isLoading: Bool, message: String? = nil) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading, message: message))
    }
}

#Preview {
    VStack {
        Text("Content behind loader")
    }
    .loading(isLoading: true, message: "Syncing habits...")
}
