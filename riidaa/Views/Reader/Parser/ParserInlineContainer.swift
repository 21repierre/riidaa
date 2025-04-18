//
//  ParserInlineContainer.swift
//  riidaa
//
//  Created by Pierre on 2025/04/18.
//

import SwiftUI

struct ParserInlineContainer: View {
    
    @State var element: StructuredContentContainer
    
    var body: some View {
        switch element.data {
        case .text(let s):
            ParserText(text: s.content)
                .font(element.font)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(element.backgroundColor)
                .roundedCorners(5, corners: .allCorners)
        case .array(let arr):
            ParserList(array: arr, prefix: nil)
        case .container(let container):
            ParserContainer(element: container)
        default:
            Text("@ic>\(element.data)")
        }
    }
}

#Preview {
    ParserInlineContainer(element: StructuredContentContainer(data: .newline, tag: ""))
}
