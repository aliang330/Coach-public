//
//  GolfBallTracker.swift
//  Coach
//
//  Created by Allen Liang on 3/11/25.
//

import SwiftUI
import Vision
import Accelerate
import AVFoundation
import SwiftImage


class AVAssetReaderVideoFrameProvider: VideoFrameProvider {
    let avAsset: AVURLAsset
    let assetReader: AVAssetReader
    let trackOutput: AVAssetReaderTrackOutput
    let videoTransform: CGAffineTransform
    
    init(avAseet: AVURLAsset) async throws {
        self.avAsset = avAseet
        let videoTrack = try await avAsset.loadTracks(withMediaType: .video).first!
        self.videoTransform = try await videoTrack.load(.preferredTransform).inverted()
        self.assetReader = try AVAssetReader(asset: avAsset)
        let outputSettings: [String: Any] = [
            (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        self.trackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
        assetReader.add(trackOutput)
        assetReader.startReading()
    }
    
    
    func copyNextFrame() -> VideoFrame? {
        if let sampleBuffer = trackOutput.copyNextSampleBuffer() {
            let cgImage = ImageProcessingTool.createCGImage(from: sampleBuffer, transform: videoTransform)!
            return VideoFrame(timeStamp: sampleBuffer.presentationTimeStamp, image: cgImage)
        } else {
            return nil
        }
    }
}


class LocalVideoFrameProvider: VideoFrameProvider {
    let golfSwingFrameFileNames = [
        "golfswing000000.jpg", "golfswing000001.jpg", "golfswing000002.jpg", "golfswing000003.jpg",
        "golfswing000004.jpg", "golfswing000005.jpg", "golfswing000006.jpg", "golfswing000007.jpg",
        "golfswing000008.jpg", "golfswing000009.jpg", "golfswing000010.jpg", "golfswing000011.jpg",
        "golfswing000012.jpg", "golfswing000013.jpg", "golfswing000014.jpg", "golfswing000015.jpg",
        "golfswing000016.jpg", "golfswing000017.jpg", "golfswing000018.jpg", "golfswing000019.jpg",
        "golfswing000020.jpg", "golfswing000021.jpg", "golfswing000022.jpg", "golfswing000023.jpg",
        "golfswing000024.jpg", "golfswing000025.jpg", "golfswing000026.jpg", "golfswing000027.jpg",
        "golfswing000028.jpg", "golfswing000029.jpg", "golfswing000030.jpg", "golfswing000031.jpg",
        "golfswing000032.jpg", "golfswing000033.jpg", "golfswing000034.jpg", "golfswing000035.jpg",
        "golfswing000036.jpg", "golfswing000037.jpg", "golfswing000038.jpg", "golfswing000039.jpg",
        "golfswing000040.jpg", "golfswing000041.jpg", "golfswing000042.jpg", "golfswing000043.jpg",
        "golfswing000044.jpg", "golfswing000045.jpg", "golfswing000046.jpg", "golfswing000047.jpg",
        "golfswing000048.jpg", "golfswing000049.jpg", "golfswing000050.jpg", "golfswing000051.jpg",
        "golfswing000052.jpg", "golfswing000053.jpg", "golfswing000054.jpg", "golfswing000055.jpg",
        "golfswing000056.jpg", "golfswing000057.jpg", "golfswing000058.jpg", "golfswing000059.jpg",
        "golfswing000060.jpg", "golfswing000061.jpg", "golfswing000062.jpg", "golfswing000063.jpg",
        "golfswing000064.jpg", "golfswing000065.jpg", "golfswing000066.jpg", "golfswing000067.jpg",
        "golfswing000068.jpg", "golfswing000069.jpg", "golfswing000070.jpg", "golfswing000071.jpg",
        "golfswing000072.jpg", "golfswing000073.jpg", "golfswing000074.jpg", "golfswing000075.jpg",
        "golfswing000076.jpg", "golfswing000077.jpg", "golfswing000078.jpg", "golfswing000079.jpg",
        "golfswing000080.jpg", "golfswing000081.jpg", "golfswing000082.jpg", "golfswing000083.jpg",
        "golfswing000084.jpg", "golfswing000085.jpg", "golfswing000086.jpg", "golfswing000087.jpg",
        "golfswing000088.jpg", "golfswing000089.jpg", "golfswing000090.jpg", "golfswing000091.jpg",
        "golfswing000092.jpg", "golfswing000093.jpg", "golfswing000094.jpg", "golfswing000095.jpg",
        "golfswing000096.jpg", "golfswing000097.jpg", "golfswing000098.jpg", "golfswing000099.jpg",
        "golfswing000100.jpg", "golfswing000101.jpg", "golfswing000102.jpg", "golfswing000103.jpg",
        "golfswing000104.jpg", "golfswing000105.jpg", "golfswing000106.jpg", "golfswing000107.jpg",
        "golfswing000108.jpg", "golfswing000109.jpg", "golfswing000110.jpg", "golfswing000111.jpg",
        "golfswing000112.jpg", "golfswing000113.jpg", "golfswing000114.jpg", "golfswing000115.jpg",
        "golfswing000116.jpg", "golfswing000117.jpg", "golfswing000118.jpg", "golfswing000119.jpg",
        "golfswing000120.jpg", "golfswing000121.jpg", "golfswing000122.jpg", "golfswing000123.jpg",
        "golfswing000124.jpg", "golfswing000125.jpg", "golfswing000126.jpg", "golfswing000127.jpg",
        "golfswing000128.jpg", "golfswing000129.jpg", "golfswing000130.jpg", "golfswing000131.jpg",
        "golfswing000132.jpg"
    ]
    /// detected ball positions from `golfSwingFrameFileNames` images
    /// normailzed with bottom left origin.
    let detectedBallPositions: [CGPoint] = [
        CGPoint(x: 0.6295703798532486, y: 0.3074567038565874),
        CGPoint(x: 0.6439814814814815, y: 0.3890625),
        CGPoint(x: 0.6569444444444444, y: 0.5143229166666666),
        CGPoint(x: 0.6652777777777777, y: 0.5859375),
        CGPoint(x: 0.6717592592592593, y: 0.63515625),
        CGPoint(x: 0.6722222222222223, y: 0.6348958333333333),
        CGPoint(x: 0.6828703703703703, y: 0.6966145833333334),
        CGPoint(x: 0.6824074074074075, y: 0.696875),
        CGPoint(x: 0.6907407407407408, y: 0.7348958333333333),
        CGPoint(x: 0.6907407407407408, y: 0.7348958333333333),
        CGPoint(x: 0.6976851851851852, y: 0.7619791666666667),
        CGPoint(x: 0.700925925925926, y: 0.77265625),
        CGPoint(x: 0.7041666666666667, y: 0.7825520833333334),
        CGPoint(x: 0.7041666666666667, y: 0.7825520833333334)
    ]
    
    init() {
        
    }
    
    private var curFrameIndex = 58
    
    func copyNextFrame() -> VideoFrame? {
        if curFrameIndex < 0 || curFrameIndex >= golfSwingFrameFileNames.count {
            return nil
        }
        let uiImage = UIImage(named: golfSwingFrameFileNames[curFrameIndex])!
        curFrameIndex += 1
        return VideoFrame(timeStamp: .zero, image: uiImage.cgImage!)
    }
}

protocol VideoFrameProvider {
    func copyNextFrame() -> VideoFrame?
}

struct VideoFrame {
    let timeStamp: CMTime
    let image: CGImage
    
    init(timeStamp: CMTime, image: CGImage) {
        self.timeStamp = timeStamp
        self.image = image
    }
}


struct TrackedGolfBallPostion {
    let timeStamp: CMTime
    let position: CGPoint
}

struct VideoGolfBallTrackerData {
    let ballPostions: [TrackedGolfBallPostion]
}

class GolfBallTracker: ObservableObject {
    private let logger: LoggerProvider? = OSLogProvider(category: "GolfBallFlightTracker")
//    let videoURL: URL
//    let detectedSwings: [DetectedGolfSwing]
//    let golfSwingTimeRanges: [CMTimeRange]
    
    @Published var curImage: UIImage? = nil
    @Published var curLabel: String = ""
    
    private var ballStateVector: [CGFloat] = [0,0,0,0] // [x,y,dx,dy] normalized with bottom left origin
    private var initialBallPosition: CGRect? = nil
    private var lastImage: CGImage?
    private var framesSinceLastBall: Int = 1
    private var foundInitialBallMovement: Bool = false
    private var ballPositions: [CGPoint] = []
    
    var videoFrameProvider: VideoFrameProvider
    
//    init(videoURL: URL, detectedSwings: [DetectedGolfSwing]) {
//        self.videoURL = videoURL
//        self.detectedSwings = detectedSwings
//        self.golfSwingTimeRanges = detectedSwings.map { CMTimeRange(start: $0.backSwingFrame.time, end: $0.nextSwingFrame.time) }
//    }
    
    init(videoFrameProvider: VideoFrameProvider) {
        self.videoFrameProvider = videoFrameProvider
    }
    
    let testGolfPositionPoints: [CGPoint] = [
        CGPoint(x: 0.6295703798532486, y: 0.3074567038565874),
        CGPoint(x: 0.6439814814814815, y: 0.3890625),
        CGPoint(x: 0.6569444444444444, y: 0.5143229166666666),
        CGPoint(x: 0.6652777777777777, y: 0.5859375),
        CGPoint(x: 0.6717592592592593, y: 0.63515625),
        CGPoint(x: 0.6722222222222223, y: 0.6348958333333333),
        CGPoint(x: 0.6828703703703703, y: 0.6966145833333334),
        CGPoint(x: 0.6824074074074075, y: 0.696875),
        CGPoint(x: 0.6907407407407408, y: 0.7348958333333333),
        CGPoint(x: 0.6907407407407408, y: 0.7348958333333333),
        CGPoint(x: 0.6976851851851852, y: 0.7619791666666667),
        CGPoint(x: 0.700925925925926, y: 0.77265625),
        CGPoint(x: 0.7041666666666667, y: 0.7825520833333334),
        CGPoint(x: 0.7041666666666667, y: 0.7825520833333334)
    ]
    
    private func setCurImage(label: String, image: CGImage, delay: Int = 1) {
        DispatchQueue.main.async {
            self.curImage = UIImage(cgImage: image)
            self.curLabel = label
        }
        sleep(UInt32(delay))
    }
    
    private func setCurImage(label: String, image: UIImage, delay: Int = 1) {
        DispatchQueue.main.async {
            self.curImage = image
            self.curLabel = label
        }
        sleep(UInt32(delay))
    }
    
    func testBallCurve() {
        let frame = videoFrameProvider.copyNextFrame()
        let image = frame?.image
        
        let curveImage = ImageProcessingTool.drawCurve(on: image!, with: testGolfPositionPoints)
        
        setCurImage(label: "ball tracer", image: curveImage!)
    }
    
    /// golf ball tracking algorithm
    /// 1. Finds the golf ball at rest on turf using object detection.
    /// 2. Using the the detected position we can use image subraction to find when the ball is in motion
    /// 3. From there we can look for pixel differences to detect ball in motion and use predicted regions of interest based off
    ///  previous ball positions to narrow down the search and ignore noise.
    func startTracking() async throws {
        while let videoFrame = videoFrameProvider.copyNextFrame() {
            let image = videoFrame.image
            
            setCurImage(label: "currentFrame", image: image) // debug
            
            if lastImage == nil {
                lastImage = image
                continue
            }
            
            if initialBallPosition == nil {
                if let boundBox = await detectInitialGolfBall(cgImage: image) {
                    initialBallPosition = boundBox
                    ballStateVector[0] = boundBox.origin.x
                    ballStateVector[1] = boundBox.origin.y
                    ballStateVector[2] = 0
                    ballStateVector[3] = 0
                    ballPositions.append(boundBox.origin)
                }
                
                lastImage = image
                continue
            } else {
                /// we have init ball position
                await processFrame(cgImage: image)
                lastImage = image
            }
            
            
        }
    }
    
    /// finds position of the next golf ball that is in motion
    private func processFrame(cgImage: CGImage) async {
        guard let lastImage else { return }
        let diffImage = ImageProcessingTool.imageSubtraction(cgImage1: lastImage, cgImage2: cgImage)!
        let diffImageCGImage = diffImage.cgImage!
        let originalImageWidth = diffImageCGImage.width
        let originalImageHeight = diffImageCGImage.height

        setCurImage(label: "diff Image", image: diffImage, delay: 1) // debug
        
        if !foundInitialBallMovement {
            let initBallPositionCroppedImage = createCroppedImage(image: diffImageCGImage, normalizedCGRect: initialBallPosition!)
            
            setCurImage(label: "found initial ball movement", image: initBallPositionCroppedImage, delay: 1) // debug
            
            let detectedBlobs = findBlobs(in: initBallPositionCroppedImage)
            for detectedBlob in detectedBlobs {
                print("finding init ball blob")
                print(detectedBlob.pixels.count)
                if detectedBlob.pixels.count > 1000 { // TODO: hard coded threshold, we can do a percentage of image
                    foundInitialBallMovement = true
                    break
                }
            }
            
            if !foundInitialBallMovement {
                return
            }
        }
        
        /// get search region, inital search region will be broad but will be narrower once we known dx dy
        let (searchRegionImage, searchRegionXOffset, searchRegionYOffset) = createSearchRegionImage(diffImage: diffImage.cgImage!)
        guard let searchRegionImage, let searchRegionXOffset, let searchRegionYOffset else {
            return
        }
        print("region dimensons: \(searchRegionImage.width), \(searchRegionImage.height)")
        setCurImage(label: "search region", image: searchRegionImage, delay: 1)
        
        /// find blobs in the search region
        let searchRegionBlobs = findBlobs(in: searchRegionImage)
        print("detected blobs in search region:")
        printBlobs(blobs: searchRegionBlobs)
        
        let dynamicFilter = max(40, 200 -  (ballPositions.count * 75))
        let searchRegionBlobsFilteredBySize = searchRegionBlobs.filter { $0.pixels.count > dynamicFilter }
        
//        visualize blobs in search region
        for blob in searchRegionBlobsFilteredBySize {
                let image = visualizeBlobOnImage(cgImage: searchRegionImage, blob: blob)
                setCurImage(label: "blob in search: \(blob.pixels.count)", image: image, delay: 1)
                print(blob.centerPoint)
        }
        
        let blobsMappedToOriginalImage = searchRegionBlobsFilteredBySize.map { $0.getBlobMappedToOriginalImage(xOffset: searchRegionXOffset, yOffset: searchRegionYOffset) }
        
        // visualize blobs on original image for debug
//        for blob in blobsMappedToOriginalImage {
//            let image = visualizeBlobOnImage(cgImage: diffImageCGImage, blob: blob)
//            setCurImage(label: "blob: \(blob.pixels.count)", image: image, delay: 1)
//        }
        
        
        /// figure out which blob is the ball from the detected blobs.
        if blobsMappedToOriginalImage.count == 1 {
            /// If there is only one blob we assume that is the ball
            let image = visualizeBlobOnImage(cgImage: diffImageCGImage, blob: blobsMappedToOriginalImage[0])
            setCurImage(label: "detected ball", image: image, delay: 1)
            
            guard let blobPoint = blobsMappedToOriginalImage[0].centerPoint else { fatalError() } // this is top left origin
            
            
            let normalizedBlobPoint = normalizeBlobCenterPoint(point: blobPoint, imageWidth: CGFloat(originalImageWidth), imageHeight: CGFloat(originalImageHeight)) // bottom left origin
            
            // update ball state
            ballPositions.append(normalizedBlobPoint)
            updateBallStateVector(newNormalizedX: normalizedBlobPoint.x, newNormalizedY: normalizedBlobPoint.y)
        } else if blobsMappedToOriginalImage.count == 2 {
            /// if there are two blobs, the assumption is one of them is the previous ball and the one furthest from the prev position is the current ball position.
            
            let blob1CenterPoint = blobsMappedToOriginalImage[0].centerPoint!
            let blob2CenterPoint = blobsMappedToOriginalImage[1].centerPoint!
            let lastX = ballStateVector[0]
            let lastY = ballStateVector[1]
            
            let blob1NormalizedCenterPoint = normalizeBlobCenterPoint(point: blob1CenterPoint, imageWidth: CGFloat(originalImageWidth), imageHeight: CGFloat(originalImageHeight))
            
            let blob2NormalizedCenterPoint = normalizeBlobCenterPoint(point: blob2CenterPoint, imageWidth: CGFloat(originalImageWidth), imageHeight: CGFloat(originalImageHeight))
            
            let blob1Distance = hypot(blob1NormalizedCenterPoint.x - lastX, blob1NormalizedCenterPoint.y - lastY)
            let blob2Distance = hypot(blob2NormalizedCenterPoint.x - lastX, blob2NormalizedCenterPoint.y - lastY)
            
            if blob1Distance > blob2Distance {
                let visualImage = visualizeBlobOnImage(cgImage: diffImageCGImage, blob: blobsMappedToOriginalImage[0])
                setCurImage(label: "two blobs found", image: visualImage, delay: 1)
                
                ballPositions.append(blob1NormalizedCenterPoint)
                updateBallStateVector(newNormalizedX: blob1NormalizedCenterPoint.x, newNormalizedY: blob1NormalizedCenterPoint.y)
            } else {
                let visualImage = visualizeBlobOnImage(cgImage: diffImageCGImage, blob: blobsMappedToOriginalImage[1])
                setCurImage(label: "two blobs found", image: visualImage, delay: 1)
                
                ballPositions.append(blob2NormalizedCenterPoint)
                updateBallStateVector(newNormalizedX: blob2NormalizedCenterPoint.x, newNormalizedY: blob2NormalizedCenterPoint.y)
            }
            
            
            // blob that is furthest from last ball position is it
        } else if blobsMappedToOriginalImage.count > 2 {
            /// If multiple blobs are detected, this takes the two that are most simliar in size and then takes the one that is furthest
            /// from the prev ball position. I know this is not very robust but it works for the demo.
            let sorted = blobsMappedToOriginalImage.sorted { blob1, blob2 in
                blob1.pixels.count < blob2.pixels.count
            }
            
            var pair: [Blob] = [sorted[0], sorted[1]]
            var closestDiff = abs(pair[0].pixels.count - pair[1].pixels.count)
            
            for i in 1..<blobsMappedToOriginalImage.count - 1 {
                let first = blobsMappedToOriginalImage[i]
                let second = blobsMappedToOriginalImage[i + 1]
                let diff = abs(first.pixels.count - second.pixels.count)
                
                if diff < closestDiff {
                    pair = [first,second]
                    closestDiff = diff
                }
            }
            
            print("closest in size: \(pair[0].pixels.count), \(pair[1].pixels.count).")
            
            // find blob that is furthest from lastball position
            let blob1CenterPoint = pair[0].centerPoint!
            let blob2CenterPoint = pair[1].centerPoint!
            
            print("blob1 center point: \(blob1CenterPoint)")
            print("blob2 center point: \(blob2CenterPoint)")
            let lastX = ballStateVector[0]
            let lastY = ballStateVector[1]
            
            
            // normalized center points
            let blob1NormalizedCenterPoint = normalizeBlobCenterPoint(point: blob1CenterPoint, imageWidth: CGFloat(originalImageWidth), imageHeight: CGFloat(originalImageHeight))
            
            let blob2NormalizedCenterPoint = normalizeBlobCenterPoint(point: blob2CenterPoint, imageWidth: CGFloat(originalImageWidth), imageHeight: CGFloat(originalImageHeight))
            
            
            print("\(blob2NormalizedCenterPoint) should be lower than \(blob1NormalizedCenterPoint)")
            
            let blob1Distance = hypot(blob1NormalizedCenterPoint.x - lastX, blob1NormalizedCenterPoint.y - lastY)
            let blob2Distance = hypot(blob2NormalizedCenterPoint.x - lastX, blob2NormalizedCenterPoint.y - lastY)
            print("blob1Distance: \(blob1Distance)")
            print("blob2Distance: \(blob2Distance)")
            
            
            
            if blob1Distance > blob2Distance {
                let visualImage = visualizeBlobOnImage(cgImage: diffImageCGImage, blob: pair[0])
                setCurImage(label: "two blobs found", image: visualImage, delay: 1)
                
                ballPositions.append(blob1NormalizedCenterPoint)
                updateBallStateVector(newNormalizedX: blob1NormalizedCenterPoint.x, newNormalizedY: blob1NormalizedCenterPoint.y)
            } else {
                let visualImage = visualizeBlobOnImage(cgImage: diffImageCGImage, blob: pair[1])
                setCurImage(label: "two blobs found", image: visualImage, delay: 1)
                
                ballPositions.append(blob2NormalizedCenterPoint)
                updateBallStateVector(newNormalizedX: blob2NormalizedCenterPoint.x, newNormalizedY: blob2NormalizedCenterPoint.y)
            }
            
            
        } else {
            /// no blobs detected is not handled yet.
            /// just display the curve for now.
            let tracerImage = ImageProcessingTool.drawCurve(on: lastImage, with: ballPositions)
            setCurImage(label: "ball tracer", image: tracerImage!)
            
            fatalError()
        }
        
        print("ball positions: \(ballPositions)")
    }
    
    // Blobs have a top left origin, normlized points have bottom left origin
    private func normalizeBlobCenterPoint(point: CGPoint, imageWidth: CGFloat, imageHeight: CGFloat) -> CGPoint {
        return CGPoint(
            x: point.x / imageWidth,
            y: (imageHeight - point.y) / imageHeight
        )
    }
    
    private func updateBallStateVector(newNormalizedX: CGFloat, newNormalizedY: CGFloat) {
        let prevX = ballStateVector[0]
        let prevY = ballStateVector[1]
        
        let newDx = newNormalizedX - prevX
        let newDy = newNormalizedY - prevY
        
        ballStateVector = [newNormalizedX, newNormalizedY, newDx, newDy]
        print("update ballStateVector: \(ballStateVector)")
    }

    
    private func printBlobs(blobs: [Blob]) {
        for blob in blobs {
                print("blob: \(blob.pixels.count)")
        }
        print()
    }
    
    /// returns an image of the with blob pixels hightlighted in red.
    private func visualizeBlobOnImage(cgImage: CGImage, blob: Blob) -> CGImage {
        var swiftImage: SwiftImage.Image<RGBA<UInt8>> = .init(cgImage: cgImage)
        
        for pixel in blob.pixels {
            swiftImage[pixel.x,pixel.y] = .init(red: 255, green: 49, blue: 49)
        }
        
        return swiftImage.cgImage
    }
    
    
    /// returns a cropped image from a normalized CGRect with bottom left origin
    private func createCroppedImage(image: CGImage, normalizedCGRect: CGRect) -> CGImage {
        let imageWidth = image.width
        let imageHeight = image.height
        
        let croppedX = normalizedCGRect.origin.x * CGFloat(imageWidth)
        let croppedY = normalizedCGRect.origin.y * CGFloat(imageHeight)
        let croppedWidth = normalizedCGRect.width * CGFloat(imageWidth)
        let croppedHeight = normalizedCGRect.height * CGFloat(imageHeight)
        let croppedRect = CGRect(x: croppedX, y: croppedY, width: croppedWidth, height: croppedHeight)
        
        let ciImage = CIImage(cgImage: image)
        let cropFilter = CIFilter(name: "CICrop")!
        cropFilter.setValue(ciImage, forKey: kCIInputImageKey)
        cropFilter.setValue(CIVector(cgRect: croppedRect), forKey: "inputRectangle")
        
        let croppedImage = cropFilter.outputImage!
        let ciContext = CIContext()
        let croppedCGImage = ciContext.createCGImage(croppedImage, from: croppedImage.extent)!
        
        return croppedCGImage
    }
    
    /// creates a search region based on ball position state.
    ///
    /// - Returns: An image of search region and x,y offset with top left origin to map to the original image.
    private func createSearchRegionImage(diffImage: CGImage) -> (CGImage?, CGFloat?, CGFloat?) {
        guard ballStateVector[0] != 0 && ballStateVector[1] != 0 else { return (nil,nil,nil) }
        let originalImageWidth: CGFloat = CGFloat(diffImage.width)
        let originalImageHeight: CGFloat = CGFloat(diffImage.height)
        
        var searchRegionRect: CGRect!
        var xOffset: CGFloat?
        var yOffset: CGFloat?
        
        
        if ballStateVector[2] == 0 && ballStateVector[3] == 0 {
            // create broad search region if ball has no velocity
            let regionX: CGFloat = ballStateVector[0] * originalImageWidth
            let regionY: CGFloat = ballStateVector[1] * originalImageHeight
            let regionWidth: CGFloat = originalImageWidth * 0.25
            let regionHeight: CGFloat = originalImageHeight * 0.2
            
            xOffset = ballStateVector[0] * originalImageWidth - (regionWidth / 2)
            yOffset = (1 - ballStateVector[1]) * originalImageHeight - regionHeight
            
            searchRegionRect = CGRect(x: regionX - (regionWidth / 2), y: regionY, width: regionWidth, height: regionHeight)
        } else {
            /// simple calculation to predict where the ball will be based on dx dy, and creates a search region with it.
            let lastX = ballStateVector[0]
            let lastY = ballStateVector[1]
            let dx = ballStateVector[2]
            let dy = ballStateVector[3]
            
            let predictedXNormalized = lastX + (CGFloat(dx))
            let predictedYNormalized = lastY + (CGFloat(dy))
            
            print("predicted normalized Region: \(predictedXNormalized), \(predictedYNormalized)")
            
            let regionX: CGFloat = predictedXNormalized * originalImageWidth
            let regionY: CGFloat = predictedYNormalized * originalImageHeight
            let regionWidth: CGFloat = originalImageWidth * 0.2
            let regionHeight: CGFloat = originalImageHeight * 0.2
            
            xOffset = predictedXNormalized * originalImageWidth - (regionWidth / 2)
            yOffset = (1 - predictedYNormalized) * originalImageHeight - (regionHeight / 2)
            
            searchRegionRect = ImageProcessingTool.createCenterCGRect(centerX: regionX, centerY: regionY, width: regionWidth, height: regionHeight)
        }
        
        let ciImage = CIImage(cgImage: diffImage)
        let cropFilter = CIFilter(name: "CICrop")!
        cropFilter.setValue(ciImage, forKey: kCIInputImageKey)
        cropFilter.setValue(CIVector(cgRect: searchRegionRect), forKey: "inputRectangle")
        
        let croppedImage = cropFilter.outputImage!
        let ciContext = CIContext()
        let searchImage = ciContext.createCGImage(croppedImage, from: croppedImage.extent)!
        
        return (searchImage, xOffset, yOffset)
    }
    
    /// Finds cluters of pixels in an image that I call blobs using a 8 direction flood fill algorithm.
    private func findBlobs(in cgImage: CGImage) -> [Blob] {
        let imageWidth = cgImage.width
        let imageHeight = cgImage.height
        
        
        var queue: [Pixel] = []
        var visited = Array(repeating: Array(repeating: false, count: imageHeight), count: imageWidth)
        var detectedBlobs: [Blob] = []
        
        let swiftImage: SwiftImage.Image<RGBA<UInt8>> = .init(cgImage: cgImage)
        
        var curX = 0
        var curY = 0
        while curY < imageHeight {
            let pixel = swiftImage[curX, curY]
            if isPixelOfInterest(pixel: pixel) && !visited[curX][curY] {
                queue.append(Pixel(x: curX, y: curY))
                visited[curX][curY] = true
            }
            
            var blob = Blob()
            
            while !queue.isEmpty {
                let curPixel = queue.removeFirst()
                blob.pixels.append(curPixel)
                
                let topCoord = [curPixel.x, curPixel.y - 1]
                let botCoord = [curPixel.x, curPixel.y + 1]
                let leftCoord = [curPixel.x - 1, curPixel.y]
                let rightCoord = [curPixel.x + 1, curPixel.y]
                let topLeftCoord = [curPixel.x - 1, curPixel.y - 1]
                let topRightCoord = [curPixel.x + 1, curPixel.y - 1]
                let botLeftCoord = [curPixel.x - 1, curPixel.y - 1]
                let botRightCoord = [curPixel.x + 1, curPixel.y + 1]
                
                let neighbors = [topCoord, botCoord, leftCoord,
                                 rightCoord, topLeftCoord, topRightCoord,
                                 botLeftCoord, botRightCoord]
                
                
                for neighbor in neighbors {
                    if validNeighbor(x: neighbor[0], y: neighbor[1], width: imageWidth, height: imageHeight, visted: visited) &&
                        isPixelOfInterest(pixel: swiftImage[neighbor[0], neighbor[1]]) {
                        let neighborPixel = Pixel(x: neighbor[0], y: neighbor[1])
                        queue.append(neighborPixel)
                        visited[neighbor[0]][neighbor[1]] = true
                    }
                }
            }
            
            if blob.pixels.count > 0 {
                detectedBlobs.append(blob)
            }
            
            if curX + 1 >= imageWidth {
                curX = 0
                curY += 1
            } else {
                curX += 1
            }
        }
        
        return detectedBlobs
    }
    
    /// helper function for findBlobs()
    /// checks if coords are in bounds and has not been visited already.
    private func validNeighbor(x: Int, y: Int, width: Int, height: Int, visted: [[Bool]]) -> Bool {
        if x >= 0 && x < width && y >= 0 && y < height && !visted[x][y] {
            return true
        } else {
            return false
        }
    }
    
    /// diff images color pixels of motion in a specific green color (170,255,0)
    /// returns true if the given pixel is that color.
    private func isPixelOfInterest(pixel: RGBA<UInt8>) -> Bool {
        return pixel.red == 170 && pixel.green == 255 && pixel.blue == 0
      
    }
    
    /// Detects golf ball at rest on the turf.
    /// Currently uses a custom yolov11 model to detect a golf ball at rest on turf. This is used to get the initial position of the ball before
    /// we can use computer vision techniques to track the ball.
    ///
    /// - Returns: a CGRect bounding box for the detected golf ball that is normalized to the bottom left corner.
    private func detectInitialGolfBall(sampleBuffer: CMSampleBuffer, transform: CGAffineTransform) async -> CGRect? {
        return await withCheckedContinuation { continuation in
            let ciImage = ImageProcessingTool.createCIImage(from: sampleBuffer, transform: transform)!
            
            /// when you copy  model into project, the compilier creates a class that you can
            /// initialize your model with.
            let model = try! best(configuration: MLModelConfiguration())
            let visionModel = try! VNCoreMLModel(for: model.model)

            
            let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                guard let self else { return }
                if let error {
                    fatalError("\(error) - \(error.localizedDescription)")
                }
                
                if let results = request.results {
                    self.logger?.info("observation count: \(results.count)")
                    if results.count > 1 {
                        continuation.resume(returning: nil)
                    }
                    
                    if let firstResult = results.first as? VNRecognizedObjectObservation {
                        let ballBoundingBox = firstResult.boundingBox
                        continuation.resume(returning: ballBoundingBox)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
            let handler = VNImageRequestHandler(ciImage: ciImage)
            try! handler.perform([request])
        }
        
       
    }
    
    /// Detects golf ball at rest on the turf.
    /// Currently uses a custom yolov11 model to detect a golf ball at rest on turf. This is used to get the initial position of the ball before
    /// we can use computer vision techniques to track the ball.
    ///
    /// - Returns: a CGRect bounding box for the detected golf ball that is normalized to the bottom left corner.
    private func detectInitialGolfBall(uiImage: UIImage) async -> CGRect? {
        return await withCheckedContinuation { continuation in
            let ciImage = CIImage(image: uiImage)!
            
            /// when you move model into project, the compilier creates a class that you can
            /// initialize your model with.
            let model = try! best(configuration: MLModelConfiguration())
            let visionModel = try! VNCoreMLModel(for: model.model)

            
            let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                guard let self else { return }
                if let error {
                    fatalError("\(error) - \(error.localizedDescription)")
                }
                
                if let results = request.results {
                    self.logger?.info("observation count: \(results.count)")
                    if results.count > 1 {
                        continuation.resume(returning: nil)
                    }
                    
                    if let firstResult = results.first as? VNRecognizedObjectObservation {
                        let ballBoundingBox = firstResult.boundingBox
                        continuation.resume(returning: ballBoundingBox)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
            let handler = VNImageRequestHandler(ciImage: ciImage)
            try! handler.perform([request])
        }
    }
    
    /// Detects golf ball at rest on the turf.
    /// Currently uses a custom yolov11 model to detect a golf ball at rest on turf. This is used to get the initial position of the ball before
    /// we can use computer vision techniques to track the ball.
    ///
    /// - Returns: a CGRect bounding box for the detected golf ball that is normalized to the bottom left corner.
    private func detectInitialGolfBall(cgImage: CGImage) async -> CGRect? {
        return await withCheckedContinuation { continuation in
            
            /// when you move model into project, the compilier creates a class that you can
            /// initialize your model with.
            let model = try! best(configuration: MLModelConfiguration())
            let visionModel = try! VNCoreMLModel(for: model.model)

            
            let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                guard let self else { return }
                if let error {
                    fatalError("\(error) - \(error.localizedDescription)")
                }
                
                if let results = request.results {
                    self.logger?.info("observation count: \(results.count)")
                    if results.count > 1 {
                        continuation.resume(returning: nil)
                    }
                    
                    if let firstResult = results.first as? VNRecognizedObjectObservation {
                        let ballBoundingBox = firstResult.boundingBox
                        continuation.resume(returning: ballBoundingBox)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try! handler.perform([request])
        }
    }
    
    
}

struct Pixel {
    let x: Int
    let y: Int
}

struct Blob {
    var pixels: [Pixel] = []
    var centerPoint: CGPoint? {
        if pixels.count == 0 { return nil}
        
        let xCoords = pixels.map {$0.x}.sorted()
        let yCoords = pixels.map{$0.y}.sorted()
        let x = xCoords.count > 1 ? (xCoords[0] + xCoords[xCoords.count-1]) / 2 : xCoords[0]
        let y = yCoords.count > 1 ? (yCoords[0] + yCoords[xCoords.count-1]) / 2 : yCoords[0]
        
        return CGPoint(x: x, y: y)
    }
    
    func getPixelsOnOriginalImage(xOffset: Int, yOffset: Int) -> [Pixel] {
        return pixels.map { Pixel(x: $0.x + xOffset, y: $0.y + yOffset) }
    }
    
    
    
    func getBlobMappedToOriginalImage(xOffset: CGFloat, yOffset: CGFloat) -> Blob {
        let newPixels = getPixelsOnOriginalImage(xOffset: Int(xOffset), yOffset: Int(yOffset))
        return Blob(pixels: newPixels)
    }
}

struct GolfTrackerResearch: View {
    @StateObject var tracker: GolfBallTracker
    
    init() {
        self._tracker = .init(wrappedValue: GolfBallTracker(videoFrameProvider: LocalVideoFrameProvider()))
    }
    
    var body: some View {
        VStack {
            Text(tracker.curLabel)
                .font(.largeTitle)
                
            if tracker.curImage != nil {
                Image(uiImage: tracker.curImage!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "photo")
            }
        }
        .onAppear() {
            Task {
//                try await tracker.startTracking()
                tracker.testBallCurve()
            }
        }
    }
}

