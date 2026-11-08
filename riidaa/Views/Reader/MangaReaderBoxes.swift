//
//  MangaReaderBoxes.swift
//  riidaa
//
//  Created by Pierre on 2025/02/20.
//

import SwiftUI

struct SelectedLine: Equatable {
    let text: String
    let page: Int64
    var box: CGRect? = nil
}

struct MangaReaderBoxes: View {

    @EnvironmentObject var settings: SettingsModel

    var boxes: [PageBoxModel]
    var pageNumber: Int64
    var scale: Double
    var offsetX: Double
    var offsetY: Double

    @Binding var currentLine: SelectedLine?

    private func select(_ box: PageBoxModel) {
        currentLine = SelectedLine(
            text: box.text, page: pageNumber,
            box: CGRect(x: Int(box.x), y: Int(box.y), width: Int(box.width), height: Int(box.height))
        )
    }

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
            .hoverEffect(.highlight)
            .rotationEffect(Angle(degrees: box.rotation))
            .offset(
                x: Double(box.x + box.width / 2) * scale - offsetX,
                y: Double(box.y + box.height / 2) * scale - offsetY
            )
            .highPriorityGesture(SpatialTapGesture(count: 1).onEnded { _ in
                select(box)
            })
            .accessibilityElement()
            .accessibilityLabel(box.text)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { select(box) }
        }
    }
}
