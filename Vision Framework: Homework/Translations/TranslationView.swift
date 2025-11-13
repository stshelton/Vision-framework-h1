//
//  TranslationView.swift
//  Vision Framework: Homework
//
//  Created by Spencer Shelton on 11/3/25.
//

import SwiftUI
import Translation

struct TranslationView: View {
    @StateObject private var viewModel = TranslationViewModel()
    @StateObject private var batchViewModel = BatchTranslationViewModel()
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Translation Mode", selection: $viewModel.mode) {
                    ForEach(TranslationMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Translation mode picker")
                
                switch viewModel.mode {
                case .single:
                    singleTranslationInputs
                case .batch:
                    BatchTranslationList(viewModel: batchViewModel)
                }
                
                if viewModel.mode == .single, let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(Color.red)
                        .font(.footnote)
                        .accessibilityIdentifier("translationErrorLabel")
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Translation")
            
            if viewModel.mode == .single, viewModel.isOverlayPresented {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 16) {
                    Text("Translation")
                        .font(.title2)
                        .bold()
                    
                    Text(viewModel.overlayText)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button("Done") {
                        viewModel.dismissOverlay()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 10)
                )
                .padding(32)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: viewModel.isOverlayPresented)
        .onChange(of: viewModel.isOverlayPresented) { _, newValue in
            if newValue {
                isTextFieldFocused = false
            }
        }
        .onChange(of: viewModel.mode) { _, newMode in
            if newMode == .batch {
                isTextFieldFocused = false
                viewModel.cancelTranslationPresentation()
                if viewModel.isOverlayPresented {
                    viewModel.dismissOverlay()
                }
            }
        }
        .translationPresentation(isPresented: $viewModel.isTranslationOverlayPresented, text: viewModel.inputText) { translatedText in
            viewModel.applyTranslatedText(translatedText)
        }
    }
    
    private func handleTranslate() {
        viewModel.beginTranslation()
        isTextFieldFocused = false
    }
}

private extension TranslationView {
    @ViewBuilder
    var singleTranslationInputs: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enter a phrase to translate")
                .font(.headline)
            
            TextField("Type something...", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .padding(.top, 4)
            
            Button(action: handleTranslate) {
                Text("Translate")
                    .frame(maxWidth: .infinity)
            }
            .accessibilityLabel("Translate button")
            .accessibilityHint("Translates the text")
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isTranslationOverlayPresented)
        }
    }
}

private struct BatchTranslationList: View {
    @ObservedObject var viewModel: BatchTranslationViewModel
    @State private var translationConfiguration: TranslationSession.Configuration?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Task List")
                .font(.headline)
            
            List {
                ForEach(viewModel.tasks) { task in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.originalText)
                        if let translated = task.translatedText {
                            Text(translated)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Language (BCP-47 code)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                TextField("e.g. es, fr, de", text: $viewModel.targetLanguageCode)
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
            }
            
            HStack {
                Button {
                    guard let configuration = viewModel.prepareTranslationConfiguration() else {
                        return
                    }
                    translationConfiguration?.invalidate()
                    translationConfiguration = nil
                    translationConfiguration = configuration
                } label: {
                    if viewModel.isTranslating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Translate Tasks")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isTranslating)
                
                Button("Reset") {
                    viewModel.resetTranslations()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isTranslating)
            }
        }
        .translationTask(translationConfiguration) { session in
            await viewModel.translateAllTasks(using: session)
            await MainActor.run {
                translationConfiguration?.invalidate()
                translationConfiguration = nil
            }
            
        }
    }
}

#Preview {
    NavigationStack {
        TranslationView()
    }
}

