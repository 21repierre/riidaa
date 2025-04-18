//
//  ParserLink.swift
//  riidaa
//
//  Created by Pierre on 2025/04/18.
//

import SwiftUI

struct ParserLink: View {
    
    @State var link: LinkContent
    
    var body: some View {
        switch link.data {
        case .text(let text):
            ParserText(text: text.content)
        case .array(let arr):
            ParserList(array: arr, prefix: nil)
        case .container(let container):
            ParserContainer(element: container)
        default:
            Text("@lnk>\(link.data)")
        }
    }
}

#Preview {
    ParserLink(link: LinkContent(href: "https://repierre.dev", data: .newline))
}
