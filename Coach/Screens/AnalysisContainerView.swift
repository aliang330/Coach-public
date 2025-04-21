//
//  AnalysisContainerView.swift
//  Coach
//
//  Created by Allen Liang on 12/6/24.
//

import SwiftUI

struct OverlayConstants {
    static let opacity = 0.6
    static let selectItemOpacity = 0.2
}

class AnalysisContainerViewModel: ObservableObject {
    @Published var videoPlayerViewModel1: ALViewPlayerViewModel
    @Published var videoPlayerViewModel2: ALViewPlayerViewModel?
    
    init(localVideo: LocalVideoDTO) {
        videoPlayerViewModel1 = ALViewPlayerViewModel(localVideo: localVideo)
    }
}

struct AnalysisContainerView: View {
    enum AnalysisContainerViewState {
        case oneVideo
        case compare
        case twoVideo
    }
    
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: AnalysisContainerViewModel
    @State var state: AnalysisContainerViewState = .oneVideo
    @State var video1: LocalVideoDTO
    @State var video2: LocalVideoDTO?
    @State var showLibrary: Bool = false
    @State var showOverlay = true
    @State var showNavBar = true
    @State var showPose = false
    
    init(video: LocalVideoDTO) {
        self._viewModel = StateObject(wrappedValue: AnalysisContainerViewModel(localVideo: video))
        self.video1 = video
    }
    
    func setState(_ state: AnalysisContainerViewState) {
        self.state = state
        switch state {
        case .oneVideo:
            showOverlay = true
            showNavBar = true
        case .twoVideo:
            showOverlay = true
            showNavBar = true
        case .compare:
            showOverlay = false
            showNavBar = true
        }
    }
    
    func close() {
        AppDelegate.setOrientation(.portrait)
        viewModel.videoPlayerViewModel1.shutdown()
        dismiss()
    }
    
    @ViewBuilder
    var NavigationBar: some View {
        switch state {
            case .oneVideo:
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: 16)
                    
                    Button {
                        close()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                    }
                    
                    Spacer()
                        .frame(width: 20)
                    
                    Button {
                        setState(.compare)
                    } label: {
                        Text("Compare")
                            .foregroundStyle(.white)
                            .bold()
                    }
                    
                    Spacer()
                        .frame(width: 32)
                    
                    Button {
                        viewModel.videoPlayerViewModel1.showPose.toggle()
                        showPose = viewModel.videoPlayerViewModel1.showPose
                    } label: {
                        Text("Pose")
                            .foregroundStyle(.white)
                            .bold()
                    }
                    .background(showPose ? Color.yellow : Color.clear)
                    
                    Spacer()
                    
                    Button {
                        AppDelegate.flipOrientation()
                    } label: {
                        Text("flip")
                            .foregroundStyle(.white)
                            .bold()
                    }
                    
                    
                    
                    Button {
                        viewModel.videoPlayerViewModel1.downloadVideo()
                    } label: {
                        Text("download")
                    }
                    
                    Spacer()
                        .frame(width: 16)
                    
                }
                .padding(.vertical, 16)
                .background(.black.opacity(OverlayConstants.opacity))
                
                Spacer()
            }
        case .compare:
            VStack {
                HStack {
                    Spacer()
                    
                    Button("Cancel") {
                        setState(.oneVideo)
                    }
                    .padding(.trailing, 16)
                }
                .frame(height: 60)
                .background(.black.opacity(OverlayConstants.opacity))
                
                Spacer()
            }
        case .twoVideo:
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: 16)
                    
                    Button {
                        close()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                    }
                    
                    Spacer()
                        .frame(width: 32)
                    
                    Button {
                        viewModel.videoPlayerViewModel1.showPose.toggle()
                        showPose = viewModel.videoPlayerViewModel1.showPose
                        viewModel.videoPlayerViewModel2?.showPose = showPose
                    } label: {
                        Text("Pose")
                            .foregroundStyle(.white)
                            .bold()
                    }
                    .background(showPose ? Color.yellow : Color.clear)
                    
                    
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(.black.opacity(OverlayConstants.opacity))
                
                Spacer()
            }
        }
        
    }
    
    var body: some View {
        ZStack {
            
            NavigationBar
                .zIndex(1)
                .opacity(showNavBar ? 1 : 0)
            HStack(spacing: 4) {
                VStack(spacing: 4) {
                    if video2 != nil && AppDelegate.orientationLock == .portrait {
                        // video2 portrait
                        if let videoPlayerVMUnwarpped = viewModel.videoPlayerViewModel2 {
                            VStack {
                                ALVideoPlayer(viewModel: viewModel.videoPlayerViewModel2!, showOverlay: $showOverlay, playbackUIOffsetOverride: ALEdgeOffset(bottom: 16))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .contentShape(Rectangle())
                        }
                    }
                    
                    if state == .compare && AppDelegate.orientationLock == .portrait {
                        VStack {
                            Button("Add") {
                                showLibrary = true
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    
                    // video 1
                    VStack {
                        ALVideoPlayer(viewModel: viewModel.videoPlayerViewModel1, showOverlay: $showOverlay, playbackUIOffsetOverride: ALEdgeOffset(bottom: 32))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .contentShape(Rectangle())
                }
                
                if state == .compare && AppDelegate.orientationLock == .landscapeRight {
                    VStack {
                        Button("Add") {
                            showLibrary = true
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                if video2 != nil && AppDelegate.orientationLock == .landscapeRight {
                    // video2 landscape
                    VStack {
                        ALVideoPlayer(viewModel: viewModel.videoPlayerViewModel2!, showOverlay: $showOverlay, playbackUIOffsetOverride: ALEdgeOffset(bottom: 32))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .contentShape(Rectangle())
                }

            }
            .contentShape(Rectangle())
            .onTapGesture {
                if state == .compare {
                    return
                }
                
                showOverlay.toggle()
                showNavBar = showOverlay
            }
            .ignoresSafeArea()
                        
        }
        .sheet(isPresented: $showLibrary) {
            CompareLibraryView(
                didSelect: { secondVideo in
                    video2 = secondVideo
                    viewModel.videoPlayerViewModel2 = ALViewPlayerViewModel(localVideo: secondVideo)
                    setState(.twoVideo)
                    showLibrary = false
                }
            )
        }
    }
}

#Preview {
    // TODO:
//    AnalysisContainerView(video: Mocks.video)
}
