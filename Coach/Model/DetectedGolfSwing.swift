//
//  DetectedSwing.swift
//  Coach
//
//  Created by Allen Liang on 1/21/25.
//

import Foundation

struct DetectedGolfSwing {
    let setupFrame: BodyPoseFrame
    let backSwingFrame: BodyPoseFrame
    let followThroughFrame: BodyPoseFrame
    let nextSwingFrame: BodyPoseFrame
    
    init(backSwingFrame: BodyPoseFrame, setupFrame: BodyPoseFrame, followThroughFrame: BodyPoseFrame, nextSwingFrame: BodyPoseFrame) {
        self.backSwingFrame = backSwingFrame
        self.setupFrame = setupFrame
        self.followThroughFrame = followThroughFrame
        self.nextSwingFrame = nextSwingFrame
    }
}
