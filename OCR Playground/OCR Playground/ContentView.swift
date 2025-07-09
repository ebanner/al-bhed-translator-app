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
    
    @State private var croppedCharacterImage: UIImage? = nil
    
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
            
            if let img = croppedCharacterImage {
                Image(uiImage: img)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .border(Color.black)
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
        request.recognitionLevel = .fast
        
        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
    }
    
    private func handleTextRecognition(request: VNRequest, error: Error?) {
        guard let cgImage = UIImage(named: "Al Bhed")?.cgImage else { return }
        
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        
        observations.forEach { observation in
            print(observation.topCandidates(1))
        }
        
        //            print("observations", observations)
        
        var newBoundingBoxes: [CGRect] = []

        if let observation = observations.first,
           let candidate = observation.topCandidates(1).first {
            
            let count = candidate.string.count

            if count < 2 {
                newBoundingBoxes.append(.zero)
            } else {
                for i in 0..<(count - 1) {
                    let startIndex = candidate.string.index(candidate.string.startIndex, offsetBy: i, limitedBy: candidate.string.endIndex) ?? candidate.string.endIndex
                    let endIndex = candidate.string.index(candidate.string.startIndex, offsetBy: i + 1, limitedBy: candidate.string.endIndex) ?? candidate.string.endIndex

                    let stringRange = startIndex..<endIndex
                    let boxObservation = try? candidate.boundingBox(for: stringRange)
                    let boundingBox = boxObservation?.boundingBox ?? .zero
                    newBoundingBoxes.append(boundingBox)
                }
            }
        } else {
            newBoundingBoxes.append(.zero)
        }
        
        let box = newBoundingBoxes[0]
        
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        let rectInPixels = CGRect(
            x: box.minX * imageWidth,
            y: (1 - box.minY - box.height) * imageHeight,
            width: box.width * imageWidth,
            height: box.height * imageHeight
        )
        
        if let cropped = cgImage.cropping(to: rectInPixels) {
            let uiImage = UIImage(cgImage: cropped)
            DispatchQueue.main.async {
                croppedCharacterImage = uiImage
            }
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
