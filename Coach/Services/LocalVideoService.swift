//
//  LocalVideoService.swift
//  Coach
//
//  Created by Allen Liang on 2/23/25.
//

import Foundation
import CoreData
import Combine
import UIKit

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
            
            // Pass the data model filename to the container’s initializer.
            let container = NSPersistentContainer(name: "Coach")
            
            // Load any persistent stores, which creates a store if none exists.
            container.loadPersistentStores { _, error in
                if let error {
                    // Handle the error appropriately. However, it's useful to use
                    // `fatalError(_:file:line:)` during development.
                    fatalError("Failed to load persistent stores: \(error.localizedDescription)")
                }
            }
            return container
        }()
            
    private init() {}
}




protocol LocalVideoServiceProtocol {
    func getLocalVideoPublisher() -> AnyPublisher<[LocalVideoDTO], Never>
    func saveLocalVideo(path: String, duration: Double, dateAdded: Date, thumbnailData: Data?, frameRate: Double, bodyposeFrames: [BodyPoseFrame]) throws -> LocalVideoDTO
    func deleteLocalVideo(_ localVideoDTO: LocalVideoDTO) throws
    
}


///
/// LocalVideoService manages local video data persistence and file operations.
///
/// - IMPORTANT: This service should be instantiated ONCE at app startup and injected
/// into dependent components. Creating multiple instances can lead to data synchronization issues.
///
class LocalVideoService: NSObject, NSFetchedResultsControllerDelegate, LocalVideoServiceProtocol {
    // MARK: - Debug
    #if DEBUG
    private static var instanceCount = 0
    #endif
    
    private var context: NSManagedObjectContext
    private var localVideoFetchControllerLoaded = false
    private var localVideoPub = CurrentValueSubject<[LocalVideoDTO], Never>([])
    
    private lazy var localVideoFetchController: NSFetchedResultsController<LocalVideo> = {
        let fetchRequest: NSFetchRequest<LocalVideo> = LocalVideo.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LocalVideo.dateAdded, ascending: false)]
        
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        controller.delegate = self
        
        do {
            try controller.performFetch()
            let results = controller.fetchedObjects ?? []
            localVideoPub.send(convertLocalVideostoDTOs(results))
        } catch {
            // TODO: how to handle this error?
            print("localVideoFetchController failed to performFetch: \(error)")
        }
        
        return controller
    }()
    
    /// Initializes a local video service with the specified Core Data context.
    ///
    /// - Parameters:
    /// - context: The Core Data managed object context to use for database operations.
    /// - isTestInstance: A flag indicating whether this instance is created for unit testing.
    /// - Important: The `isTestInstance` parameter should only be set to `true` in unit tests.
    ///         In production code, always use the default value (`false`).
    init(context: NSManagedObjectContext = CoreDataStack.shared.persistentContainer.viewContext, isTestInstance: Bool = false) {
        #if DEBUG
        if !isTestInstance {
            LocalVideoService.instanceCount += 1
        }
        assert(LocalVideoService.instanceCount <= 1, "⚠️ Multiple instances of LocalVideoService detected! This service should be instantiated once and shared.")
        #endif
        
        self.context = context
        super.init()
    }
    
    // MARK: - LocalVideoServiceProtocol methods
    
    /// Returns a `Publisher` that emits and array of LocalVideoDTO.
    ///
    /// This method provides a Combine Publisher that emits the current collection of local videos and then emit an updated collection
    /// whenever videos are added, deleted or updated from the persistent store using a `NSFetchedResultsController`.
    ///
    /// - Returns: A `Publisher` that never fails and emits an array of `LocalVideoDTO` objects whenver the local video collection
    /// changes.
    ///
    /// - Note: The first call to this method initializes a `NSFetchedResultsController` to track changes to
    ///  `LocalVideo` entites and updates the internal `Publisher`. Subsequent calls return the same `Publisher` instance.
    func getLocalVideoPublisher() -> AnyPublisher<[LocalVideoDTO], Never> {
        if !localVideoFetchControllerLoaded {
            let _ = localVideoFetchController
            localVideoFetchControllerLoaded = true
        }
        
        return localVideoPub.eraseToAnyPublisher()
    }
    
    
    /// Saves a new local video to the persistent store.
    ///
    /// This method creates a new `LocalVideo` entity in Core Data with the provided information,
    /// including serializing the body pose frames as JSON data. It then saves the managed object context
    /// and returns a data transfer object representing the saved video.
    ///
    /// - Parameters:
    ///   - path: The file path identifier for the video in the local file system relative to the documents directory.
    ///   - duration: The duration of the video in seconds.
    ///   - dateAdded: The date when the video was added. Defaults to the current date.
    ///   - thumbnailData: The binary data for the video's thumbnail image.
    ///   - frameRate: The frame rate of the video in frames per second.
    ///   - bodyposeFrames: An array of `BodyPoseFrame` detected in the video.
    ///
    /// - Returns: A LocalVideoDTO representing the saved video.
    ///
    /// - Throws: `LocalVideoServiceError.failedToEncodeBodyPoseFrames`: If the body pose frames cannot be encoded to JSON.
    /// - Throws: `LocalVideoServiceError.localVideoFailedToSave`: If the Core Data context save operation fails.
    func saveLocalVideo(path: String, duration: Double, dateAdded: Date = Date(), thumbnailData: Data?, frameRate: Double, bodyposeFrames: [BodyPoseFrame]) throws -> LocalVideoDTO {
        
        let localVideo = LocalVideo(context: context)
        localVideo.path = path
        localVideo.duration = duration
        localVideo.thumbnailData = thumbnailData
        localVideo.frameRate = frameRate
        localVideo.dateAdded = dateAdded
        
        do {
            let frameData = try JSONEncoder().encode(bodyposeFrames)
            localVideo.bodyPoseFrameData = frameData
        } catch {
            throw LocalVideoServiceError.failedToEncodeBodyPoseFrames(error)
        }
        
        do {
            try context.save()
        } catch {
            throw LocalVideoServiceError.localVideoFailedToSave(error)
        }
        
        return convertToLocalVideoDTO(localVideo)
    }
    
    /// Deletes the LocalVideo entity and video file from the file directory
    ///
    /// This operation is currently not atomic - if the core data entity is deleted sucessfully but the file deletion fails,
    /// the database will no longer contain a reference to the file but the file will remain on disk.
    ///
    /// - Parameters:
    ///    - localVideoDTO: The data transfer object representing the video to delete.
    ///
    /// - Throws: `LocalVideoServiceError.localVideoNotFound`: If the Core Data entity cannot be found.
    /// - Throws: `LocalVideoServiceError.localVideoEntityFailedToDelete`: If the Core Data entity deletion fails.
    /// - Throws: `LocalVideoServiceError.localVideoFileFailedToDelete`: If the video file cannot be removed from the file system.
    func deleteLocalVideo(_ localVideoDTO: LocalVideoDTO) throws {
        // TODO: make atomic
        // delete coredata entity
        guard let localVideo = try fetchLocalVideoBy(path: localVideoDTO.path) else {
            throw LocalVideoServiceError.localVideoNotFound
        }
        
        let videoURL = URL.videoURL(videoPath: localVideo.path)
        context.delete(localVideo)
        
        do {
            try context.save()
        } catch {
            throw LocalVideoServiceError.localVideoEntityFailedToDelete(error)
        }
        
        // delete video file from file directory
        do {
            try FileManager.default.removeItem(at: videoURL)
        } catch {
            throw LocalVideoServiceError.localVideoFileFailedToDelete(error)
        }
        
    }
    
    // MARK: - Private methods
    
    /// Converts an array of `LocalVideo` objects to an array `LocalVideoDTO` objects.
    ///
    /// This helper method maps a collection of `LocalVideo` to a `LocalVideoDTO` collection.
    ///
    /// - Parameters localVideos: An array of `LocalVideo` to convert.
    /// - Returns: An array of LocalVideoDTO objects.
    private func convertLocalVideostoDTOs(_ localVideos: [LocalVideo]) -> [LocalVideoDTO] {
        localVideos.map(convertToLocalVideoDTO)
    }
    
    /// Converts a `LocalVideo` to a `LocalVideoDTO` object.
    ///
    /// This method transforms managed object into a plain data transfer object to be used outside the data layer and handles
    ///  decoding the stored body pose data from JSON.
    ///
    /// - Parameters localVideo: The `LocalVideo` managed object to convert.
    /// - Returns: a LocalVideoDTO containing the LocalVideos data.
    /// - Note: If body pose data cannot be decoded, an empty array will be used instead.
    private func convertToLocalVideoDTO(_ localVideo: LocalVideo) -> LocalVideoDTO {
        let bodyPoseFrames = try? JSONDecoder().decode([BodyPoseFrame].self, from: localVideo.bodyPoseFrameData ?? Data())
        return LocalVideoDTO(path: localVideo.path,
                      dateAdded: localVideo.dateAdded,
                      duration: localVideo.duration,
                      frameRate: localVideo.frameRate,
                      thumbnailData: localVideo.thumbnailData,
                      bodyPoseFrames: bodyPoseFrames ?? []
        )
    }
    
    /// Fetches the `LocalVideo` with the associated path.
    ///
    /// This method queries the Core Data store for a `LocalVideo` with matching path atrribute.
    ///
    /// - Parameters path: the file path relative to the users document's directory.
    /// - Returns: An optional `LocalVideo` if found, nil otherwise
    /// - Throws: `LocalVideoServiceError.failedToFetch` if the context fails to fetch.
    private func fetchLocalVideoBy(path: String) throws -> LocalVideo? {
        let fetchRequest = LocalVideo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "path == %@", path)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            throw LocalVideoServiceError.failedToFetch(error)
        }
        
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    /// Receives updated `LocalVideo` entities and publishes them as DTOs through the `localVideoPub` publisher.
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        let result = controller.fetchedObjects as? [LocalVideo] ?? []
        localVideoPub.send(convertLocalVideostoDTOs(result))
    }
}

enum LocalVideoServiceError: Error {
    case failedToFetch(Error)
    case failedToEncodeBodyPoseFrames(Error)
    case localVideoFailedToSave(Error)
    case localVideoEntityFailedToDelete(Error)
    case localVideoFileFailedToDelete(Error)
    case localVideoNotFound
}

