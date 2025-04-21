//
//  Double+ext.swift
//  Coach
//
//  Created by Allen Liang on 3/4/25.
//

import Foundation

extension Double {
    var twoDecimalPlaces: String {
        return String(format: "%.2f", self)
    }
}
