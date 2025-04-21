//
//  TwoColumnFlowLayout.swift
//  Coach
//
//  Created by Allen Liang on 1/17/25.
//

import SwiftUI

struct TwoColumnFlowLayout: Layout {
    let spacing: CGFloat = 4
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let itemHeight: CGFloat = ((proposal.width ?? 0) - (spacing * 3)) / 2 + spacing
        let height: CGFloat = itemHeight * CGFloat(subviews.count / 2) - spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let spacing: CGFloat = 4
        let width = bounds.width / 2 - (1.5 * spacing)
        var j = 0
        let sizeProposal = ProposedViewSize(width: width, height: width)
        var x = bounds.minX + width / 2 + spacing
        var y = bounds.minY + width / 2
        
        for i in subviews.indices {
            subviews[i].place(at: CGPoint(x: x, y: y), anchor: .center, proposal: sizeProposal)
            if j == 1 {
                j = 0
                y += width + spacing
                x = bounds.minX + width / 2 + spacing
            } else {
                x += width + spacing
                j += 1
            }
        }
    }
}


#Preview {
    VStack {
        TwoColumnFlowLayout {
            ForEach(0..<5) { _ in
                Rectangle()
            }
        }
        
        Spacer()
    }
}
