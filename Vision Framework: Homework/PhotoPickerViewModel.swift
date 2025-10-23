//
//  Photo.swift
//  Vision Framework: Homework
//
//  Created by Spencer Shelton on 10/21/25.
//
import SwiftUI
import PhotosUI
import Combine

struct Photo: Identifiable, Equatable {
  let id = UUID()
  let image: UIImage
}

@MainActor
class PhotoPickerViewModel: ObservableObject {
  @Published var selectedPhoto: Photo?
  @Published var imageSelection: PhotosPickerItem? {
    didSet {
      if let item = imageSelection {
        loadPhoto(from: item)
      }
    }
  }
  
  private func loadPhoto(from item: PhotosPickerItem) {
    item.loadTransferable(type: Data.self) { result in
      switch result {
      case .success(let data):
        if let data = data, let image = UIImage(data: data) {
          DispatchQueue.main.async {
            self.selectPhoto(image)
          }
        }
      case .failure(let error):
        print("Error loading photo: \(error.localizedDescription)")
      }
    }
  }
  
  func selectPhoto(_ photo: UIImage) {
    selectedPhoto = Photo(image: photo)
  }
}
