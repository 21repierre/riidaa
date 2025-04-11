//
//  CircularText.swift
//  riidaa
//
//  Created by Pierre on 2025/04/05.
//

import SwiftUI

struct CircularText: View {

    let text: String
    @State private var radius: CGFloat = .zero

    var body: some View {
        return ZStack {
            Text(text)
                .font(.footnote)
                .padding(1)
                .background(GeometryReader { proxy in Color.clear.onAppear() { radius = max(proxy.size.width, proxy.size.height) } }.hidden())
            
            if (!radius.isZero) {
                Circle().strokeBorder().frame(width: radius, height: radius)
            }
        }
     
    }
}


#Preview {
    CircularText(text: "1")
}
