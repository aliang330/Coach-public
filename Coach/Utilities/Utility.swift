//
//  Utility.swift
//  Coach
//
//  Created by Allen Liang on 12/4/24.
//

import Foundation

struct Utility {
    
    static func timeString(from seconds: Int) -> String {
        let (h, m , s) = secondsToHoursMinutesSeconds(seconds: seconds)
        
        var timeString = ""
        if h > 0 {
            if h < 10 {
                timeString += "0\(h):"
            } else {
                timeString += "\(h):"
            }
            if m < 10 {
                timeString += "0\(m):"
            } else {
                timeString += "\(m):"
            }
        } else {
            if m < 10 {
                timeString += "0\(m):"
            } else {
                timeString += "\(m):"
            }
        }
        
        if s < 10 {
            timeString += "0\(s)"
        } else{
            timeString += "\(s)"
        }
        
        return timeString
    }
    
    static func timeString(from seconds: Double) -> String {
        let (h, m , s) = secondsToHoursMinutesSeconds(seconds: Int(seconds))
        
        var timeString = ""
        if h > 0 {
            if h < 10 {
                timeString += "0\(h):"
            } else {
                timeString += "\(h):"
            }
            if m < 10 {
                timeString += "0\(m):"
            } else {
                timeString += "\(m):"
            }
        } else {
            if m < 10 {
                timeString += "0\(m):"
            } else {
                timeString += "\(m):"
            }
        }
        
        if s < 10 {
            timeString += "0\(s)"
        } else{
            timeString += "\(s)"
        }
        
        return timeString
    }

    static func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    static func formattedDateString(from date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d, h:mm a"
        
        return df.string(from: date)
    }
    
    static func printExecutionTime<T>(name: String, _ block: () -> T) -> T {
        let startTime = Date()
        
        let result = block()
        let time = Date().timeIntervalSince(startTime)
        let ms = Int(time*1000)
        print("\(name): \(ms)ms")
        return result
    }
}


