//
//  ContentView.swift
//  OCR Playground
//
//  Created by Edward Banner on 7/8/25.
//

import SwiftUI
import Vision
import CoreImage

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
    @State private var translatedText = ""
    
    @State private var boundingBoxes: [CGRect] = []
    
    @State private var croppedCharacterImage: UIImage? = nil
    @State private var croppedCharacterImages: [UIImage] = []
    
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
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(Array(croppedCharacterImages.enumerated()), id: \.offset) { idx, img in
                        Image(uiImage: img)
                            .resizable()
                            .frame(width: 10, height: 10)
                            .border(Color.blue)
                    }
                }
            }
            
//            // Render all cropped character images
//            HStack {
//                ForEach(Array(croppedCharacterImages.enumerated()), id: \.offset) { idx, img in
//                    Image(uiImage: img)
//                        .resizable()
//                        .frame(width: 50, height: 50)
//                        .border(Color.blue)
//                }
//            }
            
            Button("Recognize") {
                recognizeText()
            }
            .buttonStyle(.borderedProminent)
            
            TextEditor(text: $recognizedText)
                .background(Color.gray)
//                .cornerRadius(8)
            
            TextEditor(text: $translatedText)
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
        
        var newCropped: [CGImage] = []

        for box in newBoundingBoxes {
            let imageWidth = CGFloat(cgImage.width)
            let imageHeight = CGFloat(cgImage.height)

            let rectInPixels = CGRect(
                x: box.minX * imageWidth,
                y: (1 - box.minY - box.height) * imageHeight,
                width: box.width * imageWidth,
                height: box.height * imageHeight
            )

            if let cropped = cgImage.cropping(to: rectInPixels) {
                newCropped.append(cropped)
            }
        }
        
        let newCharacterImages: [UIImage] = newCropped.map { cropped in
            UIImage(cgImage: cropped)
        }
        
        var isPinkBitmap: [Bool] = []
        for cropped in newCropped {
            let averageColor = getAverageColor(cropped)
            var green: CGFloat = 0
            averageColor.getRed(nil, green: &green, blue: nil, alpha: nil)
            let isPink = green < 0.3
            isPinkBitmap.append(isPink)
//            if isPink {
//                print(text[index], "pink")
//            } else {
//                print(text[index], "white")
//            }
        }
        
//        print("newBoundingBoxes", newBoundingBoxes)
        
        let recognizedStrings = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
        
        let charMap: [Character: Character] = [
            "v": "f",
            "n": "r",
            "a": "e",
            "d": "t",
        ]
        
        let text = Array(recognizedStrings[0])
        
        print("text", text)
        
        let colonIdx = text.firstIndex(of: ":")
        
        let startLetters = colonIdx != nil
            ? text.index(colonIdx!, offsetBy: 2, limitedBy: text.endIndex) ?? text.endIndex
            : text.startIndex
        
        let startPink = colonIdx != nil
            ? text.index(colonIdx!, offsetBy: 1, limitedBy: text.endIndex) ?? text.endIndex
            : text.startIndex
        
        print("letters", text[startLetters...])
        print("isPinkBitmap", isPinkBitmap[startPink...])
        
        let lettersSlice = Array(text[startLetters...])
        let isPinkBitmapSlice = Array(isPinkBitmap[startPink...])
        
        var i = 0
        var translated: [Character] = []
        for letter in lettersSlice {
            if letter == " " {
                translated.append(letter)
                continue
            }
            
            if i >= isPinkBitmapSlice.count {
                translated.append(letter)
                continue
            }
            
            if !isPinkBitmapSlice[i] {
                translated.append(charMap[letter] ?? letter)
            } else {
                translated.append(letter)
            }
            
            i += 1
        }
        
        print("translated", translated)
        
        print("Type of recognizedStrings:", type(of: recognizedStrings))
        print("Recognized strings:", String(translated))
        
        //            processResults(recognizedStrings)
        
        DispatchQueue.main.async {
            recognizedText = recognizedStrings.joined(separator: " ")
            boundingBoxes = newBoundingBoxes
            croppedCharacterImages = newCharacterImages
            let prefix = String(text[..<startLetters])
            translatedText = prefix + String(translated)
        }
    }
    
    private func getAverageColor(_ cropped: CGImage) -> UIColor {
        let ciImage = CIImage(cgImage: cropped)
        let extent = ciImage.extent

        let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ciImage, kCIInputExtentKey: CIVector(cgRect: extent)])!
        let outputImage = filter.outputImage!

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext()
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        let averageColor = UIColor(red: CGFloat(bitmap[0]) / 255.0, green: CGFloat(bitmap[1]) / 255.0, blue: CGFloat(bitmap[2]) / 255.0, alpha: 1)
        
        return averageColor
    }
}

#Preview {
    ContentView()
}
