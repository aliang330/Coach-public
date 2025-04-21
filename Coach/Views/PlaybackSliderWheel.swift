//
//  PlaybackSliderWheel.swift
//  Coach
//
//  Created by Allen Liang on 10/7/24.
//

import SwiftUI


struct PlaybackSliderWheel: View {
    @State private var rotate2: CGFloat = 0
    @State private var position: ScrollPosition = ScrollPosition(edge: .leading)
    let length: Int = 2000
    let tickSpacing: CGFloat = 24
    let tickWidth: CGFloat = 4
    let tickHeight: CGFloat = 36
    @State private var xOffset = CGFloat(2000/2*40)
    let stepBackward: () -> Void
    let stepForward: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: tickSpacing) {
                        ForEach(0..<length) { i in
                            if i % 2 == 0 {
                                Capsule()
                                    .fill(Color(#colorLiteral(red: 0.9601849914, green: 0.9601849914, blue: 0.9601849914, alpha: 1)))
                                    .opacity(0.5)
                                    .frame(width: tickWidth)
                            } else {
                                Capsule()
                                    .fill(Color(#colorLiteral(red: 0.7215686275, green: 0.7333333333, blue: 0.7098039216, alpha: 1)))
                                    .opacity(0.5)
                                    .frame(width: tickWidth)
                                    .padding(.vertical, tickHeight/5)
                                
                            }
                        }
                    }
                }
                .frame(height: tickHeight)
                .scrollPosition($position)
                .onScrollGeometryChange(for: CGFloat.self, of: { geo in
                    geo.contentOffset.x
                }, action: { oldValue, newValue in
                    if newValue == 0 {
                        return
                    }
                    let delta = newValue - xOffset
                    if abs(delta) > (tickSpacing + tickWidth) {
                        let numSteps = Int(delta / (tickSpacing + tickWidth))
                        if numSteps < 0 {
                            for _ in 0..<abs(numSteps) {
                                stepBackward()
                            }
                        } else {
                            for _ in 0..<numSteps {
                                stepForward()
                            }
                        }
                        
                        xOffset = newValue
                    }
                    
                })
                .onAppear() {
                    position.scrollTo(x: CGFloat(length/2)*(tickSpacing+tickWidth))
                }
            }
        }
        .frame(height: 48)
    }
}

#Preview {
    PlaybackSliderWheel(stepBackward: {}, stepForward: {})
}
