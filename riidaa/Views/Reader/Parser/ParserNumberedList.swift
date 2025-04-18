//
//  ParserNumberedList.swift
//  riidaa
//
//  Created by Pierre on 2025/04/18.
//

import SwiftUI

struct ParserNumberedList: View {
    
    @State var array: [[StructuredContent]]
    
    var body: some View {
        if array.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading) {
                ForEach(Array(array.enumerated()), id: \.offset) { i, elems in
                    HStack(alignment: .top) {
                        CircularText(text: "\(i+1)")
                            .padding([.top], 2)
                        ListElement(array: elems)
                    }
                }
                .id(UUID())
            }
        }
    }
}

#Preview {
    ParserNumberedList(array: [[]])
}
