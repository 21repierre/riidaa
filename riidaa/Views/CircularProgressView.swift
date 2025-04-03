//
//  CircularProgressView.swift
//  riidaa
//
//  Created by Thulani Mtetwa on 2023/03/14.
//
import SwiftUI

struct CircularProgressView: View {
    let progress: Int
    let progressMax: Int
    
    var progressPercent: CGFloat {
        return max(min(CGFloat(progress) / CGFloat(progressMax == 0 ? 1 : progressMax), 1.0), 0.0)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 10)
                .opacity(0.1)
                .foregroundColor(.blue)
            
            Circle()
                .trim(from: 0.0, to: progressPercent)
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
            
            Text("\(progress)/\(progressMax)")
                .font(.system(size: 32))
        }
    }
}

#Preview {
    CircularProgressView(progress: 60, progressMax: 100)
}
