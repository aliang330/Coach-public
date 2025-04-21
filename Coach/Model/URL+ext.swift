//
//  URL+ext.swift
//  Coach
//
//  Created by Allen Liang on 12/20/24.
//

import Foundation

extension URL {
    static func videoURL(videoPath: String) -> URL {
        return URL.documentsDirectory.appending(path: videoPath)
    }
}
