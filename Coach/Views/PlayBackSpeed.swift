//
//  PlayBackSpeed.swift
//  Coach
//
//  Created by Allen Liang on 11/21/24.
//

import SwiftUI

struct PlayBackSpeed: View {
    
    let playbackSpeedTapped: (Double) -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text("0.125x")
                    .onTapGesture {
                        playbackSpeedTapped(0.125)
                    }
                Divider()
                Text("0.25x")
                    .onTapGesture {
                        playbackSpeedTapped(0.25)
                    }
                Divider()
                Text("0.5x")
                    .onTapGesture {
                        playbackSpeedTapped(0.5)
                    }
                Divider()
                Text("1x")
                    .onTapGesture {
                        playbackSpeedTapped(1.0)
                    }
                Divider()
                Text("1.5x")
                    .onTapGesture {
                        playbackSpeedTapped(1.5)
                    }
                Divider()
                Text("2x")
                    .onTapGesture {
                        playbackSpeedTapped(2.0)
                    }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.black.opacity(0.7))
                    
            )
            
            
        }
    }
}

#Preview {
    PlayBackSpeed(playbackSpeedTapped: { _ in })
}
