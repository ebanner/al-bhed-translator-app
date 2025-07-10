//
//  ContentView.swift
//  Camera Text Detection
//
//  Created by Edward Banner on 7/10/25.
//

import SwiftUI
import UIKit
import AVFoundation

struct ContentView: View {
    var body: some View {
        ZStack {
            CameraView()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Text("Eddie's OCR Demo")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}

struct CameraView: UIViewRepresentable {
    func makeUIView(context: Context) -> CameraPreview {
        return CameraPreview()
    }

    func updateUIView(_ uiView: CameraPreview, context: Context) {
        // nothing to update for now
    }
}

class CameraPreview: UIView {
    private let session = AVCaptureSession()

    private var previewLayer: AVCaptureVideoPreviewLayer!

    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeCamera()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeCamera()
    }

    private func initializeCamera() {
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            return
        }

        session.addInput(input)

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)

        session.startRunning()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}
