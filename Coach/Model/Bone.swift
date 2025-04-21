//
//  Bone.swift
//  Coach
//
//  Created by Allen Liang on 12/20/24.
//

import Foundation

struct Bone: Identifiable {
    let id = UUID()
    let start:  VNRecognizedPointWrapper
    let end:  VNRecognizedPointWrapper
    
    init(start: VNRecognizedPointWrapper, end: VNRecognizedPointWrapper) {
        self.start = start
        self.end = end
    }
}
