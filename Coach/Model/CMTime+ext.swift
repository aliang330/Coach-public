//
//  CMTime+ext.swift
//  Coach
//
//  Created by Allen Liang on 12/20/24.
//

import Foundation
import CoreMedia

extension CMTime: Codable {
    enum CodingKeys: String, CodingKey {
        case value
        case timescale
        case flags
        case epoch
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let value = try container.decode(Int64.self, forKey: .value)
        let timescale = try container.decode(Int32.self, forKey: .timescale)
        let flagsRawValue = try container.decode(UInt32.self, forKey: .flags)
        let flags = CMTimeFlags(rawValue: flagsRawValue)
        let epoch = try container.decode(Int64.self, forKey: .epoch)
        
        self.init(value: value, timescale: timescale, flags: flags, epoch: epoch)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
        try container.encode(timescale, forKey: .timescale)
        try container.encode(flags.rawValue, forKey: .flags)
        try container.encode(epoch, forKey: .epoch)
    }
}

extension CMTime {
    static func isDifferenceMoreThan(seconds: Double, time1: CMTime, time2: CMTime) -> Bool {
        let difference = CMTimeSubtract(time1, time2)
        let absoluteDifference = CMTimeMake(value: abs(difference.value), timescale: difference.timescale)
        let oneSecond = CMTime(seconds: seconds, preferredTimescale: absoluteDifference.timescale)
        return CMTimeCompare(absoluteDifference, oneSecond) == 1
    }
}
