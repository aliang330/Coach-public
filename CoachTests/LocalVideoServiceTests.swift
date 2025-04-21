//
//  LocalVideoServiceTests.swift
//  CoachTests
//
//  Created by Allen Liang on 2/26/25.
//

import XCTest
import CoreData
import Combine
import CoreMedia
@testable import Coach

final class LocalVideoServiceTests: XCTestCase {
    var service: LocalVideoService!
    var context: NSManagedObjectContext!
    var cancellables: Set<AnyCancellable> = []
    
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        context = TestCoreDataStack.createInMemoryContainer().viewContext
        service = LocalVideoService(context: context, isTestInstance: true)
    }

    override func tearDownWithError() throws {
        service = nil
        context = nil
        cancellables.removeAll()
        try super.tearDownWithError()
    }

   // MARK: -- publisher tests
    
    func testGetLocalVideoPub_WithNoVideos_isEmpty() {
        let pub = service.getLocalVideoPublisher()
        let expectation = expectation(description: "should receive empty array")
        
        pub.sink { localVideos in
            XCTAssertEqual(localVideos.count, 0)
            expectation.fulfill()
        }
        .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testLocalVideoPub_WithOneSavedVideo_PublishesOneVideo() throws {
        let publisher = service.getLocalVideoPublisher()
        
        let localVideoDTO = try createSampleLocalVideo()
        
        let expectation = expectation(description: "should receive array with one LocalVideo")
        
        publisher.sink { localVideos in
            XCTAssertEqual(localVideos.count, 1)
            expectation.fulfill()
        }
        .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testLocalVideoPub_WithMultipleSavedVideo_PublishesMultipleVideos() throws {
        let publisher = service.getLocalVideoPublisher()
        
        let localVideoDTO = try createSampleLocalVideo()
        let localVideoDTO2 = try createSampleLocalVideo()
        
        let expectation = expectation(description: "should receive array with one LocalVideo")
        
        publisher.sink { localVideos in
            XCTAssertEqual(localVideos.count, 2)
            expectation.fulfill()
        }
        .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testLocalVideoPub_WithMultipleSavedVideo_PublishesSortedByDateAddedMostRecentFirst() throws {
        let publisher = service.getLocalVideoPublisher()
        let baseDate = Date()
        
        let oldestVideo = try createSampleLocalVideo(dateAdded: baseDate.addingTimeInterval(-2))
        let middleVideo = try createSampleLocalVideo(dateAdded: baseDate.addingTimeInterval(-1))
        let newestVideo = try createSampleLocalVideo(dateAdded: baseDate)
        
        
        
        
        let expectation = expectation(description: "should receive array with one LocalVideo")
        
        publisher.sink { localVideos in
            XCTAssertEqual(localVideos.count, 3)
            
            for i in (0..<localVideos.count - 1) {
                if !(localVideos[i].dateAdded > localVideos[i + 1].dateAdded) {
                    XCTFail("localVideos should be sorted in descending order by dateAdded.")
                }
            }
            
            expectation.fulfill()
        }
        .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
    
    
    // MARK: - save tests
    
    func testSaveLocalVideo_WithValidData_SavesVideoWithValidData() throws {
        let localVideoDTO = try createSampleLocalVideo()
        
        let expectation = expectation(description: "should save video")
        
        service.getLocalVideoPublisher()
            .sink { localVideos in
                let localVideo = localVideos.first!
                
                XCTAssertEqual(localVideo.path, localVideoDTO.path)
                XCTAssertEqual(localVideo.dateAdded, localVideoDTO.dateAdded)
                XCTAssertEqual(localVideo.duration, localVideoDTO.duration)
                XCTAssertEqual(localVideo.frameRate, localVideoDTO.frameRate)
                XCTAssertEqual(localVideo.thumbnailData, localVideoDTO.thumbnailData)
                XCTAssertEqual(localVideo.bodyPoseFrames, localVideoDTO.bodyPoseFrames)
                
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
 
    // MARK: - helper methods
    
    private func createSampleLocalVideo(dateAdded: Date = Date()) throws -> LocalVideoDTO {
        let path = "\(FileDirectoryConst.videosDirectory)/\(UUID().uuidString).mp4"
        let bodyPoseFrames = [BodyPoseFrame(time: CMTime(seconds: 0.0, preferredTimescale: 600), joints: [BodyPosePart : VNRecognizedPointWrapper]())]
        let dateAdded = dateAdded
        let duration = 10.0
        let frameRate = 60.0
        let thumbnailData = Data(count: 100)
        
        let _ = try service.saveLocalVideo(path: path,
                                   duration: duration,
                                   dateAdded: dateAdded,
                                   thumbnailData: thumbnailData,
                                   frameRate: frameRate,
                                   bodyposeFrames: bodyPoseFrames
        )
        
        return LocalVideoDTO(path: path, dateAdded: dateAdded, duration: duration, frameRate: frameRate, thumbnailData: thumbnailData, bodyPoseFrames: bodyPoseFrames)
    }
    
}

class TestCoreDataStack {
    static func createInMemoryContainer() -> NSPersistentContainer {
        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.type = NSInMemoryStoreType
        
        let container = NSPersistentContainer(name: "Coach")
        container.persistentStoreDescriptions = [persistentStoreDescription]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("❌ Failed to load test Core Data stack: \(error)")
            }
        }
        return container
    }
}
