//
//  CompareLibraryView.swift
//  Coach
//
//  Created by Allen Liang on 12/6/24.
//

import SwiftUI
import SwiftData

struct CompareLibraryView: View {
    @StateObject var viewModel = CompareLibraryViewModel()
    @State var selectedVideo: LocalVideoDTO?
    var didSelect: ((LocalVideoDTO) -> Void)
    
    init(didSelect: @escaping ((LocalVideoDTO) -> Void)) {
        self.didSelect = didSelect
    }
    
    var body: some View {
        VStack {
            ScrollView {
                TwoColumnFlowLayout {
                    ForEach(viewModel.localVideos) { video in
                        CompareLibraryVideoItem(video: video)
                            .onTapGesture {
                                didSelect(video)
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
    }
}

#Preview {
    CompareLibraryView(didSelect: {_ in })
}

struct CompareLibraryVideoItem: View {
    let video: LocalVideoDTO
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height
                ThumbnailImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: width > 0 ? width : 0, height: height > 0 ? height: 0)
                    .overlay {
                        VStack {
                            Spacer()
                            Text(Utility.timeString(from: video.duration))
                                .foregroundStyle(.white)
                            Text(Utility.formattedDateString(from: video.dateAdded))
                                .foregroundStyle(.white)
                        }
                    }
                
            }
        }
        .clipped()
    }
    
    var ThumbnailImage: Image {
        /// if thumbnailData is nil or fails to initilize a UIImage return a placeholder image
        if let thumbnailData = video.thumbnailData {
            if let uiimage = UIImage(data: thumbnailData) {
                return Image(uiImage: uiimage)
            } else {
                return Image(systemName: "photo")
            }
        } else {
            return Image(systemName: "photo")
        }
    }
}

class CompareLibraryViewModel: ObservableObject {
    let localVideoService: LocalVideoService
    @Published var localVideos: [LocalVideoDTO] = []
    
    init() {
        self.localVideoService = LocalVideoService()
    }
    
    func fetchVideos() {
        do {
//            localVideos = try localVideoService.fetchLocalVideos()
        } catch {
            print(error)
            // TODO:
        }
    }
}

