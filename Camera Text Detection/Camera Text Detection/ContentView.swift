//
//  ContentView.swift
//  Camera Text Detection
//
//  Created by Edward Banner on 7/10/25.
//

import SwiftUI
import UIKit
import AVFoundation
import Vision

struct ContentView: View {
    let bbox = CGRect(x: 0.3, y: 0.2, width: 0.4, height: 0.3)
    
    var body: some View {
        ZStack {
            CameraView()
                .edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                // Convert normalized bbox to absolute frame
                let rect = CGRect(
                    x: bbox.origin.x * geometry.size.width,
                    y: bbox.origin.y * geometry.size.height,
                    width: bbox.size.width * geometry.size.width,
                    height: bbox.size.height * geometry.size.height
                )
                
                Rectangle()
                    .stroke(Color.red, lineWidth: 3)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
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

class CameraPreview: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var isProcessingFrame = false

    lazy var textRequest = VNRecognizeTextRequest { request, error in
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        for observation in observations {
            if let candidate = observation.topCandidates(1).first {
                print("Recognized text: \(candidate.string)")
            }
        }
    }

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
              session.canAddInput(input) else {
            return
        }

        session.addInput(input)

        // Add preview
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)

        // Add video data output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
        session.addOutput(videoOutput)

        session.startRunning()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard !isProcessingFrame else { return }
        isProcessingFrame = true

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessingFrame = false
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.recognizeText(in: pixelBuffer)
            self?.isProcessingFrame = false
        }
    }

    private func recognizeText(in pixelBuffer: CVPixelBuffer) {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try requestHandler.perform([textRequest])
        } catch {
            print("Vision error: \(error)")
        }
    }
}
