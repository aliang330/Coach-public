//
//  BodyPoseFrame.swift
//  Coach
//
//  Created by Allen Liang on 12/20/24.
//

import Foundation
import Vision
import MediaPipeTasksVision

struct BodyPoseFrame: Codable, Equatable {
    let time: CMTime
    let joints: [BodyPosePart : VNRecognizedPointWrapper]
    
    init(time: CMTime, joints: [BodyPosePart : VNRecognizedPointWrapper]) {
        self.time = time
        self.joints = joints
    }
    
    init(time: CMTime, joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        var convertedJoints: [BodyPosePart : VNRecognizedPointWrapper] = [:]
        for (jointName, vnPoint) in joints {
            convertedJoints[BodyPosePart(vnJointName: jointName)] = VNRecognizedPointWrapper(vnPoint: vnPoint)
        }
        self.init(time: time, joints: convertedJoints)
    }
    
    init(time: CMTime, poseLandmarkerResult: PoseLandmarkerResult) {
        var convertedJoints: [BodyPosePart : VNRecognizedPointWrapper] = [:]
        let landmarks = poseLandmarkerResult.landmarks.first!
        for (index, landmark) in landmarks.enumerated() {
            let bodyPart = BodyPosePart(landMarkIndex: index)
            let point = VNRecognizedPointWrapper(
                location: CGPoint(x: CGFloat(landmark.x),
                                  y: 1.0 - CGFloat(landmark.y)
                                 ),
                confidence: 0.8)
            
            convertedJoints[bodyPart] = point
        }
        
        self.init(time: time, joints: convertedJoints)
    }
}
