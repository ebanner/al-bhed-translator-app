//
//  ContentView.swift
//  Al Bhed Translator App
//
//  Created by Edward Banner on 7/8/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            CameraView()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                Text("Translated Text Here")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .padding(.bottom, 100)
            }
        }
    }
}

#Preview {
    ContentView()
}
