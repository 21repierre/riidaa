//
//  ParserList.swift
//  riidaa
//
//  Created by Pierre on 2025/04/18.
//

import SwiftUI

struct ParserList: View {
    
    @State var array: [[StructuredContent]]
    @State var prefix: String?
    
    var body: some View {
        if array.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading) {
                ForEach(array) { elems in
                    HStack(alignment: .top) {
                        if let prefix = prefix {
                            Text(prefix)
                        }
                        ListElement(array: elems)
                    }
                }
                .id(UUID())
            }
        }
    }
}

struct ListElement: View {
    
    @State var array: [StructuredContent]
    
    var body: some View {
        switch array.first {
        case .inlineContainer(_), .text(_):
            if array.count > 1 {
                HStack(spacing: 5) {
                    //                    Text("ca \(arr.count)")
                    ForEach(array) { elem in
                        switch elem {
                        case .text(let s):
                            ParserText(text: s.content)
                            //                            Text(s.content)
                            //                                .font(.callout)
                                .padding([.trailing], 5)
                        case .inlineContainer(let c):
                            ParserInlineContainer(element: c)
                        default:
                            Text("@dleI>\(elem)")
                            //                            EmptyView()
                            //                        DetailedView(structuredContent: elem)
                                .font(.callout)
                                .padding([.trailing], 5)
                        }
                        //                    DetailedView(structuredContent: elem)
                        //                        .font(.callout)
                        //                        .padding([.trailing], 5)
                    }
                    .id(UUID())
                }
            } else {
                DetailedView(structuredContent: array.first!)
                //                Text("le>\(arr)")
            }
        default:
            if let elem = array.first {
                switch elem {
                case .list(let list):
                    ParserList(array: list.content, prefix: list.prefix)
                case .numberedList(let list):
                    ParserNumberedList(array: list.content)
                    
                case .container(let container):
                    ParserContainer(element: container)
                case .link(let lnk):
                    ParserLink(link: lnk)
                default:
                    Text("@dle>\(elem)")
                    //                    EmptyView()
                }
            } else {
                Text("Empty")
                EmptyView()
            }
        }
    }
}

#Preview {
    ParserList(array: [[.text(StringContent(content: "test")),.text(StringContent(content: "test")),.text(StringContent(content: "test"))]], prefix: "-")
}
