//
//  LoadingView.swift
//  QuoteVault
//
//  Loading indicator component
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading quotes...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    LoadingView()
}
