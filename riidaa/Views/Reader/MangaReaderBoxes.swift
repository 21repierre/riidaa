//
//  MangaReaderBoxes.swift
//  riidaa
//
//  Created by Pierre on 2025/02/20.
//

import SwiftUI

struct MangaReaderBoxes: View {
    
    var boxes: [PageBoxModel]
    var scale: Double
    var offsetX: Double
    var offsetY: Double
    
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
                .offset(
                    x: Double(box.x + box.width / 2) * scale - offsetX,
                    y: Double(box.y + box.height / 2) * scale - offsetY
                )
                .onTapGesture {
                    currentLine = box.text
                }
        }
    }
}

