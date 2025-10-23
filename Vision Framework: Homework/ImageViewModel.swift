//
//  ImageViewModel.swift
//  Vision Framework Homework
//
//  Created by Spencer Shelton on 10/21/25.
//


import SwiftUI
import Combine
import Vision
import OSLog

let logger = Logger() as Logger

enum FacialFeature: String, CaseIterable {
  case eyes = "Eyes"
  case mouth = "Mouth"
  case nose = "Nose"
  
  var icon: String {
    switch self {
    case .eyes: return "eye.fill"
    case .mouth: return "mouth.fill"
    case .nose: return "nose.fill"
    }
  }
  
  var availableStickers: [StickerIcon] {
    switch self {
    case .eyes:
      return [
        StickerIcon(name: "eye-narrowed", displayName: "Narrowed"),
        StickerIcon(name: "eye-pupil", displayName: "Pupil"),
        StickerIcon(name: "opened-eye", displayName: "Opened")
      ]
    case .mouth:
      return [
        StickerIcon(name: "lips", displayName: "Lips"),
        StickerIcon(name: "mouth", displayName: "Mouth"),
        StickerIcon(name: "smile", displayName: "Smile")
      ]
    case .nose:
      return [
        StickerIcon(name: "nose", displayName: "Nose"),
        StickerIcon(name: "dog-nose", displayName: "Dog Nose"),
        StickerIcon(name: "strip", displayName: "Strip")
      ]
    }
  }
}

struct StickerIcon: Identifiable, Equatable {
  var id: String { name }
  let name: String
  let displayName: String
}

struct FaceLandmarks {
  let leftEye: CGPoint?
  let rightEye: CGPoint?
  let nose: CGPoint?
  let mouth: CGPoint?
  let boundingBox: CGRect
}

class ImageViewModel: ObservableObject {
  @Published var faceRectangles: [CGRect] = []
  @Published var faceLandmarks: [FaceLandmarks] = []
  @Published var currentIndex: Int = 0
  @Published var errorMessage: String? = nil
  @Published var selectedFeature: FacialFeature = .eyes
  @Published var selectedSticker: StickerIcon?
  
  // Shared PhotoPickerViewModel
  @Published var photoPickerViewModel: PhotoPickerViewModel
  
  init(photoPickerViewModel: PhotoPickerViewModel) {
    self.photoPickerViewModel = photoPickerViewModel
  }
  
  @MainActor func detectFaces() {
    currentIndex = 0
    guard let image = photoPickerViewModel.selectedPhoto?.image else {
      DispatchQueue.main.async {
        self.errorMessage = "No image available"
      }
      return
    }
    
    guard let cgImage = image.cgImage else {
      DispatchQueue.main.async {
        self.errorMessage = "Failed to convert UIImage to CGImage"
      }
      return
    }
    
    // Use VNDetectFaceLandmarksRequest to detect facial landmarks
    let faceDetectionRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
      if let error = error {
        DispatchQueue.main.async {
          self?.errorMessage = "Face detection error: \(error.localizedDescription)"
        }
        return
      }
      
      guard let observations = request.results as? [VNFaceObservation] else {
        DispatchQueue.main.async {
          self?.errorMessage = "No face observations found"
        }
        return
      }
      
      // Extract landmarks from each face
      let landmarks: [FaceLandmarks] = observations.compactMap { observation in
        guard let landmarks = observation.landmarks else { return nil }
        
        // Get center points for each facial feature
        let leftEye = landmarks.leftEye?.normalizedPoints.centerPoint()
        let rightEye = landmarks.rightEye?.normalizedPoints.centerPoint()
        let nose = landmarks.nose?.normalizedPoints.centerPoint()
        let mouth = landmarks.outerLips?.normalizedPoints.centerPoint()
        
        // Convert points to image coordinates
        let leftEyePoint = leftEye.map { self?.convertToImageCoordinates($0, in: observation.boundingBox) } ?? nil
        let rightEyePoint = rightEye.map { self?.convertToImageCoordinates($0, in: observation.boundingBox) } ?? nil
        let nosePoint = nose.map { self?.convertToImageCoordinates($0, in: observation.boundingBox) } ?? nil
        let mouthPoint = mouth.map { self?.convertToImageCoordinates($0, in: observation.boundingBox) } ?? nil
        
        return FaceLandmarks(
          leftEye: leftEyePoint,
          rightEye: rightEyePoint,
          nose: nosePoint,
          mouth: mouthPoint,
          boundingBox: observation.boundingBox
        )
      }
      
      let rectangles: [CGRect] = observations.map { $0.boundingBox }
      
      DispatchQueue.main.async {
        self?.faceRectangles = rectangles
        self?.faceLandmarks = landmarks
        self?.errorMessage = rectangles.isEmpty ? "No faces detected" : nil
      }
    }
    
#if targetEnvironment(simulator)
    let supportedDevices = try! faceDetectionRequest.supportedComputeStageDevices
    if let mainStage = supportedDevices[.main] {
      if let cpuDevice = mainStage.first(where: { device in
        device.description.contains("CPU")
      }) {
        faceDetectionRequest.setComputeDevice(cpuDevice, for: .main)
      }
    }
#endif

    // Create handler without orientation - we'll handle orientation in the drawing phase
    // This ensures Vision coordinates match the raw cgImage coordinate system
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    
    do {
      try handler.perform([faceDetectionRequest])
    } catch {
      DispatchQueue.main.async {
        self.errorMessage = "Failed to perform detection: \(error.localizedDescription)"
      }
    }
  }
  
  // Helper to convert landmark points relative to face bounding box to normalized image coordinates
  private func convertToImageCoordinates(_ point: CGPoint, in boundingBox: CGRect) -> CGPoint {
    // Landmarks are normalized relative to the face bounding box (0-1 range)
    // Just add them to the bounding box origin, scaled by the box size
    return CGPoint(
      x: boundingBox.origin.x + point.x * boundingBox.width,
      y: boundingBox.origin.y + point.y * boundingBox.height
    )
  }

  
  var currentFace: CGRect? {
    guard !faceRectangles.isEmpty else { return nil }
    return faceRectangles[currentIndex]
  }
  
  func adjustOrientation(orient: UIImage.Orientation) -> UIImage.Orientation {
    switch orient {
    case .up: return .downMirrored
    case .upMirrored: return .up
      
    case .down: return .upMirrored
    case .downMirrored: return .down
      
    case .left: return .rightMirrored
    case .rightMirrored: return .left
      
    case .right: return .leftMirrored //check
    case .leftMirrored: return .right
      
    @unknown default: return orient
    }
  }
  
  func drawVisionRect(on image: UIImage?, visionRect: CGRect?) -> UIImage? {
    guard let image = image, let cgImage = image.cgImage else {
      return nil
    }
    guard let visionRect = visionRect else { return image }
    
    // Get image size and prepare the context
    let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
    
    UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
    
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    
    // Draw the original image
    context.draw(cgImage, in: CGRect(origin: .zero, size: imageSize))
    
    // Draw feature bounding boxes or stickers based on selection
    if currentIndex < faceLandmarks.count {
      let landmarks = faceLandmarks[currentIndex]
      
      if selectedSticker != nil {
        // If a sticker is selected, draw the sticker covering the feature
        drawStickersOnLandmarks(landmarks, in: context, imageSize: imageSize)
      } else {
        // If no sticker selected, draw boxes around the selected feature
        drawFeatureBoundingBoxes(landmarks, in: context, imageSize: imageSize)
      }
    }
    
    // Get the resulting UIImage
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    
    logger.debug("original orientation is \(image.imageOrientation.rawValue)")
    // End image context
    UIGraphicsEndImageContext()
      let correctlyOrientedImage = UIImage(cgImage: newImage!.cgImage!, scale: image.scale, orientation: adjustOrientation(orient: newImage?.imageOrientation ?? image.imageOrientation))
    
    logger.debug("final orientation \(correctlyOrientedImage.imageOrientation.rawValue)")
    
    return correctlyOrientedImage
  }
  
  private func drawFeatureBoundingBoxes(_ landmarks: FaceLandmarks, in context: CGContext, imageSize: CGSize) {
    // Determine which landmark to highlight based on selected feature
    var landmarkPoints: [CGPoint] = []
    var boxSize: CGFloat = 80
    
    switch selectedFeature {
    case .eyes:
      if let leftEye = landmarks.leftEye {
        landmarkPoints.append(leftEye)
      }
      if let rightEye = landmarks.rightEye {
        landmarkPoints.append(rightEye)
      }
      boxSize = 60
    case .nose:
      if let nose = landmarks.nose {
        landmarkPoints.append(nose)
      }
      boxSize = 70
    case .mouth:
      if let mouth = landmarks.mouth {
        landmarkPoints.append(mouth)
      }
      boxSize = 90
    }
    
    // Draw box around each landmark point
    for point in landmarkPoints {
      // Landmarks are already in normalized coordinates (0-1 range)
      // VNImagePointForNormalizedPoint converts from Vision coordinates (bottom-left origin) to image coordinates (top-left origin)
      let imagePoint = VNImagePointForNormalizedPoint(
        point,
        Int(imageSize.width),
        Int(imageSize.height)
      )
      
      // Create rect centered on the landmark point
      let featureRect = CGRect(
        x: imagePoint.x - boxSize / 2,
        y: imagePoint.y - boxSize / 2,
        width: boxSize,
        height: boxSize
      )
      
      // Draw the bounding box
      context.saveGState()
      UIColor.systemBlue.withAlphaComponent(0.3).setFill()
      let rectPath = UIBezierPath(roundedRect: featureRect, cornerRadius: 8)
      rectPath.fill()
      
      UIColor.systemBlue.setStroke()
      rectPath.lineWidth = 3.0
      rectPath.stroke()
      context.restoreGState()
    }
  }
  
  private func drawStickersOnLandmarks(_ landmarks: FaceLandmarks, in context: CGContext, imageSize: CGSize) {
    guard let selectedSticker = selectedSticker else { return }
    
    // Get the sticker image
    guard let stickerImage = UIImage(named: selectedSticker.name) else {
      logger.warning("Sticker image not found: \(selectedSticker.name)")
      return
    }
    
    // Determine which landmark to use based on selected feature
    var landmarkPoints: [CGPoint] = []
    var stickerSize: CGFloat = 80
    
    switch selectedFeature {
    case .eyes:
      if let leftEye = landmarks.leftEye {
        landmarkPoints.append(leftEye)
      }
      if let rightEye = landmarks.rightEye {
        landmarkPoints.append(rightEye)
      }
      stickerSize = 60
    case .nose:
      if let nose = landmarks.nose {
        landmarkPoints.append(nose)
      }
      stickerSize = 70
    case .mouth:
      if let mouth = landmarks.mouth {
        landmarkPoints.append(mouth)
      }
      stickerSize = 90
    }
    
    // Draw sticker at each landmark point
    for point in landmarkPoints {
      // Landmarks are already in normalized coordinates (0-1 range)
      // VNImagePointForNormalizedPoint converts from Vision coordinates (bottom-left origin) to image coordinates (top-left origin)
      let imagePoint = VNImagePointForNormalizedPoint(
        point,
        Int(imageSize.width),
        Int(imageSize.height)
      )
      
      // Create rect centered on the landmark point
      let stickerRect = CGRect(
        x: imagePoint.x - stickerSize / 2,
        y: imagePoint.y - stickerSize / 2,
        width: stickerSize,
        height: stickerSize
      )
      
      // Draw the sticker
      context.saveGState()
      if let cgSticker = stickerImage.cgImage {
        context.draw(cgSticker, in: stickerRect)
      }
      context.restoreGState()
    }
  }
}

// Extension to calculate center point of an array of CGPoints
extension Array where Element == CGPoint {
  func centerPoint() -> CGPoint? {
    guard !isEmpty else { return nil }
    let sumX = reduce(0) { $0 + $1.x }
    let sumY = reduce(0) { $0 + $1.y }
    return CGPoint(x: sumX / CGFloat(count), y: sumY / CGFloat(count))
  }
}
