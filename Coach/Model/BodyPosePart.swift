//
//  BodyPosePart.swift
//  Coach
//
//  Created by Allen Liang on 12/20/24.
//

import Foundation
import Vision
import MediaPipeTasksVision

enum BodyPosePart: String, Codable, Equatable {
    case leftAnkle = "leftAnkle"
    case leftKnee = "leftKnee"
    case leftHip = "leftHip"
    case leftShoulder = "leftShoulder"
    case leftElbow = "leftElbow"
    case leftWrist = "leftWrist"
    case rightHip = "rightHip"
    case rightKnee = "rightKnee"
    case rightAnkle = "rightAnkle"
    case rightShoulder = "rightShoulder"
    case rightWrist = "rightWrist"
    case rightElbow = "rightElbow"
    case undefined = "undefined"
        
    init(vnJointName: VNHumanBodyPoseObservation.JointName) {
        switch vnJointName {
        case .leftAnkle:
            self = .leftAnkle
        case .leftKnee:
            self = .leftKnee
        case .leftHip:
            self = .leftHip
        case .leftShoulder:
            self = .leftShoulder
        case .leftElbow:
            self = .leftElbow
        case .leftWrist:
            self = .leftWrist
        case .rightAnkle:
            self = .rightAnkle
        case .rightKnee:
            self = .rightKnee
        case .rightHip:
            self = .rightHip
        case .rightShoulder:
            self = .rightShoulder
        case .rightElbow:
            self = .rightElbow
        case .rightWrist:
            self = .rightWrist
        default:
            self = .undefined
        }
    }
    
    // mediapipe pose support
    init(landMarkIndex: Int) {
        switch landMarkIndex {
        case 27:
            self = .leftAnkle
        case 25:
            self = .leftKnee
        case 23:
            self = .leftHip
        case 11:
            self = .leftShoulder
        case 13:
            self = .leftElbow
        case 15:
            self = .leftWrist
        default:
            self = .undefined
        }
    }
}
