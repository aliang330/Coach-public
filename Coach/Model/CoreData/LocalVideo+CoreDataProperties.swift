//
//  LocalVideo+CoreDataProperties.swift
//  
//
//  Created by Allen Liang on 2/23/25.
//
//

import Foundation
import CoreData


extension LocalVideo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalVideo> {
        return NSFetchRequest<LocalVideo>(entityName: "LocalVideo")
    }

    @NSManaged public var bodyPoseFrameData: Data?
    @NSManaged public var dateAdded: Date
    @NSManaged public var duration: Double
    @NSManaged public var frameRate: Double
    @NSManaged public var thumbnailData: Data?
    @NSManaged public var path: String

}
