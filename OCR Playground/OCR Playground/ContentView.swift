//
//  ContentView.swift
//  OCR Playground
//
//  Created by Edward Banner on 7/8/25.
//

import SwiftUI
import Vision

struct BoundingBoxOverlay: View {
    let boundingBoxes: [CGRect]
    let geometrySize: CGSize

    var body: some View {
        ZStack {
            ForEach(boundingBoxes, id: \.self) { box in
                Path { path in
                    let rect = CGRect(
                        x: box.minX * geometrySize.width,
                        y: (1 - box.minY - box.height) * geometrySize.height,
                        width: box.width * geometrySize.width,
                        height: box.height * geometrySize.height
                    )
                    path.addRect(rect)
                }
                .stroke(Color.red, lineWidth: 2.0)
            }
        }
    }
}

struct ContentView: View {
    @State private var recognizedText = ""
    
    @State private var boundingBoxes: [CGRect] = []
    
//    @State private var boundingBoxes = [
//        CGRect(
//            x: 0.37778348771915893,
//            y: 0.07265425895500921,
//            width: 0.08801600933074949,
//            height: 0.037747698360019344
//        ),
//        CGRect(
//            x: 0.4703125007582713,
//            y: 0.07499999999999996,
//            width: 0.16250000000000003,
//            height: 0.033333333333333326
//        )
//    ]

    
    var body: some View {
        VStack {
            Text("Eddie's OCR Demo")
                .font(.title)
            
            ZStack {
                Image("Al Bhed")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(
                        GeometryReader { geometry in
                            BoundingBoxOverlay(
                                boundingBoxes: boundingBoxes,
                                geometrySize: geometry.size
                            )
                        }
                    )
            }
            
            Button("Recognize") {
                recognizeText()
            }
            .buttonStyle(.borderedProminent)
            
            TextEditor(text: $recognizedText)
                .background(Color.gray)
//                .cornerRadius(8)
        }
        .preferredColorScheme(.light)
    }
    
    private func recognizeText() {
        // Get the CGImage on which to perform requests.
        guard let cgImage = UIImage(named: "Al Bhed")?.cgImage else { return }

        // Create a new image-request handler.
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest(completionHandler: handleTextRecognition)

        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
    }
    
    private func handleTextRecognition(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        
        observations.forEach { observation in
            print(observation.topCandidates(1))
        }
        
        //            print("observations", observations)
        
        let newBoundingBoxes: [CGRect] = observations.map { observation in
            guard let candidate = observation.topCandidates(1).first else { return .zero }
            print("startIndex", candidate.string.startIndex)
            print("endIndex", candidate.string.endIndex)
//            let endIndex = candidate.string.index(after: candidate.string.startIndex)
//            print("index + 1 =", endIndex)
            let n = 1  // or whatever number you want
            let endIndex = candidate.string.index(candidate.string.startIndex, offsetBy: n, limitedBy: candidate.string.endIndex) ?? candidate.string.endIndex
            let stringRange = candidate.string.startIndex..<endIndex
            let boxObservation = try? candidate.boundingBox(for: stringRange)
            let boundingBox = boxObservation?.boundingBox ?? .zero
            return boundingBox
        }
        
//        print("newBoundingBoxes", newBoundingBoxes)
        
        let recognizedStrings = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
        
        print("Type of recognizedStrings:", type(of: recognizedStrings))
        print("Recognized strings:", recognizedStrings.joined(separator: " "))
        
        //            processResults(recognizedStrings)
        
        DispatchQueue.main.async {
            recognizedText = recognizedStrings.joined(separator: " ")
            boundingBoxes = newBoundingBoxes
        }
    }
}

#Preview {
    ContentView()
}
