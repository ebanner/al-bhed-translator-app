//
//  CameraPreview.swift
//  Al Bhed Translator
//
//  Created by Edward Banner on 7/8/25.
//

import UIKit
import AVFoundation

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
