//
//  BodyPoseHelper.swift
//  Coach
//
//  Created by Allen Liang on 12/20/24.
//

import Foundation
import Vision
import AVFoundation
import CoreImage
import MediaPipeTasksVision

enum BodyPoseModel {
    case apple
    case mediapipe_lite
    case mediapipe_full
    case mediapipe_heavy
}

enum MediaPipeModel {
    case mediapipe_lite
    case mediapipe_full
    case mediapipe_heavy
}



class BodyPoseHelper {
    static let shared = BodyPoseHelper()
    var poseLandmarker: PoseLandmarker? = nil
    var currentMediaPipeModel: MediaPipeModel? = nil
    let minPoseDetectionConfidence: Float = 0.6
    let minPosePresenceConfidence: Float = 0.6
    let minTrackingConfidence: Float = 0.5
    let numPoses = 1
    
    init() {}
    
    func initializePoseLandMaker(model: MediaPipeModel) {
        var modelString: String
        
        switch model {
        case .mediapipe_lite:
            modelString = "pose_landmarker_lite"
        case .mediapipe_full:
            modelString = "pose_landmarker_full"
        case .mediapipe_heavy:
            modelString = "pose_landmarker_heavy"
        }
        
        let modelPath = Bundle.main.path(forResource: modelString,
                                         ofType: "task")!
        let options = PoseLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .image
        options.minPoseDetectionConfidence = minPoseDetectionConfidence
        options.minPosePresenceConfidence = minPosePresenceConfidence
        options.minTrackingConfidence = minTrackingConfidence
        options.numPoses = numPoses
        
        self.poseLandmarker = try! PoseLandmarker(options: options)
    }
    
    
    
    // TODO: make more general purpose
    /// downloads the frames of a video at a URL to frames/ in documents directory
    static func downloadFrames(url: URL) async {
        let asset = AVURLAsset(url: url)
        
        guard let videoTrack = try! await asset.loadTracks(withMediaType: .video).first else {
            print("\(#function): no video track")
            return
        }
        
        do {
            let assetReader = try AVAssetReader(asset: asset)
            let outputSettings: [String: Any] = [
                (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
            ]
            let trackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
            assetReader.add(trackOutput)
            
            assetReader.startReading()
            var count = 0
            while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
                guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                    print("Failed to get image buffer from sample buffer.")
                    return
                }
                
                let ciImage = CIImage(cvPixelBuffer: imageBuffer)
                let context = CIContext()
                guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                    print("Failed to create CGImage from CIImage.")
                    return
                }
                
                let uiImage = UIImage(cgImage: cgImage)
                
                let framesFolder = URL.documentsDirectory.appending(path: "frames")
                try FileManager.createPathIfNotExist(url: framesFolder)
                let frameName = String(format: "frame%05d.png", count)
                let destinationURL = framesFolder.appending(path: frameName)
                try uiImage.pngData()?.write(to: destinationURL)
                print(count)
                count += 1
            }
        } catch {
            print("\(#function): \(error)")
            return
        }
        
    }
    
    func detectUsingMediaPipe(model: MediaPipeModel, sampleBuffer: CMSampleBuffer, transform: CGAffineTransform) -> BodyPoseFrame? {
        if currentMediaPipeModel != model {
            initializePoseLandMaker(model: model)
        }
        
        do {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                print("cant get image buffer")
                return nil
            }
            
            let ciimage = CIImage(cvImageBuffer: imageBuffer).transformed(by: transform)
            let ciContext = CIContext()
            
            guard let cgImage = ciContext.createCGImage(ciimage, from: ciimage.extent) else {
                print("cant get cgImage")
                return nil
            }
            
            let uiimage = UIImage(cgImage: cgImage)
            let mpImage = try MPImage(uiImage: uiimage)
            let result = try poseLandmarker!.detect(image: mpImage)
            
            return BodyPoseFrame(time: sampleBuffer.presentationTimeStamp, poseLandmarkerResult: result)
        } catch {
            return nil
        }
    }
    
    func detectUsingAppleVision(sampleBuffer: CMSampleBuffer, transform: CGAffineTransform) -> BodyPoseFrame? {
        do {
            let request = VNDetectHumanBodyPoseRequest()
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                print("cant get image buffer")
                return nil
            }
            
            let ciimage = CIImage(cvImageBuffer: imageBuffer).transformed(by: transform)
            let handler = VNImageRequestHandler(ciImage: ciimage)
            
            try handler.perform([request])
            if let returnedObservation = request.results?.first {
                let points = try returnedObservation.recognizedPoints(.all)
                return BodyPoseFrame(time: sampleBuffer.presentationTimeStamp, joints: points)
            }
        } catch {
            print("\(#function) \(error)")
            return nil
        }
        
        return nil
    }
    
    
    
    func getBodyPoseFramesEvenFaster(model: BodyPoseModel, url: URL, progressHandler: (Double) -> Void) async -> [BodyPoseFrame] {
        let asset = AVURLAsset(url: url)

        let videoTrack = try! await asset.loadTracks(withMediaType: .video).first!
        let frameRate = try! await videoTrack.load(.nominalFrameRate)
        let duration = try! await videoTrack.asset!.load(.duration)
        let videoTransform = try! await videoTrack.load(.preferredTransform).inverted()
        let totalFrames = Int(Double(frameRate) * duration.seconds)
        
        // Create a result array with capacity to avoid resizing
        var bodyFrames = [BodyPoseFrame?](repeating: nil, count: totalFrames)
        
        let assetReader = try! AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: 640, // Set your desired width here
            kCVPixelBufferHeightKey as String: 480 // Set your desired height here
        ]
        let trackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
        assetReader.add(trackOutput)
        assetReader.startReading()
        
        // Determine optimal batch size based on system capabilities
        let processorCount = ProcessInfo.processInfo.processorCount
        let optimalBatchSize = max(processorCount * 5, 20) // Minimum 20, scales with CPU cores
        var frameIndex = 0
        var frameBatch: [CMSampleBuffer] = []
        
        // Initialize progress tracking
        let progressLock = NSLock()
        var completedFrames = 0

        // Process frames in batches
        while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
            frameBatch.append(sampleBuffer)
            
            // Process when we've accumulated enough frames for a batch
            if frameBatch.count >= optimalBatchSize {
                let currentBatch = frameBatch
                let currentStartIndex = frameIndex - frameBatch.count
                
                // Process this batch concurrently
                await processBatch(
                    sampleBuffers: currentBatch,
                    startIndex: currentStartIndex,
                    transform: videoTransform,
                    bodyFrames: &bodyFrames,
                    progressLock: progressLock,
                    completedFrames: &completedFrames,
                    totalFrames: totalFrames,
                    progressHandler: progressHandler
                )
                
                frameBatch = []
            }
            
            frameIndex += 1
        }
        
        // Process any remaining frames
        if !frameBatch.isEmpty {
            let currentStartIndex = frameIndex - frameBatch.count
            await processBatch(
                sampleBuffers: frameBatch,
                startIndex: currentStartIndex,
                transform: videoTransform,
                bodyFrames: &bodyFrames,
                progressLock: progressLock,
                completedFrames: &completedFrames,
                totalFrames: totalFrames,
                progressHandler: progressHandler
            )
        }
        
        // Handle any errors from asset reading
        switch assetReader.status {
        case .failed:
            print("Asset reader failed: \(assetReader.error?.localizedDescription ?? "Unknown error")")
        case .cancelled:
            print("Asset reading was cancelled")
        default:
            break
        }
        
        // Return non-nil frames in order
        let result = bodyFrames.compactMap { $0 }
        print("Total frames processed: \(result.count)")
        return result
    }

    private func processBatch(
        sampleBuffers: [CMSampleBuffer],
        startIndex: Int,
        transform: CGAffineTransform,
        bodyFrames: inout [BodyPoseFrame?],
        progressLock: NSLock,
        completedFrames: inout Int,
        totalFrames: Int,
        progressHandler: (Double) -> Void
    ) async {
        // Process a batch of frames using TaskGroup for controlled concurrency
        await withTaskGroup(of: [(Int, BodyPoseFrame?)].self) { group in
            // Determine optimal chunk size based on system capabilities
            let processorCount = ProcessInfo.processInfo.processorCount
            let optimalChunkCount = min(max(processorCount - 1, 2), 8) // Between 2 and 8 chunks
            
            // Distribute frames across chunks more evenly
            let chunkSize = (sampleBuffers.count + optimalChunkCount - 1) / optimalChunkCount // Ceiling division
            
            // Create task for each chunk
            for chunkIndex in 0..<optimalChunkCount {
                let startOffset = chunkIndex * chunkSize
                let endOffset = min(startOffset + chunkSize, sampleBuffers.count)
                
                // Skip empty chunks (possible at the end)
                if startOffset >= sampleBuffers.count {
                    continue
                }
                
                group.addTask {
                    var chunkResults: [(Int, BodyPoseFrame?)] = []
                    
                    // Process each frame in this chunk
                    for offset in startOffset..<endOffset {
                        let frameIndex = startIndex + offset
                        let sampleBuffer = sampleBuffers[offset]
                        
                        // Detect pose in this frame
                        let bodyFrame = self.detectUsingAppleVision(sampleBuffer: sampleBuffer, transform: transform)
                        chunkResults.append((frameIndex, bodyFrame))
                    }
                    
                    // Process each frame in this chunk and return results individually
                    return chunkResults
                }
            }
            
            // Collect results as tasks complete
            for await chunkResults in group {
                for (index, bodyFrame) in chunkResults {
                    if let bodyFrame = bodyFrame {
                        // Store result at the correct index
                        bodyFrames[index] = bodyFrame
                        
                        // Update progress
                        progressLock.lock()
                        completedFrames += 1
                        let progress = Double(completedFrames) / Double(totalFrames)
                        progressLock.unlock()
                        
                        // Report progress (throttle updates to avoid UI bottlenecks)
                        if completedFrames % 10 == 0 {
                            progressHandler(progress)
                        }
                    }
                }
            }
        }
    }
    
    
}

extension FileManager {
    static func createPathIfNotExist(url: URL) throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    static func saveImage(path: String) {
        
    }
    
}

extension UIImage {
    func writeToPath(path: String) throws {
        let destinationURL = URL.documentsDirectory.appending(path: path)
        let directoryURL = destinationURL.deletingLastPathComponent()
        try FileManager.createPathIfNotExist(url: directoryURL)
        try self.pngData()?.write(to: destinationURL)
    }
}
