//
//  ALEdgeOffset.swift
//  Coach
//
//  Created by Allen Liang on 12/8/24.
//

import Foundation
import SwiftUI

struct ALEdgeOffset {
    let top: CGFloat?
    let bottom: CGFloat?
    let leading: CGFloat?
    let trailing: CGFloat?
    
    static var zero: ALEdgeOffset { .init(top: 0, bottom: 0, leading: 0, trailing: 0) }
    static var nilSet: ALEdgeOffset { .init(top: nil, bottom: nil, leading: nil, trailing: nil) }
    
    init(top: CGFloat? = nil, bottom: CGFloat? = nil, leading: CGFloat? = nil, trailing: CGFloat? = nil) {
        self.top = top
        self.bottom = bottom
        self.leading = leading
        self.trailing = trailing
    }
    
    func override(override: ALEdgeOffset?) -> ALEdgeOffset {
        if let override = override {
            return ALEdgeOffset(top: override.top ?? self.top,
                                         bottom: override.bottom ?? self.bottom,
                                         leading: override.leading ?? self.leading,
                                         trailing: override.trailing ?? self.trailing)
        } else {
            return self
        }
    }
}

extension View {
    func edgeOffset(_ offset: ALEdgeOffset) -> some View {
        self
            .padding(.top, offset.top)
            .padding(.bottom, offset.bottom)
            .padding(.leading, offset.leading)
            .padding(.trailing, offset.trailing)
    }
}
