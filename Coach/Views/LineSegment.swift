//
//  LineSegment.swift
//  Coach
//
//  Created by Allen Liang on 12/16/24.
//

import SwiftUI

struct LineSegment: Shape {
    var startPoint: CGPoint
    var endPoint: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: startPoint) // Start of the line
        path.addLine(to: endPoint) // End of the line
        return path
    }
}

#Preview {
    LineSegment(startPoint: .zero, endPoint: .zero)
}
