//
//  PetClassifierService.swift
//  Vision Framework: Homework
//
//  Created by Spencer Shelton on 11/4/25.
//

import CoreML
import UIKit
import Vision

enum PetClassifierError: Error, LocalizedError {
    case invalidImage
    case noResults
    case modelMissing

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to create image for classification."
        case .noResults:
            return "The model did not return any predictions."
        case .modelMissing:
            return "Unable to locate the PetClassifier model in the app bundle."
        }
    }
}

struct PetClassifierPrediction {
    let identifier: String
    let confidence: Float
}

final class PetClassifierService {
    private let visionModel: VNCoreMLModel

    init() {
        do {
            visionModel = try PetClassifierService.makeVisionModel()
        } catch {
            fatalError("Failed to load PetClassifier model: \(error.localizedDescription)")
        }
    }

    private static func makeVisionModel() throws -> VNCoreMLModel {
        let bundle = Bundle.main
//        let candidateNames = [
////            "PetClassifier 1",
////            "PetClassifier1",
//            "PetClassifier"
//        ]

        
            if let compiledURL = bundle.url(forResource: "PetClassifier", withExtension: "mlmodelc") {
                let mlModel = try MLModel(contentsOf: compiledURL)
                return try VNCoreMLModel(for: mlModel)
            }
        

            if let modelURL = bundle.url(forResource:  "PetClassifier", withExtension: "mlmodel") {
                let compiledURL = try MLModel.compileModel(at: modelURL)
                let mlModel = try MLModel(contentsOf: compiledURL)
                return try VNCoreMLModel(for: mlModel)
            }
        

        throw PetClassifierError.modelMissing
    }

    func classify(image: UIImage) async throws -> PetClassifierPrediction {
        guard let ciImage = CIImage(image: image) else {
            throw PetClassifierError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard
                    let results = request.results as? [VNClassificationObservation],
                    let bestResult = results.max(by: { $0.confidence < $1.confidence })
                else {
                    continuation.resume(throwing: PetClassifierError.noResults)
                    return
                }

                continuation.resume(
                    returning: PetClassifierPrediction(
                        identifier: bestResult.identifier,
                        confidence: bestResult.confidence
                    )
                )
            }

            request.imageCropAndScaleOption = .centerCrop

            let orientation = CGImagePropertyOrientation(image.imageOrientation)
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}

