//
//  LibraryView.swift
//  Coach
//
//  Created by Allen Liang on 11/17/24.
//

import SwiftUI
import PhotosUI
import SwiftData


struct LibraryView: View {
    enum LibraryViewState {
        case selecting
        case normal
    }
    
    
    @StateObject var libraryVM: LibraryViewModel
    @State var selectedVideo: LocalVideoDTO?
    @State var libraryState: LibraryViewState = .normal
    @State var selectedVideos: Set<LocalVideoDTO> = []
    
    init() {
        let detectorLogger = OSLogProvider(category: "AppleBodyPoseDetector")
        let libraryViewModelLogger = OSLogProvider(category: "LibraryViewModel")
        self._libraryVM = .init(
            wrappedValue: .init(
                localVideoService: LocalVideoService(),
                bodyPoseDetector: AppleBodyPoseDetector(logger: detectorLogger),
                golfSwingDetector: GolfSwingDetector(logger: OSLogProvider(category: "GolfSwingDetector")),
                logger: libraryViewModelLogger)
        )
    }
    
    func navigationTitle() -> String {
        switch libraryState {
        case .selecting:
            return "Select"
        case .normal:
            return "Library"
        }
    }
    
    func setLibraryState(state: LibraryViewState) {
        withAnimation(Animation.easeInOut(duration: 0.2)) {
            if state == .normal {
                selectedVideos.removeAll()
            }
            
            libraryState = state
        }
    }
    
    func handleSelecting(video: LocalVideoDTO) {
        if selectedVideos.contains(video) {
            selectedVideos.remove(video)
        } else {
            selectedVideos.insert(video)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { geo in
                    ScrollView(.vertical, showsIndicators: true, content: {
                        
                        VStack {

                            if libraryVM.loadingCount > 0 {
                                VStack {
                                    ProgressView()
                                    Text("loading \(libraryVM.loadingCount) videos...")
                                    Text("\(libraryVM.currentVideoProgress)%")
                                }
                            }

                            
                        }
                        
                        TwoColumnFlowLayout {
                            ForEach(libraryVM.localVideos) { video in
                                LibraryVideoItemView(video: video, isSelected: selectedVideos.contains(video))
                                    .onTapGesture {
                                        switch libraryState {
                                        case .selecting:
                                            handleSelecting(video: video)
                                        case .normal:
                                            selectedVideo = video
                                        }
                                    }
                            }
                        }
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle(navigationTitle())
                    .toolbar {
                        switch libraryState {
                        case .selecting:
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Cancel") {
                                    setLibraryState(state: .normal)
                                }
                            }
                            
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Select All") {
                                    for video in libraryVM.localVideos {
                                        selectedVideos.insert(video)
                                    }
                                }
                            }
                            
                            
                        case .normal:
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Select") {
                                    setLibraryState(state: .selecting)
                                }
                            }
                            
                            ToolbarItem(placement: .topBarTrailing) {
                                PhotosPicker(selection: $libraryVM.importSelection, matching: .videos, photoLibrary: .shared()) {
                                    Text("Import")
                                }
                            }
                            
                            ToolbarItem(placement: .topBarTrailing) {
                                PhotosPicker(selection: $libraryVM.golfImportSelection, matching: .videos, photoLibrary: .shared()) {
                                    Text("Import ⛳️")
                                }
                            }
                        }
                    }
                    .fullScreenCover(item: $selectedVideo) { localVideo in
                        AnalysisContainerView(video: localVideo)
                    }
                }

                
                // selection bar
                
                VStack {
                    Spacer()
                    
                    
                    HStack {
                        Rectangle()
                            .fill(.black.opacity(0.1))
                            .background(.ultraThinMaterial)
                            .frame(height: selectionBarHeight())
                            
                            .overlay {
                                VStack {
                                    ZStack {
                                        HStack {
                                            Text("\(selectedVideos.count) selected")
                                                .foregroundStyle(.white)
                                                .bold()
                                        }
                                        
                                        HStack {
                                            Spacer()
                                            
                                            Button {
                                                for video in selectedVideos {
                                                    libraryVM.deleteLocalVideo(video)
                                                }
                                                setLibraryState(state: .normal)
                                            } label: {
                                                Image(systemName: "trash")
                                                    .resizable()
                                                    .frame(width: 24, height: 24)
                                            }
                                            
                                            .padding(.horizontal, 16)
                                            
                                        }
                                    }
                                    .padding(.top, 16)
                                    
                                    Spacer()
                                }
                            }
                            .clipped()
                    }
                }
                .ignoresSafeArea()
            }
            
                
        }
    }
    
    func selectionBarHeight() -> CGFloat {
        switch libraryState {
        case .selecting:
            return 80
        case .normal:
            return 0
        }
    }
}

#Preview {
   
//     for mocking
//    LibraryView(modelContext: ModelContext(try! ModelContainer(for: LocalVideo.self)), videos: Mocks.videos)
    LibraryView()
}






