//
//  PetDetectionViewModel.swift
//  Vision Framework: Homework
//
//  Created by Spencer Shelton on 11/12/25.
//

import SwiftUI
import UIKit
import Combine

@MainActor
final class PetDetectionViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var detectedPet: String?
    @Published var confidenceDescription: String?
    @Published var errorMessage: String?
    @Published var isClassifying: Bool = false

    private let classifier = PetClassifierService()

    func classifyImage() {
        guard let image else { return }
        guard !isClassifying else { return }

        isClassifying = true
        errorMessage = nil

        Task {
            let preparedImage = image.resizedForClassification() ?? image

            do {
                let prediction = try await classifier.classify(image: preparedImage)
                detectedPet = prediction.identifier.capitalized
                confidenceDescription = String(format: "%.1f%%", prediction.confidence * 100)
            } catch {
                errorMessage = error.localizedDescription
            }

            isClassifying = false
        }
    }

    func reset() {
        image = nil
        detectedPet = nil
        confidenceDescription = nil
        errorMessage = nil
        isClassifying = false
    }

    func prepareForNewSelection() {
        detectedPet = nil
        confidenceDescription = nil
        errorMessage = nil
        isClassifying = false
    }
}

private extension UIImage {
    func resizedForClassification(targetSize: CGFloat = 224) -> UIImage? {
        let newSize = CGSize(width: targetSize, height: targetSize)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

