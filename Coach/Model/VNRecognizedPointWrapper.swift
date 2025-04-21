//
//  VNRecognizedPointWrapper.swift
//  Coach
//
//  Created by Allen Liang on 12/20/24.
//

import Foundation
import Vision

// wrapper because couldn't make VNRecognizedPoint Codable due to it being a class and not final
struct VNRecognizedPointWrapper: Codable, Equatable {
    let location: CGPoint
    let confidence: Float
    var x: CGFloat {
        return location.x
    }
    var y: CGFloat {
        return location.y
    }
    
    init(location: CGPoint, confidence: Float) {
        self.location = location
        self.confidence = confidence
    }
    
    // Initialize from VNRecognizedPoint
    init(vnPoint: VNRecognizedPoint) {
        self.location = vnPoint.location
        self.confidence = vnPoint.confidence
    }
}
