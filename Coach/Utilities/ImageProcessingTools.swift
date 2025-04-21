//
//  ImageProcessingTools.swift
//  Coach
//
//  Created by Allen Liang on 3/14/25.
//

import Accelerate
import UIKit
import CoreImage
import CoreMedia

struct ImageProcessingTool {
    static func createCIImage(from sampleBuffer: CMSampleBuffer, transform: CGAffineTransform) -> CIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        let ciimage = CIImage(cvImageBuffer: imageBuffer).transformed(by: transform)
        return ciimage
    }
    
    static func createCGImage(from sampleBuffer: CMSampleBuffer, transform: CGAffineTransform) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        return cgImage
    }
    
    static func createUIImage(sampleBuffer: CMSampleBuffer, transform: CGAffineTransform) throws -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        let ciimage = CIImage(cvImageBuffer: imageBuffer).transformed(by: transform)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciimage, from: ciimage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    static func createCenterCGRect(centerX: CGFloat, centerY: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        let originX = centerX - (width / 2)
        let originY = centerY - (height / 2)
        
        return CGRect(x: originX, y: originY, width: width, height: height)
    }
    
    static func drawCurve(on image: CGImage, with points: [CGPoint]) -> UIImage? {
        let imageSize = CGSize(width: image.width, height: image.height)
        
        // Create a graphics context
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        // Draw the original image flipped so it displays correctly.
        // Save the state before applying the flip, then restore it for curve drawing.
        context.saveGState()
        context.translateBy(x: 0, y: imageSize.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.draw(image, in: CGRect(origin: .zero, size: imageSize))
        context.restoreGState()
        
        // Convert the normalized points (bottom-left origin) to UIKit coordinates (top-left origin)
        let convertedPoints = points.map { CGPoint(x: $0.x * imageSize.width, y: (1.0 - $0.y) * imageSize.height) }
        
        // Build the curve. Here we simply draw a connected line.
        // You can replace this with any curve interpolation method (e.g., Catmull-Rom spline) if desired.
        let path = UIBezierPath()
        if let firstPoint = convertedPoints.first {
            path.move(to: firstPoint)
        }
        
        for point in convertedPoints.dropFirst() {
            path.addLine(to: point)
        }
        
        // Set the drawing attributes for the curve
        let translucentRed = UIColor.red.withAlphaComponent(0.5)
            translucentRed.setStroke()
        translucentRed.setStroke()
        path.lineWidth = 10.0
        path.stroke()
        
        // Capture the final image
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    
    /// generated using claude  ~3/10/25, haven't analyzed it yet but is it faster than using SwiftImage and subtracting each pixel.
    static func imageSubtraction(image1: UIImage, image2: UIImage, threshold: CGFloat = 20, minBlobSize: Int = 4) -> UIImage? {
        // Use autoreleasepool to help manage memory
        return autoreleasepool { () -> UIImage? in
            guard let cgImage1 = image1.cgImage,
                  let cgImage2 = image2.cgImage,
                  cgImage1.width == cgImage2.width,
                  cgImage1.height == cgImage2.height else {
                return UIImage() // Return empty image if sizes don't match
            }
            
            let width = cgImage1.width
            let height = cgImage1.height
            let bytesPerRow = width * 4
            
            // Setup vImage buffers
            var sourceBuffer1 = vImage_Buffer()
            var sourceBuffer2 = vImage_Buffer()
            var destBuffer = vImage_Buffer()
            var tempBuffer = vImage_Buffer() // Added for two-pass processing
            
            // Initialize all data pointers to nil
            sourceBuffer1.data = nil
            sourceBuffer2.data = nil
            destBuffer.data = nil
            tempBuffer.data = nil
            
            // Use a single comprehensive defer block that will execute when the function exits
            // This ensures all allocated memory is freed regardless of how we exit the function
            defer {
                if sourceBuffer1.data != nil { free(sourceBuffer1.data) }
                if sourceBuffer2.data != nil { free(sourceBuffer2.data) }
                if destBuffer.data != nil { free(destBuffer.data) }
                if tempBuffer.data != nil { free(tempBuffer.data) }
            }
            
            // Allocate memory for buffers
            let bufferSize = bytesPerRow * height
            sourceBuffer1.width = vImagePixelCount(width)
            sourceBuffer1.height = vImagePixelCount(height)
            sourceBuffer1.rowBytes = bytesPerRow
            sourceBuffer1.data = malloc(bufferSize)
            
            // Check for allocation failure
            guard sourceBuffer1.data != nil else { return UIImage() }
            
            sourceBuffer2.width = vImagePixelCount(width)
            sourceBuffer2.height = vImagePixelCount(height)
            sourceBuffer2.rowBytes = bytesPerRow
            sourceBuffer2.data = malloc(bufferSize)
            
            // Check for allocation failure
            guard sourceBuffer2.data != nil else { return UIImage() }
            
            destBuffer.width = vImagePixelCount(width)
            destBuffer.height = vImagePixelCount(height)
            destBuffer.rowBytes = bytesPerRow
            destBuffer.data = malloc(bufferSize)
            
            // Check for allocation failure
            guard destBuffer.data != nil else { return UIImage() }
            
            tempBuffer.width = vImagePixelCount(width)
            tempBuffer.height = vImagePixelCount(height)
            tempBuffer.rowBytes = bytesPerRow
            tempBuffer.data = malloc(bufferSize)
            
            // Check for allocation failure
            guard tempBuffer.data != nil else { return UIImage() }
            
            // Create CGContext for each buffer
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            
            guard let context1 = CGContext(
                data: sourceBuffer1.data,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else {
                return UIImage()
            }
            
            guard let context2 = CGContext(
                data: sourceBuffer2.data,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else {
                return UIImage()
            }
            
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            context1.draw(cgImage1, in: rect)
            context2.draw(cgImage2, in: rect)
            
            // Process the images using vImage for SIMD acceleration
            let pixelCount = width * height
            let thresholdValue: UInt8 = UInt8(threshold)
            
            // Convert to 8-bit bytes for processing
            let buffer1 = sourceBuffer1.data.assumingMemoryBound(to: UInt8.self)
            let buffer2 = sourceBuffer2.data.assumingMemoryBound(to: UInt8.self)
            let tempOutputBuffer = tempBuffer.data.assumingMemoryBound(to: UInt8.self)
            let outputBuffer = destBuffer.data.assumingMemoryBound(to: UInt8.self)
            
            // Clear the output buffer - initialize to black
            memset(outputBuffer, 0, bufferSize)
            
            // PASS 1: Calculate differences and create initial green highlighted image
            DispatchQueue.concurrentPerform(iterations: height) { y in
                let rowStart = y * bytesPerRow
                for x in stride(from: 0, to: width * 4, by: 4) {
                    let pixelIndex = rowStart + x
                    
                    // Calculate pixel differences
                    let redDiff = abs(Int(buffer1[pixelIndex]) - Int(buffer2[pixelIndex]))
                    let greenDiff = abs(Int(buffer1[pixelIndex + 1]) - Int(buffer2[pixelIndex + 1]))
                    let blueDiff = abs(Int(buffer1[pixelIndex + 2]) - Int(buffer2[pixelIndex + 2]))
                    
                    let totalDiff = redDiff + greenDiff + blueDiff
                    
                    if totalDiff > Int(thresholdValue) {
                        tempOutputBuffer[pixelIndex] = 170     // Red
                        tempOutputBuffer[pixelIndex + 1] = 255 // Green
                        tempOutputBuffer[pixelIndex + 2] = 0   // Blue
                        tempOutputBuffer[pixelIndex + 3] = 255 // Alpha
                    } else {
                        tempOutputBuffer[pixelIndex] = 0       // Red
                        tempOutputBuffer[pixelIndex + 1] = 0   // Green
                        tempOutputBuffer[pixelIndex + 2] = 0   // Blue
                        tempOutputBuffer[pixelIndex + 3] = 255 // Alpha
                    }
                }
            }
            
            // Use autoreleasepool for large temporary arrays
            autoreleasepool {
                // PASS 2: Create a map of green pixels to identify blobs
                // We'll use a simple 2D array to represent green pixels
                var greenMap = [Bool](repeating: false, count: pixelCount)
                
                for y in 0..<height {
                    for x in 0..<width {
                        let pixelOffset = (y * width) + x
                        let byteOffset = (y * bytesPerRow) + (x * 4)
                        
                        // Check if this is a green pixel (part of detected difference)
                        if tempOutputBuffer[byteOffset] == 170 &&
                            tempOutputBuffer[byteOffset + 1] == 255 &&
                            tempOutputBuffer[byteOffset + 2] == 0 {
                            greenMap[pixelOffset] = true
                        }
                    }
                }
                
                // PASS 3: Find connected components (blobs) using flood fill
                var visited = [Bool](repeating: false, count: pixelCount)
                
                for y in 0..<height {
                    for x in 0..<width {
                        let startPixel = (y * width) + x
                        
                        // Skip if not a green pixel or already visited
                        if !greenMap[startPixel] || visited[startPixel] {
                            continue
                        }
                        
                        // Perform flood fill to find all connected pixels
                        var queue = [Int]()
                        var blobPixels = [Int]()
                        
                        // Reserve capacity to avoid reallocations
                        queue.reserveCapacity(minBlobSize * 2)
                        blobPixels.reserveCapacity(minBlobSize * 2)
                        
                        queue.append(startPixel)
                        blobPixels.append(startPixel)
                        visited[startPixel] = true
                        
                        // Simple 4-way flood fill
                        while !queue.isEmpty {
                            let pixel = queue.removeFirst()
                            let px = pixel % width
                            let py = pixel / width
                            
                            // Check 4 neighbors (up, down, left, right)
                            if px > 0 {
                                let neighbor = pixel - 1
                                if greenMap[neighbor] && !visited[neighbor] {
                                    visited[neighbor] = true
                                    queue.append(neighbor)
                                    blobPixels.append(neighbor)
                                }
                            }
                            
                            if px < width - 1 {
                                let neighbor = pixel + 1
                                if greenMap[neighbor] && !visited[neighbor] {
                                    visited[neighbor] = true
                                    queue.append(neighbor)
                                    blobPixels.append(neighbor)
                                }
                            }
                            
                            if py > 0 {
                                let neighbor = pixel - width
                                if greenMap[neighbor] && !visited[neighbor] {
                                    visited[neighbor] = true
                                    queue.append(neighbor)
                                    blobPixels.append(neighbor)
                                }
                            }
                            
                            if py < height - 1 {
                                let neighbor = pixel + width
                                if greenMap[neighbor] && !visited[neighbor] {
                                    visited[neighbor] = true
                                    queue.append(neighbor)
                                    blobPixels.append(neighbor)
                                }
                            }
                        }
                        
                        // If this blob is large enough, copy it to the final output
                        if blobPixels.count >= minBlobSize {
                            for pixel in blobPixels {
                                let py = pixel / width
                                let px = pixel % width
                                let byteOffset = (py * bytesPerRow) + (px * 4)
                                
                                outputBuffer[byteOffset] = 170     // Red
                                outputBuffer[byteOffset + 1] = 255 // Green
                                outputBuffer[byteOffset + 2] = 0   // Blue
                                outputBuffer[byteOffset + 3] = 255 // Alpha
                            }
                        }
                    }
                }
            } // End inner autoreleasepool for large arrays
            
            // Create output image from the processed buffer
            guard let destContext = CGContext(
                data: destBuffer.data,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else {
                return UIImage()
            }
            
            // Clean up any non-green pixels (ensure they're black)
            for i in stride(from: 0, to: bufferSize, by: 4) {
                // If this pixel is not part of a detected blob (not green)
                if outputBuffer[i] != 170 || outputBuffer[i+1] != 255 || outputBuffer[i+2] != 0 {
                    // Ensure it's completely black with full opacity
                    outputBuffer[i] = 0        // R
                    outputBuffer[i+1] = 0      // G
                    outputBuffer[i+2] = 0      // B
                    outputBuffer[i+3] = 255    // A (fully opaque)
                }
            }
            
            // Create the final image
            guard let outputCGImage = destContext.makeImage() else {
                return UIImage()
            }
            
            // Return the final image - all memory will be released via defer block
            return UIImage(cgImage: outputCGImage)
        } // End outer autoreleasepool
    }
    
    
    /// generated using claude  ~3/10/25, haven't analyzed it yet but is it faster than using SwiftImage and subtracting each pixel.
    static func imageSubtraction(cgImage1: CGImage, cgImage2: CGImage, threshold: CGFloat = 30, minBlobSize: Int = 4) -> UIImage? {
        // Use autoreleasepool to help manage memory
        return autoreleasepool { () -> UIImage? in
            guard cgImage1.width == cgImage2.width,
                  cgImage1.height == cgImage2.height else {
                return UIImage() // Return empty image if sizes don't match
            }
            
            let width = cgImage1.width
            let height = cgImage1.height
            let bytesPerRow = width * 4
            
            // Setup vImage buffers
            var sourceBuffer1 = vImage_Buffer()
            var sourceBuffer2 = vImage_Buffer()
            var destBuffer = vImage_Buffer()
            var tempBuffer = vImage_Buffer() // Added for two-pass processing
            
            // Initialize all data pointers to nil
            sourceBuffer1.data = nil
            sourceBuffer2.data = nil
            destBuffer.data = nil
            tempBuffer.data = nil
            
            // Use a single comprehensive defer block that will execute when the function exits
            // This ensures all allocated memory is freed regardless of how we exit the function
            defer {
                if sourceBuffer1.data != nil { free(sourceBuffer1.data) }
                if sourceBuffer2.data != nil { free(sourceBuffer2.data) }
                if destBuffer.data != nil { free(destBuffer.data) }
                if tempBuffer.data != nil { free(tempBuffer.data) }
            }
            
            // Allocate memory for buffers
            let bufferSize = bytesPerRow * height
            sourceBuffer1.width = vImagePixelCount(width)
            sourceBuffer1.height = vImagePixelCount(height)
            sourceBuffer1.rowBytes = bytesPerRow
            sourceBuffer1.data = malloc(bufferSize)
            
            // Check for allocation failure
            guard sourceBuffer1.data != nil else { return UIImage() }
            
            sourceBuffer2.width = vImagePixelCount(width)
            sourceBuffer2.height = vImagePixelCount(height)
            sourceBuffer2.rowBytes = bytesPerRow
            sourceBuffer2.data = malloc(bufferSize)
            
            // Check for allocation failure
            guard sourceBuffer2.data != nil else { return UIImage() }
            
            destBuffer.width = vImagePixelCount(width)
            destBuffer.height = vImagePixelCount(height)
            destBuffer.rowBytes = bytesPerRow
            destBuffer.data = malloc(bufferSize)
            
            // Check for allocation failure
            guard destBuffer.data != nil else { return UIImage() }
            
            tempBuffer.width = vImagePixelCount(width)
            tempBuffer.height = vImagePixelCount(height)
            tempBuffer.rowBytes = bytesPerRow
            tempBuffer.data = malloc(bufferSize)
            
            // Check for allocation failure
            guard tempBuffer.data != nil else { return UIImage() }
            
            // Create CGContext for each buffer
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            
            guard let context1 = CGContext(
                data: sourceBuffer1.data,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else {
                return UIImage()
            }
            
            guard let context2 = CGContext(
                data: sourceBuffer2.data,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else {
                return UIImage()
            }
            
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            context1.draw(cgImage1, in: rect)
            context2.draw(cgImage2, in: rect)
            
            // Process the images using vImage for SIMD acceleration
            let pixelCount = width * height
            let thresholdValue: UInt8 = UInt8(threshold)
            
            // Convert to 8-bit bytes for processing
            let buffer1 = sourceBuffer1.data.assumingMemoryBound(to: UInt8.self)
            let buffer2 = sourceBuffer2.data.assumingMemoryBound(to: UInt8.self)
            let tempOutputBuffer = tempBuffer.data.assumingMemoryBound(to: UInt8.self)
            let outputBuffer = destBuffer.data.assumingMemoryBound(to: UInt8.self)
            
            // Clear the output buffer - initialize to black
            memset(outputBuffer, 0, bufferSize)
            
            // PASS 1: Calculate differences and create initial green highlighted image
            DispatchQueue.concurrentPerform(iterations: height) { y in
                let rowStart = y * bytesPerRow
                for x in stride(from: 0, to: width * 4, by: 4) {
                    let pixelIndex = rowStart + x
                    
                    // Calculate pixel differences
                    let redDiff = abs(Int(buffer1[pixelIndex]) - Int(buffer2[pixelIndex]))
                    let greenDiff = abs(Int(buffer1[pixelIndex + 1]) - Int(buffer2[pixelIndex + 1]))
                    let blueDiff = abs(Int(buffer1[pixelIndex + 2]) - Int(buffer2[pixelIndex + 2]))
                    
                    let totalDiff = redDiff + greenDiff + blueDiff
                    
                    if totalDiff > Int(thresholdValue) {
                        tempOutputBuffer[pixelIndex] = 170     // Red
                        tempOutputBuffer[pixelIndex + 1] = 255 // Green
                        tempOutputBuffer[pixelIndex + 2] = 0   // Blue
                        tempOutputBuffer[pixelIndex + 3] = 255 // Alpha
                    } else {
                        tempOutputBuffer[pixelIndex] = 0       // Red
                        tempOutputBuffer[pixelIndex + 1] = 0   // Green
                        tempOutputBuffer[pixelIndex + 2] = 0   // Blue
                        tempOutputBuffer[pixelIndex + 3] = 255 // Alpha
                    }
                }
            }
            
            // Use autoreleasepool for large temporary arrays
            autoreleasepool {
                // PASS 2: Create a map of green pixels to identify blobs
                // We'll use a simple 2D array to represent green pixels
                var greenMap = [Bool](repeating: false, count: pixelCount)
                
                for y in 0..<height {
                    for x in 0..<width {
                        let pixelOffset = (y * width) + x
                        let byteOffset = (y * bytesPerRow) + (x * 4)
                        
                        // Check if this is a green pixel (part of detected difference)
                        if tempOutputBuffer[byteOffset] == 170 &&
                            tempOutputBuffer[byteOffset + 1] == 255 &&
                            tempOutputBuffer[byteOffset + 2] == 0 {
                            greenMap[pixelOffset] = true
                        }
                    }
                }
                
                // PASS 3: Find connected components (blobs) using flood fill
                var visited = [Bool](repeating: false, count: pixelCount)
                
                for y in 0..<height {
                    for x in 0..<width {
                        let startPixel = (y * width) + x
                        
                        // Skip if not a green pixel or already visited
                        if !greenMap[startPixel] || visited[startPixel] {
                            continue
                        }
                        
                        // Perform flood fill to find all connected pixels
                        var queue = [Int]()
                        var blobPixels = [Int]()
                        
                        // Reserve capacity to avoid reallocations
                        queue.reserveCapacity(minBlobSize * 2)
                        blobPixels.reserveCapacity(minBlobSize * 2)
                        
                        queue.append(startPixel)
                        blobPixels.append(startPixel)
                        visited[startPixel] = true
                        
                        // Simple 4-way flood fill
                        while !queue.isEmpty {
                            let pixel = queue.removeFirst()
                            let px = pixel % width
                            let py = pixel / width
                            
                            // Check 4 neighbors (up, down, left, right)
                            if px > 0 {
                                let neighbor = pixel - 1
                                if greenMap[neighbor] && !visited[neighbor] {
                                    visited[neighbor] = true
                                    queue.append(neighbor)
                                    blobPixels.append(neighbor)
                                }
                            }
                            
                            if px < width - 1 {
                                let neighbor = pixel + 1
                                if greenMap[neighbor] && !visited[neighbor] {
                                    visited[neighbor] = true
                                    queue.append(neighbor)
                                    blobPixels.append(neighbor)
                                }
                            }
                            
                            if py > 0 {
                                let neighbor = pixel - width
                                if greenMap[neighbor] && !visited[neighbor] {
                                    visited[neighbor] = true
                                    queue.append(neighbor)
                                    blobPixels.append(neighbor)
                                }
                            }
                            
                            if py < height - 1 {
                                let neighbor = pixel + width
                                if greenMap[neighbor] && !visited[neighbor] {
                                    visited[neighbor] = true
                                    queue.append(neighbor)
                                    blobPixels.append(neighbor)
                                }
                            }
                        }
                        
                        // If this blob is large enough, copy it to the final output
                        if blobPixels.count >= minBlobSize {
                            for pixel in blobPixels {
                                let py = pixel / width
                                let px = pixel % width
                                let byteOffset = (py * bytesPerRow) + (px * 4)
                                
                                outputBuffer[byteOffset] = 170     // Red
                                outputBuffer[byteOffset + 1] = 255 // Green
                                outputBuffer[byteOffset + 2] = 0   // Blue
                                outputBuffer[byteOffset + 3] = 255 // Alpha
                            }
                        }
                    }
                }
            } // End inner autoreleasepool for large arrays
            
            // Create output image from the processed buffer
            guard let destContext = CGContext(
                data: destBuffer.data,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else {
                return UIImage()
            }
            
            // Clean up any non-green pixels (ensure they're black)
            for i in stride(from: 0, to: bufferSize, by: 4) {
                // If this pixel is not part of a detected blob (not green)
                if outputBuffer[i] != 170 || outputBuffer[i+1] != 255 || outputBuffer[i+2] != 0 {
                    // Ensure it's completely black with full opacity
                    outputBuffer[i] = 0        // R
                    outputBuffer[i+1] = 0      // G
                    outputBuffer[i+2] = 0      // B
                    outputBuffer[i+3] = 255    // A (fully opaque)
                }
            }
            
            // Create the final image
            guard let outputCGImage = destContext.makeImage() else {
                return UIImage()
            }
            
            // Return the final image - all memory will be released via defer block
            return UIImage(cgImage: outputCGImage)
        } // End outer autoreleasepool
    }
}
