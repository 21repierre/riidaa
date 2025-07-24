//
//  MangaReaderBoxes.swift
//  riidaa
//
//  Created by Pierre on 2025/02/20.
//

import SwiftUI

struct MangaReaderBoxes: View {
    
    @EnvironmentObject var settings: SettingsModel
    
    var boxes: [PageBoxModel]
    var scale: Double
    var offsetX: Double
    var offsetY: Double
    
    @Binding var currentLine: String?
    
    var body: some View {
        ForEach(boxes, id: \.self) { box in
            ZStack {
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .allowsHitTesting(true)
                
                Rectangle()
                    .fill(settings.backgroundColorEnabled ? settings.backgroundColor.wrappedValue : Color.clear)
                    .border(settings.borderColorEnabled ? settings.borderColor.wrappedValue : Color.clear, width: settings.borderSize)
            }
            .frame(
                width: Double(box.width) * scale + settings.padding,
                height: Double(box.height) * scale + settings.padding
            )
            .offset(
                x: Double(box.x + box.width / 2) * scale - offsetX,
                y: Double(box.y + box.height / 2) * scale - offsetY
            )
            .rotationEffect(Angle(degrees: box.rotation))
            .highPriorityGesture(SpatialTapGesture(count: 1).onEnded { _ in
                    currentLine = box.text
            })
        }
    }
}
