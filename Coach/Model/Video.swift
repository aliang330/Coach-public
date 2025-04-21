//
//  Video.swift
//  Coach
//
//  Created by Allen Liang on 1/20/25.
//

import SwiftUI


struct Video: Transferable {
    let url: URL
    let path: String
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            return SentTransferredFile(movie.url)
        } importing: { received in
            do {
                let videoName = FileDirectoryConst.generateRandomVideoName()
                let path = "videos/\(videoName)"
                
                let videosFolder = FileDirectoryConst.videosDirectory
                try! FileManager.createPathIfNotExist(url: videosFolder)
                let destinationURL = videosFolder.appending(path: videoName)
                            
                if FileManager.default.fileExists(atPath: destinationURL.path()) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.copyItem(at: received.file, to: destinationURL)
                return Self.init(url: destinationURL, path: path)
            } catch {
                print(error)
            }
            fatalError()
            
        }

    }
}

struct FileDirectoryConst {
    static let videosDirectory = URL.documentsDirectory.appending(path: "videos")
    
    static func generateRandomVideoName() -> String {
        return "\(UUID().uuidString).mp4"
    }
}
