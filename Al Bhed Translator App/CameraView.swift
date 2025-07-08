//
//  CameraView.swift
//  Al Bhed Translator
//
//  Created by Edward Banner on 7/8/25.
//

import SwiftUI

struct CameraView: UIViewRepresentable {
    func makeUIView(context: Context) -> CameraPreview {
        return CameraPreview()
    }

    func updateUIView(_ uiView: CameraPreview, context: Context) {
        // nothing to update for now
    }
}
