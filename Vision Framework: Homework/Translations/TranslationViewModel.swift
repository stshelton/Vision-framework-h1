//
//  TranslationViewModel.swift
//  Vision Framework: Homework
//
//  Created by Spencer Shelton on 11/4/25.
//

import Foundation
import SwiftUI
import Translation
import Combine

enum TranslationMode: String, CaseIterable, Identifiable {
    case single = "Translation"
    case batch = "Batch Translation"

    var id: String { rawValue }
}

@MainActor
class TranslationViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published private(set) var overlayText: String = ""
    @Published var isOverlayPresented: Bool = false
    @Published var errorMessage: String?
    @Published var isTranslationOverlayPresented: Bool = false
    @Published var mode: TranslationMode = .single

    func beginTranslation() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Enter text to translate."
            return
        }
        errorMessage = nil
        overlayText = ""
        isTranslationOverlayPresented = true
    }

    func applyTranslatedText(_ translatedText: String) {
        overlayText = translatedText
        inputText = translatedText
        isTranslationOverlayPresented = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isOverlayPresented = true
        }
    }

    func cancelTranslationPresentation() {
        isTranslationOverlayPresented = false
    }

    func dismissOverlay() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            isOverlayPresented = false
        }
    }
}

