//
//  ContentView.swift
//  OCR Playground
//
//  Created by Edward Banner on 7/8/25.
//

import SwiftUI
import Vision

struct ContentView: View {
    @State private var recognizedText = ""
    
    var body: some View {
        VStack() {
            Text("Bounding Box Demo")
                .font(.title)
            
            ZStack {
                Image("Al Bhed")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(
                        GeometryReader { geometry in
                            Rectangle()
                                .path(in: CGRect(
                                    x: 0.37778348771915893 * geometry.size.width,
                                    y: (1-0.07265425895500921 - 0.037747698360019344) * geometry.size.height,
                                    width: 0.08801600933074949 * geometry.size.width,
                                    height: 0.037747698360019344 * geometry.size.height))
                                .stroke(Color.red, lineWidth: 2.0)
                        }
                    )
            }

        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
