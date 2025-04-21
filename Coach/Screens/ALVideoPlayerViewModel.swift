//
//  ALVideoPlayerViewModel.swift
//  Coach
//
//  Created by Allen Liang on 1/20/25.
//

import SwiftUI
import AVKit
import Vision
import Photos


class ALViewPlayerViewModel: ObservableObject {
    var player: AVPlayer
    @Published var playerStatus: ALVideoPlayerStatus = .idle
    @Published var currentTime: Double = 0.0
    @Published var playbackSpeed: Double = 1.0
    @Published var currentJoints: [BodyPosePart : VNRecognizedPointWrapper] = [:]
    @Published var showPose: Bool = false {
        didSet {
            print(showPose)
        }
    }
    let duration: Double
    var playerTimeControlStatusObservation: NSKeyValueObservation?
    var periodicTimeObservation: Any?
    // why does this not have to be @Published
    @Published var bones: [Bone] = []
    var bodyPoseFrames: [BodyPoseFrame]
    
    let jointsOfInterest: [BodyPosePart] = [
        .leftShoulder,
        .leftElbow,
        .leftWrist,
        .leftHip,
        .leftKnee,
        .leftAnkle,
        .rightShoulder,
        .rightElbow,
        .rightWrist,
        .rightHip,
        .rightKnee,
        .rightAnkle
    ]
    
    let leftJoints: [BodyPosePart] = [.leftShoulder,
                                      .leftElbow,
                                      .leftWrist,
                                      .leftHip,
                                      .leftKnee,
                                      .leftAnkle]
    
    let rightJoints: [BodyPosePart] = [.rightShoulder,
                                       .rightElbow,
                                       .rightWrist,
                                       .rightHip,
                                       .rightKnee,
                                       .rightAnkle]
    let localVideo: LocalVideoDTO
    
    init(localVideo: LocalVideoDTO
    
    
    
    ) {
        self.localVideo = localVideo
        self.player = AVPlayer(url: URL.documentsDirectory.appending(path: localVideo.path))
        self.duration = localVideo.duration
        self.bodyPoseFrames = localVideo.bodyPoseFrames
        
        self.periodicTimeObservation = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: 600), queue: .main, using: { [weak self] time in
            guard let self = self else { return }
            currentTime = time.seconds
            
            if let actualTime = player.currentItem?.currentTime(), let closestJoints = self.getClosestFrameJoint(time: actualTime) {
                self.bones = []
                
                self.currentJoints = closestJoints.joints
                
                // right bones
                if let rightAnkle = self.currentJoints[.rightAnkle], let rightKnee = self.currentJoints[.rightKnee] {
                    if validateVNPoints(vnPoints: [rightAnkle, rightKnee]) {
                        let rightShin = Bone(start: rightAnkle, end: rightKnee)
                        self.bones.append(rightShin)
                    }
                }
                
                if let rightKnee = self.currentJoints[.rightKnee], let rightHip = self.currentJoints[.rightHip] {
                    if validateVNPoints(vnPoints: [rightKnee, rightHip]) {
                        let rightFemur = Bone(start: rightKnee, end: rightHip)
                        self.bones.append(rightFemur)
                    }
                }
                
                
                if let rightShoulder = self.currentJoints[.rightShoulder], let rightElbow = self.currentJoints[.rightElbow] {
                    if validateVNPoints(vnPoints: [rightShoulder, rightElbow]) {
                        let rightUpperArm = Bone(start: rightShoulder, end: rightElbow)
                        self.bones.append(rightUpperArm)
                    }
                }
                
                if let rightElbow = self.currentJoints[.rightElbow], let rightWrist = self.currentJoints[.rightWrist] {
                    if validateVNPoints(vnPoints: [rightElbow, rightWrist]) {
                        let rightForearm = Bone(start: rightElbow, end: rightWrist)
                        self.bones.append(rightForearm)
                    }
                }
                
                // left bones
                if let leftAnkle = self.currentJoints[.leftAnkle], let leftKnee = self.currentJoints[.leftKnee] {
                    if validateVNPoints(vnPoints: [leftAnkle, leftKnee]) {
                        let leftShin = Bone(start: leftAnkle, end: leftKnee)
                        self.bones.append(leftShin)
                    }
                }
                
                if let leftKnee = self.currentJoints[.leftKnee], let leftHip = self.currentJoints[.leftHip] {
                    if validateVNPoints(vnPoints: [leftKnee, leftHip]) {
                        let leftFemur = Bone(start: leftKnee, end: leftHip)
                        self.bones.append(leftFemur)
                    }
                }
                
                
                if let leftShoulder = self.currentJoints[.leftShoulder], let leftElbow = self.currentJoints[.leftElbow] {
                    if validateVNPoints(vnPoints: [leftShoulder, leftElbow]) {
                        let leftUpperArm = Bone(start: leftShoulder, end: leftElbow)
                        self.bones.append(leftUpperArm)
                    }
                }
                
                if let leftElbow = self.currentJoints[.leftElbow], let leftWrist = self.currentJoints[.leftWrist] {
                    if validateVNPoints(vnPoints: [leftElbow, leftWrist]) {
                        let leftForearm = Bone(start: leftElbow, end: leftWrist)
                        self.bones.append(leftForearm)
                    }
                }
                
            } else {
                currentJoints = [:]
                bones = []
                print("time not found")
            }
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlayer), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        
        playerTimeControlStatusObservation = player.observe(\.timeControlStatus, options: [.new]) { player, change in
            if player.timeControlStatus == .paused {
                self.playerStatus = .paused
            } else if player.timeControlStatus == .playing {
                self.playerStatus = .playing
            }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMediaServicesReset),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: nil
        )
        
    }
    
    deinit {
        print("ALViewPlayerViewModel deinit")
    }
    
    func downloadVideo() {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Permission denied.")
                return
            }
            
            let videoURL = URL.videoURL(videoPath: self.localVideo.path)
            
            // Perform changes to save the video
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            } completionHandler: { success, error in
                if success {
                    print("✅ Video saved successfully!")
                } else {
                    print("❌ Error saving video: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    func shutdown() {
        playerTimeControlStatusObservation = nil
        player.removeTimeObserver(periodicTimeObservation)
        periodicTimeObservation = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    // uses binary search, microsecond performances
    func getClosestFrameJoint(time target: CMTime) -> BodyPoseFrame? {
        var lo = 0
        var hi = bodyPoseFrames.count - 1
        while lo <= hi {
            let mid = (lo + hi) / 2
            let time = bodyPoseFrames[mid].time
            if time == target {
                return bodyPoseFrames[mid]
            } else if target < time {
                hi = mid - 1
            } else if target > time {
                lo = mid + 1
            }
        }
        
        if lo < 0 {
            lo = 0
        }
        
        if lo > bodyPoseFrames.count - 1 {
            lo = bodyPoseFrames.count - 1
        }
        
        if hi < 0 {
            hi = 0
        }
        
        if hi > bodyPoseFrames.count - 1 {
            hi = bodyPoseFrames.count - 1
        }
        
        let fromLo = target - bodyPoseFrames[lo].time
        let fromHi = target - bodyPoseFrames[hi].time
        
        
        
        if fromLo < fromHi {
            if CMTime.isDifferenceMoreThan(seconds: 1, time1: target, time2: bodyPoseFrames[lo].time) {
                return nil
            }
            return bodyPoseFrames[lo]
        } else {
            if CMTime.isDifferenceMoreThan(seconds: 1, time1: target, time2: bodyPoseFrames[hi].time) {
                return nil
            }
            return bodyPoseFrames[hi]
        }
    }
    
    
    
    func validateVNPoints(vnPoints: [VNRecognizedPoint]) -> Bool {
        for point in vnPoints {
            if point.confidence > 0.5 {
                return false
            }
        }
        
        return true
    }
    
    func validateVNPoints(vnPoints: [VNRecognizedPointWrapper]) -> Bool {
        for point in vnPoints {
            if point.confidence < 0.5 {
                return false
            }
        }
        
        return true
    }
    
    
    
    @objc func handleMediaServicesReset() {
        print("")
    }
    
    
    
    
    
    @objc private func playerDidFinishPlayer() {
        playerStatus = .paused
    }
    
    func play() {
        if player.currentTime().seconds == duration {
            player.seek(to: .zero)
            player.rate = Float(playbackSpeed)
            player.play()
        } else {
            player.rate = Float(playbackSpeed)
            player.play()
        }
        
        playerStatus = .playing
    }
    
    func pause() {
        player.pause()
        playerStatus = .paused
    }
    
    func seek(to time: CMTime) {
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time.seconds
    }
    
    func seekToBeginning() {
        player.seek(to: .zero)
    }
    
    func seekToEnd() {
        if let duration = player.currentItem?.duration {
            player.seek(to: duration, toleranceBefore: .zero, toleranceAfter: .zero)
        }
    }
    
    func updatePlaybackSpeed(to speed: Double) {
        let validSpeedRange = 0.01...2.0
        if validSpeedRange.contains(speed) {
            player.rate = Float(speed)
            playbackSpeed = speed
        }
    }
    
    func stepFrame(isForward: Bool) {
        if playerStatus == .playing {
            pause()
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        player.currentItem?.step(byCount: isForward ? 1 : -1)
    }
}
