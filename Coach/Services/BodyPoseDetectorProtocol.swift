//
//  BodyPoseDetectorProtocol.swift
//  Coach
//
//  Created by Allen Liang on 3/4/25.
//

import Foundation

protocol BodyPoseDetectorProtocol {
    func getBodyPoseFrames(url: URL, progressHandler: (Double) -> Void) async throws -> [BodyPoseFrame]
}
