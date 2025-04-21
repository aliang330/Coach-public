//
//  LibraryViewModel.swift
//  Coach
//
//  Created by Allen Liang on 1/20/25.
//

import Foundation
import SwiftUI
import PhotosUI
import Combine

class LibraryViewModel: NSObject, ObservableObject {
    @Published var loadingCount = 0
    @Published var currentVideoProgress = 0
    @Published var localVideos: [LocalVideoDTO] = []
    
    @Published var importSelection: PhotosPickerItem? {
        didSet {
            if let importSelection {
                loadTransferable(from: importSelection)
            }
        }
    }
    
    @Published var golfImportSelection: PhotosPickerItem? {
        didSet {
            if let golfImportSelection {
                golfLoadTransferable(from: golfImportSelection)
            }
        }
    }
    
    var localVideoService: LocalVideoServiceProtocol
    var localVideoSub: AnyCancellable?
    var bodyPoseDetector: BodyPoseDetectorProtocol
    var golfSwingDetector: GolfSwingDetector
    
    private let logger: LoggerProvider
    
    init(localVideoService: LocalVideoServiceProtocol, bodyPoseDetector: BodyPoseDetectorProtocol, golfSwingDetector: GolfSwingDetector, logger: LoggerProvider?) {
        self.localVideoService = localVideoService
        self.bodyPoseDetector = bodyPoseDetector
        self.golfSwingDetector = golfSwingDetector
        self.logger = logger ?? OSLogProvider(category: "LibraryViewModel")
        super.init()
        fetchLocalVideos()
    }
    
    func fetchLocalVideos() {
        localVideoSub = localVideoService.getLocalVideoPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] localVideos in
                guard let self = self else { return }
                self.localVideos = localVideos
            })
    }
    
    func deleteLocalVideo(_ localVideo: LocalVideoDTO) {
        do {
            try localVideoService.deleteLocalVideo(localVideo)
        } catch {
            logger.error("delete local video failed: \(error) - \(error.localizedDescription)")
        }
        
    }
    
    // BETA
    private func golfLoadTransferable(from selection: PhotosPickerItem) {
        UIApplication.shared.isIdleTimerDisabled = true
        print("estimate: \(getTransferTimeEstimateInSeconds(from: selection))")
        
        loadingCount += 1
        let estimate = getTransferTimeEstimateInSeconds(from: selection) ?? 1
        let startTime = Date()
        importProgressTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            let elasped = Date().timeIntervalSince(startTime)
            DispatchQueue.main.async {
                self.currentVideoProgress = Int(elasped / Double(estimate) * 100)
            }
        })
        
        Task {
            do {
                let importStart = Date()
                guard let video = try await selection.loadTransferable(type: Video.self) else {
                    print("video is nil")
                    return
                }
                importProgressTimer?.invalidate()
                importProgressTimer = nil
                
                print("import time: \(Date().timeIntervalSince(importStart))")
                
                let videoURL = URL.videoURL(videoPath: video.path)
                
                async let metaDataTask = getVideoMetaData(url: videoURL)
                async let bodyPoseFramesTask = getBodyPoseFrames(url: videoURL)
                
                let (assetMetaData, bodyframes) = try await (metaDataTask, bodyPoseFramesTask)
                
                let savedLocalVideo = try localVideoService.saveLocalVideo(path: video.path, duration: assetMetaData.duration, dateAdded: Date(), thumbnailData: assetMetaData.thumbnailData, frameRate: assetMetaData.frameRate, bodyposeFrames: bodyframes)
                
                DispatchQueue.main.async {
                    self.currentVideoProgress = 0
                    self.loadingCount -= 1
                }
                
                detectGolfSwingSaveNewVideo(localVideo: savedLocalVideo)
                
                DispatchQueue.main.async {
                    self.golfImportSelection = nil
                    UIApplication.shared.isIdleTimerDisabled = false
                }
                
            } catch {
                UIApplication.shared.isIdleTimerDisabled = false
                print(error)
            }
        }
    }
    
    func bytesToMegaBytes(byteCount: Int) -> Int {
        return byteCount / 1_048_576
    }
    
    let numBytesInMB = 1_048_576
    
    func getTransferTimeEstimateInSeconds(from photosPickerItem: PhotosPickerItem) -> Int? {
        guard let itemIdentifier = photosPickerItem.itemIdentifier else {
            print("no itemIdentifier")
            return nil
        }
        
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [itemIdentifier], options: nil)
        if result.count == 0 {
            print("no PHAsset results")
            return nil
        }
        if let asset = result.firstObject,
           let resource = PHAssetResource.assetResources(for: asset).first,
           let size = resource.value(forKey: "fileSize") as? Int {
            print("size: \(size)")
            
            return size / (9 * numBytesInMB)
        } else {
            print("no asset, resource, or size")
            return nil
        }
    }
    
    private func getSizeInBytes(photosPickerItem: PhotosPickerItem) -> Int? {
        guard let itemIdentifier = photosPickerItem.itemIdentifier else {
            logger.warning("no itemIdentifier")
            return nil
        }
        
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [itemIdentifier], options: nil)
        if result.count == 0 {
            logger.warning("no PHAsset results")
            return nil
        }
        if let asset = result.firstObject,
           let resource = PHAssetResource.assetResources(for: asset).first,
           let size = resource.value(forKey: "fileSize") as? Int {
            return size
        } else {
            logger.warning("Could not get fileSize")
            return nil
        }
        
    }
    
    var importProgressTimer: Timer?
    
    private func setupImportTimer(pickerItem: PhotosPickerItem) {
        let estimate = getTransferTimeEstimateInSeconds(from: pickerItem) ?? 1
        print("estimate: \(estimate)")
        loadingCount += 1
        let startTime = Date()
        importProgressTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            let elasped = Date().timeIntervalSince(startTime)
            DispatchQueue.main.async {
                self.currentVideoProgress = min(Int(elasped / Double(estimate) * 100), 99)
            }
        })
    }
    
    private func loadTransferable(from selection: PhotosPickerItem) {
        setupImportTimer(pickerItem: selection)
        
        Task {
            do {
                let importStartDate = Date()
                logger.info("importing video started")
                guard let video = try await selection.loadTransferable(type: Video.self) else {
                    // TODO: show error pop up
                    logger.error("loadTransferable failed for selection: \(selection)")
                    return
                }
                
                logger.info("import finished: \(Date().timeIntervalSince(importStartDate).twoDecimalPlaces) seconds.")
                
                importProgressTimer?.invalidate()
                importProgressTimer = nil
                
                let videoURL = URL.videoURL(videoPath: video.path)
                
                async let metaDataTask = getVideoMetaData(url: videoURL)
                
                let assetMetaData = try await metaDataTask
                
                let _ = try localVideoService.saveLocalVideo(path: video.path, duration: assetMetaData.duration, dateAdded: Date(), thumbnailData: assetMetaData.thumbnailData, frameRate: assetMetaData.frameRate, bodyposeFrames: [])
                
                DispatchQueue.main.async {
                    self.loadingCount -= 1
                    self.currentVideoProgress = 0
                    self.importSelection = nil
                }
            } catch {
                self.importSelection = nil
                // TODO: handle error ui
                logger.error("failed to save selected video: \(error) - \(error.localizedDescription)")
            }
        }
    }
    
//    private func loadTransferable(from selection: PhotosPickerItem) {
//        setupImportTimer(pickerItem: selection)
//        
//        Task {
//            do {
//                let importStartDate = Date()
//                logger.info("importing video started")
//                guard let video = try await selection.loadTransferable(type: Video.self) else {
//                    // TODO: show error pop up
//                    logger.error("loadTransferable failed for selection: \(selection)")
//                    return
//                }
//                
//                logger.info("import finished: \(Date().timeIntervalSince(importStartDate).twoDecimalPlaces) seconds.")
//                
//                importProgressTimer?.invalidate()
//                importProgressTimer = nil
//                
//                let videoURL = URL.videoURL(videoPath: video.path)
//                
//                async let metaDataTask = getVideoMetaData(url: videoURL)
//                async let bodyPoseFramesTask = getBodyPoseFrames(url: videoURL)
//                
//                let (assetMetaData, bodyframes) = try await (metaDataTask, bodyPoseFramesTask)
//                
//                let _ = try localVideoService.saveLocalVideo(path: video.path, duration: assetMetaData.duration, dateAdded: Date(), thumbnailData: assetMetaData.thumbnailData, frameRate: assetMetaData.frameRate, bodyposeFrames: bodyframes)
//                
//                DispatchQueue.main.async {
//                    self.loadingCount -= 1
//                    self.currentVideoProgress = 0
//                    self.importSelection = nil
//                }
//            } catch {
//                self.importSelection = nil
//                // TODO: handle error ui
//                logger.error("failed to save selected video: \(error) - \(error.localizedDescription)")
//            }
//        }
//    }
    
    private func getBodyPoseFrames(url: URL) async throws -> [BodyPoseFrame] {
        let startDate = Date()
        
        logger.info("getting body pose frames started.")
        
        let frames = try await bodyPoseDetector.getBodyPoseFrames(url: url) { [weak self] progress in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.currentVideoProgress = Int(progress * 100)
            }
        }
        
        logger.info("get body pose frames completed in: \(Date().timeIntervalSince(startDate).twoDecimalPlaces) seconds.")
        
        return frames
    }

////        get progress implementation but currently not working due to ios bug
////        self.importingProgress = selection.loadTransferable(type: Video.self) { [weak self] result in
////            guard let self = self else { return }
////            switch result {
////            case .success(let video):
////                Task {
////                    do {
////                        guard let video = video else {
////                            print("movie is nil")
////                            return
////                        }
////
////                        let thumbnail = try await self.generateThumbnail(for: video.path)
////                        let duration = try await self.getDuration(from: video.path)
////                        let localMovie = LocalVideo(path: video.path, dateAdded: Date(), thumbnailData: thumbnail.pngData()!, duration: duration)
////
////                        self.modelContext.insert(localMovie)
////                        try self.modelContext.save()
////                    } catch {
////                        print(error)
////                    }
////                }
////            case .failure(let error):
////                print(error)
////            }
////        }
////
////        observation = importingProgress?.observe(\.fractionCompleted, options: [.old,.new], changeHandler: { progress, change in
////            print(change)
////            self.progress = change.newValue
////        })
//    }
    
    func detectGolfSwingSaveNewVideo(localVideo: LocalVideoDTO) {
        Task {
            do {
                DispatchQueue.main.async {
                    self.loadingCount += 1
                }
                
                let detectedSwings = await golfSwingDetector.detectGolfSwings(localVideo: localVideo)
                
                let videoName = "\(UUID().uuidString).mp4"
                let path = "videos/\(videoName)"
                let destinationURL = URL.videoURL(videoPath: path)
                
                
                // head
//                try await VideoComposer().composeAndExportVideoFromTimeRanges(source: AVURLAsset(url: URL.videoURL(videoPath: localVideo.path)), destinationURL: destinationURL, timeRanges: golfSwingDetector.getTimeRangesForTraining(swings: detectedSwings))
                
                // dev
                try await VideoComposer().composeAndExportVideoFromTimeRanges(source: AVURLAsset(url: URL.videoURL(videoPath: localVideo.path)), destinationURL: destinationURL, timeRanges: golfSwingDetector.getTimeRanges(swings: detectedSwings))
                //end
                
                
                
                let metaData = try await getVideoMetaData(url: destinationURL)
                
                
                
                let frames = try await bodyPoseDetector.getBodyPoseFrames(url: destinationURL) { [weak  self] progress in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.currentVideoProgress = Int(progress * 100)
                    }
                }
                
            
                
                let _ = try localVideoService.saveLocalVideo(path: path, duration: metaData.duration, dateAdded: Date(), thumbnailData: metaData.thumbnailData, frameRate: metaData.frameRate, bodyposeFrames: frames)
                
                DispatchQueue.main.async {
                    self.currentVideoProgress = 0
                    self.loadingCount -= 1
                }
            } catch {
                // TODO: handle
                DispatchQueue.main.async {
                    self.currentVideoProgress = 0
                    self.loadingCount -= 1
                }
                print("saving new video failed")
            }
        }
    }
    
    func getVideoMetaData(url: URL) async throws -> VideoMetaData {
        let asset = AVURLAsset(url: url)
        let videoTracks = try await asset.load(.tracks)
        
        guard let videoTrack = videoTracks.first else {
            // TODO: handle
            throw MetaDataError.failedToGetVideoTrack
        }
        
        var duration: Double = 0
        var frameRate: Double = 0
        var thumbnailData: Data? = nil
        var resolution: CGSize = .zero
        
        do {
            duration = try await CMTimeGetSeconds(asset.load(.duration))
        } catch {
            logger.warning("Failed to get asset duration: \(error) - \(error.localizedDescription)")
        }
        
        do {
            frameRate = try await Double(videoTrack.load(.nominalFrameRate))
        } catch {
            logger.warning("Failed to get asset frame rate: \(error) - \(error.localizedDescription)")
        }
        
        do {
            thumbnailData = try await generateThumbnailImageData(asset: asset)
            
        } catch {
            logger.warning("Failed to generate thumbnail: \(error) - \(error.localizedDescription)")
        }
        
        do {
            resolution = try await videoTrack.load(.naturalSize)
        } catch {
            logger.warning("Failed to get video resolution: \(error) - \(error.localizedDescription)")
        }
        
        return VideoMetaData(duration: duration, frameRate: frameRate, thumbnailData: thumbnailData, resolution: resolution)
        
    }
    
    
    private func generateThumbnailImageData(asset: AVURLAsset) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let imageGen = AVAssetImageGenerator(asset: asset)
            imageGen.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0, preferredTimescale: 600)
            
            imageGen.generateCGImageAsynchronously(for: time) { cgImage, time, error in
                if let error {
                    continuation.resume(throwing: MetaDataError.failedToGenerateImage(error))
                }
                
                guard let cgImage else {
                    continuation.resume(throwing: MetaDataError.cgImageisNil)
                    return
                }
                
                let uiImage = UIImage(cgImage: cgImage)
                
                if let imageData = uiImage.pngData() {
                    continuation.resume(returning: imageData)
                } else {
                    continuation.resume(throwing: MetaDataError.failedToGenerateImageData)
                }
            }
        }
    }
    
    enum MetaDataError: Error {
        case failedToGenerateImage(Error)
        case cgImageisNil
        case failedToGenerateImageData
        case failedToGetVideoTrack
        
    }
    
    func generateThumbnail(for videoPath: String) async throws -> UIImage {
        
        return try await withCheckedThrowingContinuation { continuation in
            let url = URL.documentsDirectory.appendingPathComponent(videoPath)
            let asset = AVURLAsset(url: url)
            let imageGen = AVAssetImageGenerator(asset: asset)
            imageGen.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0, preferredTimescale: 600)
            
            imageGen.generateCGImageAsynchronously(for: time) { cgImage, time, error in
                if let error {
                    continuation.resume(throwing: error)
                }
                
                guard let cgImage else {
                    continuation.resume(returning: UIImage(systemName: "video.slash")!)
                    return
                }
                
                continuation.resume(returning: UIImage(cgImage: cgImage))
            }
        }
    }
}

struct VideoMetaData {
    let duration: Double
    let frameRate: Double
    let thumbnailData: Data?
    let resolution: CGSize
}
