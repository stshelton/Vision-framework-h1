//
//  ContentView.swift
//  Vision Framework: Homework
//
//  Created by Spencer Shelton on 10/21/25.
//

import SwiftUI
import PhotosUI

struct FacesView: View {
  @StateObject var viewModel: ImageViewModel
 
  
  var body: some View {
    VStack {
      if let originalImage = viewModel.photoPickerViewModel.selectedPhoto?.image,
         let processedImage = viewModel.drawVisionRect(on: originalImage, visionRect: viewModel.currentFace) {
        Image(uiImage: processedImage)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .id("\(viewModel.selectedFeature.rawValue)-\(viewModel.selectedSticker?.id ?? "none")")
        
        // Feature selection scroll view
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 16) {
            ForEach(FacialFeature.allCases, id: \.self) { feature in
              FeatureCard(
                feature: feature,
                isSelected: viewModel.selectedFeature == feature
              )
              .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.selectedFeature = feature
                    viewModel.selectedSticker = nil // Reset sticker selection when feature changes
                }
              }
            }
          }
          .padding(.horizontal)
        }
        .padding(.vertical, 8)
        
        // Sticker icon selection scroll view
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            ForEach(viewModel.selectedFeature.availableStickers) { sticker in
              StickerCard(
                sticker: sticker,
                isSelected: viewModel.selectedSticker?.id == sticker.id
              )
              .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.selectedSticker = sticker
                }
              }
            }
          }
          .padding(.horizontal)
        }
        .padding(.vertical, 8)
        
        if let errorMessage = viewModel.errorMessage {
          Text(errorMessage)
            .foregroundColor(.red)
            .padding()
        }
      } else {
        Text("No image available")
      }
    }
    .onChange(of: viewModel.photoPickerViewModel.selectedPhoto, { oldValue, newValue in
        if oldValue != newValue {
            Task {
                viewModel.detectFaces()
            }
        }
    })
   
    .padding()
  }
}

struct FeatureCard: View {
  let feature: FacialFeature
  let isSelected: Bool
  
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: feature.icon)
        .font(.system(size: 32))
        .foregroundColor(isSelected ? .white : .primary)
      
      Text(feature.rawValue)
        .font(.caption)
        .fontWeight(isSelected ? .semibold : .regular)
        .foregroundColor(isSelected ? .white : .primary)
    }
    .frame(width: 70, height: 70)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(isSelected ? Color.accentColor : Color(.systemGray6))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
    )
    .scaleEffect(isSelected ? 1.05 : 1.0)
    .padding(6)
  }
}

struct StickerCard: View {
  let sticker: StickerIcon
  let isSelected: Bool
  
  var body: some View {
    VStack(spacing: 6) {
      // Display the sticker icon image
      Image(sticker.name)
        .resizable()
        .scaledToFit()
        .frame(width: 40, height: 40)
      
      Text(sticker.displayName)
        .font(.caption2)
        .fontWeight(isSelected ? .semibold : .regular)
        .foregroundColor(isSelected ? .white : .primary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .frame(width: 60, height: 65)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(isSelected ? Color.accentColor : Color(.systemGray6))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
    )
    .scaleEffect(isSelected ? 1.05 : 1.0)
    .padding(4)
  }
}

//#Preview {
//    FaceView()
//}
