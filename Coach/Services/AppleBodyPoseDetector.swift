//
//  AppleBodyPoseDetector.swift
//  Coach
//
//  Created by Allen Liang on 3/4/25.
//

import Foundation
import AVFoundation
import Vision
import CoreImage
import UIKit

struct VideoComposer {
    enum VideoComposerError: Error {
        case failedToGetTracks(Error?)
        case failedToGetPreferredTransform(Error)
        case failedToInsertTrack(Error)
        case failedToExport(Error)
        case failedToCreateExportSession
    }
    
    func composeAndExportVideoFromTimeRanges(source: AVURLAsset, destinationURL: URL, timeRanges: [CMTimeRange]) async throws {
        var videoTrack: AVAssetTrack
        var audioTrack: AVAssetTrack
        
        do {
            guard let loadedVideoTrack = try await source.loadTracks(withMediaType: .video).first, let loadedAudioTrack = try await source.loadTracks(withMediaType: .audio).first else {
                throw VideoComposerError.failedToGetTracks(nil)
            }
            
            videoTrack = loadedVideoTrack
            audioTrack = loadedAudioTrack
        } catch {
            throw VideoComposerError.failedToGetTracks(error)
        }
        
        let composition = AVMutableComposition()
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        var curCompositionTime = CMTime.zero
        
        for timeRange in timeRanges {
            do {
                try compositionVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: curCompositionTime)
                try compositionAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: curCompositionTime)
                curCompositionTime = CMTimeAdd(curCompositionTime, timeRange.duration)
            } catch {
                throw VideoComposerError.failedToInsertTrack(error)
            }
        }
        
        do {
            compositionVideoTrack?.preferredTransform = try await videoTrack.load(.preferredTransform)
        } catch {
            throw VideoComposerError.failedToGetPreferredTransform(error)
        }
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw VideoComposerError.failedToCreateExportSession
        }
        
        do {
            try await exportSession.export(to: destinationURL, as: .mp4)
        } catch {
            throw VideoComposerError.failedToExport(error)
        }
    }
}


struct AppleBodyPoseDetector: BodyPoseDetectorProtocol {
    private let logger: LoggerProvider?
    
    init(logger: LoggerProvider?) {
        self.logger = logger
    }
    
    func getBodyPoseFrames(url: URL, progressHandler: (Double) -> Void) async throws -> [BodyPoseFrame] {
        let asset = AVURLAsset(url: url)

        let videoTrack = try await asset.loadTracks(withMediaType: .video).first!
        let frameRate = try await videoTrack.load(.nominalFrameRate)
        let duration = try await videoTrack.asset!.load(.duration)
        let videoTransform = try await videoTrack.load(.preferredTransform).inverted()
        let totalFrames = Double(frameRate) * duration.seconds
        
        
        let assetReader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        let trackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
        assetReader.add(trackOutput)
        assetReader.startReading()
        
        var frameBatch: [CMSampleBuffer] = []
        var bodyFrames: [BodyPoseFrame] = []
        
        while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
            if frameBatch.count < 100 {
                frameBatch.append(sampleBuffer)
                continue
            }
            
            //process batch
            let batchBodyFrames = await batchDetectUsingAppleVision(sampleBufferBatch: frameBatch, transform: videoTransform)
            bodyFrames += batchBodyFrames
            frameBatch = []
            progressHandler(Double(bodyFrames.count) / totalFrames)
        }
        
        // process remaining batch
        let remainderBatch = await batchDetectUsingAppleVision(sampleBufferBatch: frameBatch, transform: videoTransform)
        bodyFrames += remainderBatch
        
        switch assetReader.status {
        case .unknown:
            break
        case .reading:
            break
        case .completed:
            break
        case .failed:
            logger?.warning("assetReader failed.")
        case .cancelled:
            logger?.warning("assetReader cancelled.")
        @unknown default:
            logger?.warning("assetReader unhandled status.")
        }
        
        return bodyFrames
    }
    
    private func batchDetectUsingAppleVision(sampleBufferBatch: [CMSampleBuffer], chunkCount: Int = 4, transform: CGAffineTransform) async -> [BodyPoseFrame] {
        let chunkSize = sampleBufferBatch.count / chunkCount
        var chunks: [[CMSampleBuffer]] = []
        
        for i in 0..<(chunkCount - 1) {
            let start = i * chunkSize
            let end = start + chunkSize
            chunks.append(Array(sampleBufferBatch[start..<end]))
        }
        
        // last chunk includes the remainder
        let start = (chunkCount-1) * chunkSize
        let end = sampleBufferBatch.count
        chunks.append(Array(sampleBufferBatch[start..<end]))
        
        var tasks: [Task<[BodyPoseFrame], Never>] = []
        for chunk in chunks {
            async let task = Task {
                var bodyFrames: [BodyPoseFrame] = []
                for sampleBuffer in chunk {
                    if let bodyFrame = detectUsingAppleVision(sampleBuffer: sampleBuffer, transform: transform) {
                        bodyFrames.append(bodyFrame)
                    }
                }
                return bodyFrames
            }
            
            await tasks.append(task)
        }
        
        var results: [BodyPoseFrame] = []
        for task in tasks {
            let res = await task.value
            results += res
        }
        
        return results
    }
    
    private func detectUsingAppleVision(sampleBuffer: CMSampleBuffer, transform: CGAffineTransform) -> BodyPoseFrame? {
        do {
            let request = VNDetectHumanBodyPoseRequest()
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                logger?.error("Failed to get CVImageBuffer from CMSampleBuffer at time: \(sampleBuffer.presentationTimeStamp.seconds).")
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
            logger?.error("Failed to run body pose detection at time: \(sampleBuffer.presentationTimeStamp.seconds).")
            return nil
        }
        
        return nil
    }
    
}


