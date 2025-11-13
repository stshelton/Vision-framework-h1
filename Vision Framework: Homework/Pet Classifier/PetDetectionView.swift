//
//  PetDetectionView.swift
//  Vision Framework: Homework
//
//  Created by Spencer Shelton on 11/4/25.
//

import SwiftUI
import UIKit

struct PetDetectionView: View {
    @StateObject private var viewModel = PetDetectionViewModel()
    @State private var isShowingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showSourceTypeDialog = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PetImageDisplayView(
                    image: $viewModel.image,
                    showSourceTypeDialog: $showSourceTypeDialog
                )

                if let detectedPet = viewModel.detectedPet,
                   let confidence = viewModel.confidenceDescription {
                    PetDetectionResultView(pet: detectedPet, confidence: confidence)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                PetDetectionButtonsView(
                    image: $viewModel.image,
                    isClassifying: viewModel.isClassifying,
                    classifyAction: viewModel.classifyImage,
                    resetAction: viewModel.reset,
                    selectImageAction: { showSourceTypeDialog = true }
                )
            }
            .padding()
        }
        .navigationTitle("Pet Detection")
        .confirmationDialog("Select Image Source", isPresented: $showSourceTypeDialog) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Camera") {
                    sourceType = .camera
                    isShowingImagePicker = true
                }
            }

            Button("Photo Library") {
                sourceType = .photoLibrary
                isShowingImagePicker = true
            }

            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(image: $viewModel.image, sourceType: sourceType)
        }
        .onChange(of: viewModel.image) { _, newValue in
            if newValue != nil {
                viewModel.prepareForNewSelection()
            }
        }
    }
}

#Preview {
    NavigationStack {
        PetDetectionView()
    }
}

private struct PetImageDisplayView: View {
    @Binding var image: UIImage?
    @Binding var showSourceTypeDialog: Bool

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 10)
                    .overlay(alignment: .topTrailing) {
                        Button {
                            showSourceTypeDialog = true
                        } label: {
                            Label("Change Photo", systemImage: "photo.on.rectangle.angled")
                                .labelStyle(.iconOnly)
                                .padding(8)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .padding()
                    }
                    .onTapGesture {
                        showSourceTypeDialog = true
                    }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "pawprint.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .foregroundStyle(.secondary)

                    Text("Tap to select a photo of your pet.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 10)
                .onTapGesture {
                    showSourceTypeDialog = true
                }
            }
        }
        .animation(.easeInOut, value: image)
    }
}

private struct PetDetectionResultView: View {
    let pet: String
    let confidence: String

    var body: some View {
        VStack(spacing: 12) {
            Text("Detected Pet")
                .font(.headline)

            Text(pet)
                .font(.title2)
                .bold()

            Text("Confidence: \(confidence)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Detected pet is \(pet) with \(confidence) confidence")
    }
}

private struct PetDetectionButtonsView: View {
    @Binding var image: UIImage?
    let isClassifying: Bool
    let classifyAction: () -> Void
    let resetAction: () -> Void
    let selectImageAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if image != nil {
                Button {
                    classifyAction()
                } label: {
                    if isClassifying {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Detect Pet")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isClassifying)

                Button(role: .destructive) {
                    resetAction()
                } label: {
                    Text("Choose Another Image")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
            } else {
                Button {
                    selectImageAction()
                } label: {
                    Text("Select Image")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

private struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
