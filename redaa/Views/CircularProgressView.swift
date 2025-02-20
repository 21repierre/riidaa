//
//  CircularProgressView.swift
//  ProgressView
//
//  Created by Thulani Mtetwa on 2023/03/14.
//
import SwiftUI

struct CircularProgressView: View {
  let progress: CGFloat

  var body: some View {
    ZStack {
      // Background for the progress bar
      Circle()
        .stroke(lineWidth: 10)
        .opacity(0.1)
        .foregroundColor(.blue)

      // Foreground or the actual progress bar
      Circle()
        .trim(from: 0.0, to: min(progress, 1.0))
        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
        .foregroundColor(.blue)
        .rotationEffect(Angle(degrees: 270.0))
        .animation(.linear, value: progress)
    }
  }
}
