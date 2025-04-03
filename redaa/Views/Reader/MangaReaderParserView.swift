//
//  MangaReaderParserView.swift
//  redaa
//
//  Created by Pierre on 2025/03/27.
//

import SwiftUI

struct MangaReaderParserView: View {
    
    let line: String
    @State var parsedText: [ParsingResult] = []
    @State var selectedElement: Int?
    @State var loading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if loading {
                Text("loading...")
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(Array(parsedText.enumerated()), id: \.element) { index, element in
                            Text(element.original)
                                .font(.largeTitle)
                                .padding([.horizontal], 4)
                                .padding([.vertical], 7)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(selectedElement == index ? Color.blue.opacity(0.3) : Color.clear)
                                .cornerRadius(10)
                                .onTapGesture {
                                    selectedElement = index
                                }
                        }
                    }
                    .padding([.vertical], 5)
                }
                if let selectedElement = selectedElement {
                    Text(parsedText[selectedElement].original)
                }
                Spacer()
            }
        }
        .onChange(of: line) { newLine in
            if line == "" {
                parsedText = []
            } else {
                parseLine(line: newLine)
            }
        }
        .onAppear {
            parseLine(line: line)
        }
    }
}

extension MangaReaderParserView {
    
    func parseLine(line: String) {
        DispatchQueue.global(qos: .userInteractive).async {
            self.loading = true
            let results = Parser.parse(text: line)
            print(results)
            selectedElement = nil
            if results.count > 0 {
                parsedText = results
            }
            self.loading = false
        }
    }
    
}

#Preview {
    MangaReaderParserView(
        line: "君は学校を何だと思っているのかね",
        parsedText: [
            ParsingResult(original: "君", results: [
//                TermDeinflection(term: , deinflection: <#T##Deinflection#>)
            ]),
            ParsingResult(original: "は", results: []),
            ParsingResult(original: "学校", results: []),
            ParsingResult(original: "を", results: []),
            ParsingResult(original: "何だと", results: []),
            ParsingResult(original: "思っている", results: []),
            ParsingResult(original: "のか", results: []),
            ParsingResult(original: "ね", results: []),
        ]
    ).onAppear {
    }
}
