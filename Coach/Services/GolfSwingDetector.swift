//
//  GolfSwingDetector.swift
//  Coach
//
//  Created by Allen Liang on 3/4/25.
//

import Foundation
import AVFoundation

struct GolfSwingDetector {
    let minPoseDetectionConfidence: Float = 0.6
    private let logger: LoggerProvider?
    
    init(logger: LoggerProvider?) {
        self.logger = logger
    }
    
    func detectGolfSwings(localVideo: LocalVideoDTO) async -> [DetectedGolfSwing] {
        let bodyFrames = localVideo.bodyPoseFrames
        let frameRate = Int(localVideo.frameRate)
        var detectedSwings: [DetectedGolfSwing] = []
        var curIndex = 0
        
        logger?.info("Starting golf swing detector: \(localVideo.path), video duration: \(localVideo.duration), frames: \(bodyFrames.count)")
        
        while curIndex < bodyFrames.count {
            guard let backSwingIndex = findBackSwingIndex(bodyFrames: bodyFrames, startIndex: curIndex, endIndex: bodyFrames.count) else {
                logger?.info("Could not find next back swing position, stopping detector.")
                break
            }
            
            logger?.info("backswing detected at \(bodyFrames[backSwingIndex].time.seconds.twoDecimalPlaces) seconds")
            
            guard let setupPositionIndex = findSetupPositionIndex(bodyFrames: bodyFrames, fromIndex: backSwingIndex) else {
                
                logger?.info("did not find setup position from backswing at \(bodyFrames[backSwingIndex].time.seconds.twoDecimalPlaces) seconds) seconds")
                /// couldn't find backswing in within one second, move curIndex 1 second forward from backSwingIndex
                curIndex = backSwingIndex + (1 * frameRate)
                continue
            }
            
            logger?.info("setup position detected at \(bodyFrames[setupPositionIndex].time.seconds) seconds")
            
            guard let followThroughIndex = findFollowthroughIndex(bodyFrames: bodyFrames, startIndex: backSwingIndex) else {
                logger?.info("Could not find follow through position from backswing at \(bodyFrames[backSwingIndex].time.seconds.twoDecimalPlaces) seconds")
                /// couldn't find follow through within 2 seconds, move curIndex 2 seconds forward from backSwingIndex
                curIndex = backSwingIndex + (2 * frameRate)
                continue
            }
            
            logger?.info("follow through position detected at \(bodyFrames[followThroughIndex].time.seconds.twoDecimalPlaces) seconds")
            
            /// nextSwingFrame is used to add padding to the end of the followthrough frame so we can see the ball flight and the whole follow through motion.
            guard let nextSwingIndex = findNextSwingPositionIndex(bodyFrames: bodyFrames, startIndex: followThroughIndex) else {
                detectedSwings.append(
                    DetectedGolfSwing(
                        backSwingFrame: bodyFrames[backSwingIndex],
                        setupFrame: bodyFrames[setupPositionIndex],
                        followThroughFrame: bodyFrames[followThroughIndex],
                        nextSwingFrame: bodyFrames[bodyFrames.count - 1]
                    )
                )
                break
            }
            
            logger?.info("next swing postion detected at \(bodyFrames[nextSwingIndex].time.seconds.twoDecimalPlaces) seconds")
            
            detectedSwings.append(
                DetectedGolfSwing(
                    backSwingFrame: bodyFrames[backSwingIndex],
                    setupFrame: bodyFrames[setupPositionIndex],
                    followThroughFrame: bodyFrames[followThroughIndex],
                    nextSwingFrame: bodyFrames[nextSwingIndex]
                )
            )
                        
            curIndex = nextSwingIndex
        }
        
        logger?.info("golf swing detection complete. \(detectedSwings.count) swing(s) detected.")
        
        return detectedSwings
    }
    
//    func detectGolfSwings(localVideo: LocalVideoDTO) async -> String? {
//        let bodyFrames = localVideo.bodyPoseFrames
//        let frameRate = Int(localVideo.frameRate)
//        
//        var detectedSwings: [DetectedGolfSwing] = []
//        
//        var curIndex = 0
//        
//        while curIndex < bodyFrames.count {
//            guard let backSwingIndex = findBackSwingIndex(bodyFrames: bodyFrames, startIndex: curIndex, endIndex: bodyFrames.count) else {
//                break
//            }
//            
//            print("backswing time: \(bodyFrames[backSwingIndex].time.seconds)")
//            
//            guard let setupPositionIndex = findSetupPositionIndex(bodyFrames: bodyFrames, fromIndex: backSwingIndex) else {
//                // couldn't find backswing in within one second, move curIndex 1 second forward from backSwingIndex
//                curIndex = backSwingIndex + (1 * frameRate)
//                continue
//            }
//            
//            print("setup time: \(bodyFrames[setupPositionIndex].time.seconds)")
//            
//            guard let followThroughIndex = findFollowthroughIndex(bodyFrames: bodyFrames, startIndex: backSwingIndex) else {
//                // couldn't find follow through within 2 seconds, move curIndex 2 seconds forward from backSwingIndex
//                curIndex = backSwingIndex + (2 * frameRate)
//                continue
//            }
//            
//            print("followThroughIndex time: \(bodyFrames[followThroughIndex].time.seconds)")
//            
//            guard let nextSwingIndex = findNextSwingPositionIndex(bodyFrames: bodyFrames, startIndex: followThroughIndex) else {
//                detectedSwings.append(
//                    DetectedGolfSwing(
//                        backSwingFrame: bodyFrames[backSwingIndex],
//                        setupFrame: bodyFrames[setupPositionIndex],
//                        followThroughFrame: bodyFrames[followThroughIndex],
//                        nextSwingFrame: bodyFrames[bodyFrames.count - 1]
//                    )
//                )
//                break
//            }
//            
//            detectedSwings.append(
//                DetectedGolfSwing(
//                    backSwingFrame: bodyFrames[backSwingIndex],
//                    setupFrame: bodyFrames[setupPositionIndex],
//                    followThroughFrame: bodyFrames[followThroughIndex],
//                    nextSwingFrame: bodyFrames[nextSwingIndex]
//                )
//            )
//            
//            print("nextSwingIndex time: \(bodyFrames[nextSwingIndex].time.seconds)")
//            
//            curIndex = nextSwingIndex
//            print()
//        }
//        
//        print("swing count: \(detectedSwings.count)")
//        
//        
//        if detectedSwings.count < 1 {
//            // switch to throwing
//            return ""
//        }
//        // save new video
//        
//        let url = URL.videoURL(videoPath: localVideo.path)
//        let asset = AVURLAsset(url: url)
//        
//        guard let videoTrack = try! await asset.loadTracks(withMediaType: .video).first, let audioTrack = try! await asset.loadTracks(withMediaType: .audio).first else {
//            print("\(#function): no video track or audio tracks")
//            return ""
//        }
//        
//        
//        
//        let composition = AVMutableComposition()
//        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
//        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
//        var curCompositionTime = CMTime.zero
//        
//        for timeRange in getTimeRanges(swings: detectedSwings) {
//            try! compositionVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: curCompositionTime)
//            try! compositionAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: curCompositionTime)
//            curCompositionTime = CMTimeAdd(curCompositionTime, timeRange.duration)
//        }
//        
//        compositionVideoTrack?.preferredTransform = try! await videoTrack.load(.preferredTransform)
//        
//        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
//        let videoName = "\(UUID().uuidString).mp4"
//        let path = "videos/\(videoName)"
//        let destinationURL = URL.videoURL(videoPath: path)
//        try! await exportSession?.export(to: destinationURL, as: .mp4)
//        
//        print("new video saved")
//        
//        return path
//    }
    
    
    private func findNextSwingPositionIndex(bodyFrames: [BodyPoseFrame], startIndex: Int) -> Int? {
        for i in startIndex..<bodyFrames.count {
            let curFrame = bodyFrames[i]
            guard let rightWrist = curFrame.joints[.rightWrist], let rightHip = curFrame.joints[.rightHip],
                  isConfident(rightWrist), isConfident(rightHip),
                  isJoint(rightWrist, below: rightHip) else {
                continue
            }
            
            return i
        }
        
        return nil
    }
    
    /// Identifies backswing postion as when the right wrist is above right shouulder and left wrist is right of right hip
    private func findBackSwingIndex(bodyFrames: [BodyPoseFrame], startIndex: Int, endIndex: Int) -> Int? {
        for i in startIndex..<endIndex {
            let curFrame = bodyFrames[i]
            guard let rightWrist = curFrame.joints[.rightWrist], let rightHip = curFrame.joints[.rightHip],
                  let rightShoulder = curFrame.joints[.rightShoulder],
                  let leftWrist = curFrame.joints[.leftWrist],
                  isConfident(rightWrist), isConfident(rightHip) else {
                continue
            }
            
            if isJoint(rightWrist, above: rightShoulder), isJoint(leftWrist, rightOf: rightHip) {
                return i
            }
        }
        
        return nil
    }
    
    
    /// finds the follow through within 2 seconds
    private func findFollowthroughIndex(bodyFrames: [BodyPoseFrame], startIndex: Int) -> Int? {
        let startTime = bodyFrames[startIndex].time
        let timeThresholdInSeconds = 2.0
        
        for i in startIndex..<bodyFrames.count {
            let curFrame = bodyFrames[i]
            if isDifferenceMoreThan(seconds: timeThresholdInSeconds, time1: startTime, time2: curFrame.time) {
                return nil
            }
            
            guard let leftWrist = curFrame.joints[.leftWrist],
                  let rightWrist = curFrame.joints[.rightWrist],
                  let rightHip = curFrame.joints[.rightHip],
                  isConfident(leftWrist),
                  isConfident(rightWrist),
                  isConfident(rightHip) else {
                continue
            }
            
            if isJoint(leftWrist, leftOf: rightWrist) &&
                isJoint(leftWrist, leftOf: rightHip) &&
                isJoint(rightWrist, leftOf: rightHip) {
                
                return i
            }
        }
        
        return nil
    }
    
    func getTimeRanges(swings: [DetectedGolfSwing]) -> [CMTimeRange] {
        var timeRanges: [CMTimeRange] = []
        for swing in swings {
            timeRanges.append(CMTimeRange(start: swing.setupFrame.time, end: swing.nextSwingFrame.time))
        }
        
        return timeRanges
    }
    
    func getTimeRangesForTraining(swings: [DetectedGolfSwing]) -> [CMTimeRange] {
        var timeRanges: [CMTimeRange] = []
        for swing in swings {
            timeRanges.append(CMTimeRange(start: swing.setupFrame.time, end: swing.followThroughFrame.time))
        }
        
        return timeRanges
    }
    
    
    private func isConfident(_ point: VNRecognizedPointWrapper) -> Bool {
        return point.confidence > minPoseDetectionConfidence
    }
    
    
    private func isJoint(_ lhs: VNRecognizedPointWrapper, above rhs: VNRecognizedPointWrapper) -> Bool {
        return lhs.y > rhs.y
    }
    
    private func isJoint(_ lhs: VNRecognizedPointWrapper, leftOf rhs: VNRecognizedPointWrapper) -> Bool {
        return lhs.x < rhs.x
    }
    
    private func isJoint(_ lhs: VNRecognizedPointWrapper, rightOf rhs: VNRecognizedPointWrapper) -> Bool {
        return lhs.x > rhs.x
    }
    
    private func isJoint(_ lhs: VNRecognizedPointWrapper, below rhs: VNRecognizedPointWrapper) -> Bool {
        return lhs.y < rhs.y
    }
    
    private func isDifferenceMoreThan(seconds: Double, time1: CMTime, time2: CMTime) -> Bool {
        let difference = CMTimeSubtract(time1, time2)
        let absoluteDifference = CMTimeMake(value: abs(difference.value), timescale: difference.timescale)
        let oneSecond = CMTime(seconds: seconds, preferredTimescale: absoluteDifference.timescale)
        return CMTimeCompare(absoluteDifference, oneSecond) == 1
    }
    
    /// finds the follow through within 3 seconds
    private func findSetupPositionIndex(bodyFrames: [BodyPoseFrame], fromIndex: Int) -> Int? {
        let yThreshold = 0.02
        let timeThresholdInSeconds = 3.0
        var potentialFrame: BodyPoseFrame?
        let fromFrame = bodyFrames[fromIndex]
        
        for i in stride(from: fromIndex, through: 0, by: -1) {
            let curFrame = bodyFrames[i]
            let time = curFrame.time
            let joints = curFrame.joints
            if isDifferenceMoreThan(seconds: timeThresholdInSeconds, time1: fromFrame.time, time2: time) {
                return nil
            }
            
            guard let rightWrist = joints[.rightWrist], let rightHip = joints[.rightHip], isConfident(rightWrist), isConfident(rightHip) else {
                continue
            }
            
            if let potentialRightWrist = potentialFrame?.joints[.rightWrist], let potentialTime = potentialFrame?.time {
                // check if rightWrist position is steady for 1 second hinting at it
                // being in the setup part of swing.
                if abs(rightWrist.y - potentialRightWrist.y) < yThreshold  {
                    if isDifferenceMoreThan(seconds: 1, time1: time, time2: potentialTime) {
                        return i
                    }
                } else {
                    potentialFrame = curFrame
                }
            } else {
                potentialFrame = curFrame
            }
        }
        
        return nil
        
    }
}
