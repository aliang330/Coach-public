//
//  LocalVideoDTO.swift
//  Coach
//
//  Created by Allen Liang on 2/26/25.
//

import UIKit


struct LocalVideoDTO: Identifiable, Hashable {
    var id: String { path }
    
    let path: String
    let dateAdded: Date
    let duration: Double
    let frameRate: Double
    let thumbnailData: Data?
    let bodyPoseFrames: [BodyPoseFrame]
    
    init(path: String, dateAdded: Date, duration: Double, frameRate: Double, thumbnailData: Data?, bodyPoseFrames: [BodyPoseFrame]) {
        self.path = path
        self.dateAdded = dateAdded
        self.duration = duration
        self.frameRate = frameRate
        self.thumbnailData = thumbnailData
        self.bodyPoseFrames = bodyPoseFrames
    }
    
    func hash(into hasher: inout Hasher) {
        // Hash only stable properties that define identity
        hasher.combine(path)
    }
    
//    // Implement equality check for Hashable conformance
//    static func == (lhs: LocalVideoDTO, rhs: LocalVideoDTO) -> Bool {
//        // Two videos are the same if they have the same path
//        return lhs.path == rhs.path
//    }
}
