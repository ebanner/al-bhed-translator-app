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
    @State private var recognizedText: String = ""

    let bbox = CGRect(x: 0.3, y: 0.2, width: 0.4, height: 0.3)
    
    var body: some View {
        ZStack {
            CameraView(recognizedText: $recognizedText)
                .edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
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
                
                ScrollView {
                    Text(recognizedText)
                        .foregroundColor(.yellow)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                }
                .frame(maxHeight: 200)

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
    @Binding var recognizedText: String

    func makeUIView(context: Context) -> CameraPreview {
        return CameraPreview(recognizedText: $recognizedText)
    }

    func updateUIView(_ uiView: CameraPreview, context: Context) {
        // nothing to update
    }
}

class CameraPreview: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var isProcessingFrame = false
    private var recognizedTextBinding: Binding<String>

    init(recognizedText: Binding<String>) {
        self.recognizedTextBinding = recognizedText
        super.init(frame: .zero)
        initializeCamera()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var textRequest = VNRecognizeTextRequest { [weak self] request, error in
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
        DispatchQueue.main.async {
            self?.recognizedTextBinding.wrappedValue = recognizedStrings.joined(separator: "\n")
        }
    }

    private func initializeCamera() {
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return
        }

        session.addInput(input)

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)

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
