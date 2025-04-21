//
//  VideoPlayer.swift
//  Coach
//
//  Created by Allen Liang on 10/5/24.
//

import SwiftUI
import PhotosUI
import AVKit
import Vision


struct ALVideoPlayer: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection: PhotosPickerItem? = nil
    @State private var sliderIsEditing = false
    @ObservedObject private var viewModel: ALViewPlayerViewModel
    @State private var showPlaybackSpeedMenu = false
    @Binding private var showOverlay: Bool
    var playbackUIOffset = ALEdgeOffset(top: 0, bottom: 16, leading: 8, trailing: 8)
    
    init(viewModel: ALViewPlayerViewModel, showOverlay: Binding<Bool>, playbackUIOffsetOverride: ALEdgeOffset? = nil) {
        self.viewModel = viewModel
        self._showOverlay = showOverlay
        self.playbackUIOffset = playbackUIOffset.override(override: playbackUIOffsetOverride)
        
    }
    
    
    
    // for overlaying body pose points
    @State var videoRect: CGRect = .zero
        
    var body: some View {
        ZStack {
            VStack {
                ALVideoPlayerView(avPlayer: viewModel.player, didUpdateVideoRect: { videoRect in
                    self.videoRect = videoRect
                })
                .overlay {
                    BonesOverlay
                }
                .overlay {
                    JointsOverlay
                }
                .addPinchZoom()
                .ignoresSafeArea()
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            PlaybackControlOverlay
                .opacity(showOverlay ? 1.0 : 0.0)
            
        }
    }
    
    @ViewBuilder
    var BonesOverlay: some View {
        if viewModel.showPose {
            ForEach(viewModel.bones) { bone in
                let x1 = bone.start.x
                let y1 = 1.0 - bone.start.y
                let x2 = bone.end.x
                let y2 = 1.0 - bone.end.y
                
                let start = CGPoint(x: videoRect.width * x1, y: videoRect.height * y1 + videoRect.minY)
                let end = CGPoint(x: videoRect.width * x2, y: videoRect.height * y2 + videoRect.minY)
                LineSegment(startPoint: start, endPoint: end)
                    .stroke(Color.red, lineWidth: 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    @ViewBuilder
    var JointsOverlay: some View {
        if viewModel.showPose {
            ForEach(viewModel.jointsOfInterest, id: \.self) { joint in
                if let vnPoint = viewModel.currentJoints[joint] {
                    if vnPoint.confidence > 0.6 {
                        let y = 1.0 - vnPoint.y
                        let x = vnPoint.x
                        Circle()
                            .fill(viewModel.leftJoints.contains(joint) ? .blue : .red)
                            .frame(width: 4, height: 4)
                            .position(x: videoRect.width * x, y: videoRect.height * y + videoRect.minY)
                    }
                }
            }
        }
    }
    
    var PlaybackControlOverlay: some View {
        VStack {
            Spacer()
            
            Text(String(format: "%.3f", viewModel.currentTime))
                .font(.body)
                .foregroundStyle(.green)
            
            VStack(spacing: 0) {
                if showPlaybackSpeedMenu {
                    PlayBackSpeed { speed in
                        viewModel.updatePlaybackSpeed(to: speed)
                    }
                }
                
                Slider(value: $viewModel.currentTime, in: 0...viewModel.duration) { editingStarted in
                    if viewModel.playerStatus == .playing {
                        viewModel.pause()
                    }
                    if !editingStarted {
                        sliderIsEditing = false
                    } else {
                        sliderIsEditing = true
                    }
                }
                .onChange(of: viewModel.currentTime) {
                    if sliderIsEditing {
                        let seekTime = CMTime(seconds: viewModel.currentTime, preferredTimescale: 600)
                        viewModel.seek(to: seekTime)
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
                    .frame(height: 4)
                
                PlaybackSliderWheel(stepBackward: {
                    viewModel.stepFrame(isForward: false)
                }, stepForward: {
                    viewModel.stepFrame(isForward: true)
                })
                
                PlayBackUI
                    .edgeOffset(playbackUIOffset)
            }
            .background(.black.opacity(viewModel.playerStatus == .playing ? 0 : OverlayConstants.opacity))
            
            
        }
    }
    
    
    @ViewBuilder
    var PlayBackUI: some View {
        let buttonSize: CGFloat = 24
        
        
        ZStack {
            HStack(spacing: 36) {
                Button {
                    viewModel.seekToBeginning()
                } label: {
                    Image(systemName: "backward.frame.fill")
                        .resizable()
                        .frame(width: buttonSize, height: buttonSize)
                }
                .buttonStyle(.plain)
                .opacity(viewModel.playerStatus == .playing ? 0 : 1)
                
                
                if viewModel.playerStatus == .playing {
                    Button {
                        viewModel.pause()
                    } label: {
                        Image(systemName: "pause.fill")
                            .resizable()
                            .frame(width: buttonSize, height: buttonSize)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        viewModel.play()
                    } label: {
                        Image(systemName: "play.fill")
                            .resizable()
                            .frame(width: buttonSize, height: buttonSize)
                    }
                    .buttonStyle(.plain)
                }
                    
                Button {
                    viewModel.seekToEnd()
                } label: {
                    Image(systemName: "forward.frame.fill")
                        .resizable()
                        .frame(width: buttonSize, height: buttonSize)
                }
                .buttonStyle(.plain)
                .opacity(viewModel.playerStatus == .playing ? 0 : 1)
            }
            
            HStack(spacing: 16) {
                Text(String(format: "%.2f", viewModel.playbackSpeed))
                    .frame(height: buttonSize)
                
                Image(systemName: "repeat")
                    .resizable()
                    .frame(width: buttonSize, height: buttonSize)
                    .onTapGesture {
                        showPlaybackSpeedMenu.toggle()
                    }
                
                Spacer()
            }
        }
    }
}

#Preview {
    // TODO: 
//    ALVideoPlayer(viewModel: ALViewPlayerViewModel(localVideo: Mocks.video), showOverlay: .constant(true))
}



struct ALVideoPlayerView: UIViewRepresentable {
    let avPlayer: AVPlayer?
    let didUpdateVideoRect: (CGRect) -> Void
    
    
    func makeUIView(context: Context) -> ALPlayerUIView {
        ALPlayerUIView(avPlayer: avPlayer, didUpdateVideoRect: didUpdateVideoRect)
    }
    
    func updateUIView(_ uiView: ALPlayerUIView, context: Context) {
        //
    }
}

class ALPlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    let didUpdateVideoRect: (CGRect) -> Void
    
    init(avPlayer: AVPlayer?,didUpdateVideoRect: @escaping (CGRect) -> Void) {
        self.didUpdateVideoRect = didUpdateVideoRect
        super.init(frame: .zero)
        playerLayer.player = avPlayer
        layer.addSublayer(playerLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
        // observe when avplayer item is .readyToPlay, that might be when videoRect gets set
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print(self.playerLayer.videoRect)
            self.didUpdateVideoRect(self.playerLayer.videoRect)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}



//struct DualView: View {
//    var body: some View {
//        VStack {
//            VStack {
//                ALVideoPlayer()
//            }
//            .clipped()
//            
//            VStack {
//                ALVideoPlayer()
//            }
//            .clipped()
//        }
//    }
//}
