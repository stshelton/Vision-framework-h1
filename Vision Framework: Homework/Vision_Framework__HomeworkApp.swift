//
//  Vision_Framework__HomeworkApp.swift
//  Vision Framework: Homework
//
//  Created by Spencer Shelton on 10/21/25.
//

import SwiftUI
import PhotosUI

@main
struct Vision_Framework__HomeworkApp: App {
    @StateObject var photoPickerViewModel: PhotoPickerViewModel = PhotoPickerViewModel()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    FacesView(viewModel: .init(photoPickerViewModel: photoPickerViewModel))
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                PhotosPicker(
                                    selection: $photoPickerViewModel.imageSelection,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .imageScale(.large)
                                }
                            }
                        }
                }
                .tabItem {
                    Label("Faces", systemImage: "face.smiling")
                }
                .tag(0)

                NavigationStack {
                    TranslationView()
                }
                .tabItem {
                    Label("Translation", systemImage: "character.book.closed")
                }
                .tag(1)
                
                NavigationStack {
                    PetDetectionView()
                }
                .tabItem {
                    Label("Pet Detection", systemImage: "pawprint")
                }
                .tag(2)
            }
        }
    }
}
