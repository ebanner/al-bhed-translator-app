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
import Combine

struct ContentView: View {
    @State private var recognizedText: String = ""
    @State private var boundingBoxes: [CGRect] = []

    var body: some View {
        ZStack {
            CameraView(recognizedText: $recognizedText, boundingBoxes: $boundingBoxes)
                .edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                ForEach(boundingBoxes.indices, id: \.self) { i in
                    let bbox = boundingBoxes[i]
                    let rect = bbox

                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
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
    @Binding var boundingBoxes: [CGRect]

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> CameraPreview {
        let view = CameraPreview(recognizedText: $recognizedText)
        view.$boundingBoxes
            .receive(on: DispatchQueue.main)
            .sink { boxes in
                context.coordinator.boundingBoxes = boxes
                boundingBoxes = boxes
            }
            .store(in: &context.coordinator.cancellables)
        return view
    }

    func updateUIView(_ uiView: CameraPreview, context: Context) {
        // nothing to update
    }

    class Coordinator {
        var boundingBoxes: [CGRect] = []
        var cancellables = Set<AnyCancellable>()
    }
}

class CameraPreview: UIView, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    @Published var boundingBoxes: [CGRect] = []
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
            guard let self = self else { return }
            self.recognizedTextBinding.wrappedValue = recognizedStrings.joined(separator: "\n")
            let convertedBoxes = observations.map { self.previewLayer.layerRectConverted(fromMetadataOutputRect: $0.boundingBox) }
            self.boundingBoxes = convertedBoxes
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
