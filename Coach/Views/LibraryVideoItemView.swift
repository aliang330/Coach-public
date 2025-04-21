//
//  LibraryVideoItemView.swift
//  Coach
//
//  Created by Allen Liang on 1/17/25.
//

import SwiftUI

struct LibraryVideoItemView: View {
    let video: LocalVideoDTO
    let isSelected: Bool
    
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
                    .overlay(content: {
                        if isSelected {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    SelectedCheckCircle()
                                        .frame(width: 30, height: 30)
                                        .padding(.trailing, 4)
                                        .padding(.bottom, 4)
                                }
                            }
                            .background(.black.opacity(OverlayConstants.selectItemOpacity))
                        }
                    })
            }
        }
        .clipped()
        .contentShape(Rectangle())
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

#Preview {
    // TODO:
//    LibraryVideoItemView(video: Mocks.video, isSelected: false)
}
