//
//  MangaReaderBoxes.swift
//  redaa
//
//  Created by Pierre on 2025/02/20.
//

import SwiftUI

struct MangaReaderBoxes: View {
    
    var boxes: [PageBoxModel]
    var scale: Double
    var offset: Double
    
    @Binding var currentLine: String
    
    var body: some View {
        ForEach(boxes, id: \.self) { box in
            Rectangle()
                .fill(Color.red.opacity(0.3))
                .border(Color.red, width: 1)
                .rotationEffect(Angle(degrees: box.rotation))
                .frame(
                    width: Double(box.width) * scale,
                    height: Double(box.height) * scale
                )
                .position(
                    x: Double(box.x + box.width / 2) * scale,
                    y: Double(box.y + box.height / 2) * scale + offset
                )
                .onTapGesture {
                    currentLine = box.text
                }
        }
    }
}

