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
        }
    }
}
