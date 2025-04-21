//
//  SelectedCheckCircle.swift
//  Coach
//
//  Created by Allen Liang on 12/5/24.
//

import SwiftUI

struct SelectedCheckCircle: View {
    var body: some View {
        Circle()
            .fill(.white)
            .overlay {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .blue)
                    .padding(2)
            }
    }
}

#Preview {
    SelectedCheckCircle()
        .frame(width: 40, height: 40)
}
