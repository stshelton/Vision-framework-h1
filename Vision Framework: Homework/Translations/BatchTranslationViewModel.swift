//
//  BatchTranslationViewModel.swift
//  Vision Framework: Homework
//
//  Created by Spencer Shelton on 11/11/25.
//

import Foundation
import Translation
import SwiftUI
import Combine

@MainActor
class BatchTranslationViewModel: ObservableObject {
    struct TaskItem: Identifiable, Hashable {
        let id: UUID
        let originalText: String
        var translatedText: String?

        init(id: UUID = UUID(), originalText: String, translatedText: String? = nil) {
            self.id = id
            self.originalText = originalText
            self.translatedText = translatedText
        }
    }

    @Published var tasks: [TaskItem]
    @Published var isTranslating: Bool = false
    @Published var errorMessage: String?
    @Published var targetLanguageCode: String

    init(initialTasks: [String] = [
        "Review project requirements",
        "Prototype the new UI",
        "Write unit tests",
        "Update documentation",
        "Submit the pull request"
    ],
         targetLanguageCode: String = "es") {
        self.tasks = initialTasks.map { TaskItem(originalText: $0) }
        self.targetLanguageCode = targetLanguageCode
    }

    func prepareTranslationConfiguration() -> TranslationSession.Configuration? {
        guard !isTranslating else { return nil }

        let trimmedTarget = targetLanguageCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTarget.isEmpty else {
            errorMessage = "Enter a language code."
            return nil
        }

        errorMessage = nil
        isTranslating = true
        return TranslationSession.Configuration(
            source: nil,
            target: Locale.Language(identifier: trimmedTarget)
        )
    }

    func translateAllTasks(using session: TranslationSession) async {
        do {
            var updatedItems: [TaskItem] = []

            for item in tasks {
                let response = try await session.translate(item.originalText)
                updatedItems.append(
                    TaskItem(
                        id: item.id,
                        originalText: item.originalText,
                        translatedText: response.targetText
                    )
                )
            }

            tasks = updatedItems
            isTranslating = false

        } catch {
            errorMessage = "Failed to translate tasks. \(error.localizedDescription)"
            isTranslating = false
        }
    }

    func resetTranslations() {
        for index in tasks.indices {
            tasks[index].translatedText = nil
        }
        errorMessage = nil
        isTranslating = false
    }
}
