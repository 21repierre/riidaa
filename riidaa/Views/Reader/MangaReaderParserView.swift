//
//  MangaReaderParserView.swift
//  riidaa
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
                ProgressView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
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
                    //                    .padding([.vertical], 5)
                }
                if let selectedElement = selectedElement {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading) {
                            ForEach(parsedText[selectedElement].results, id: \.self) { result in
                                ResultView(result: result)
                            }
                        }
                    }
                    .padding([.horizontal])
                    .frame(
                        minWidth: 0,
                        maxWidth: .infinity,
                        minHeight: 0,
                        maxHeight: .infinity,
                        alignment: .leading
                    )
                }
                Spacer()
            }
        }
        .padding()
        .onChange(of: line) { newLine in
            if newLine == "" {
                self.selectedElement = nil
                parsedText = []
            } else {
                parseLine(line: newLine)
            }
        }
        .onAppear {
            if line != "" {
                parseLine(line: line)
            }
        }
    }
}

extension MangaReaderParserView {
    
    func parseLine(line: String) {
        DispatchQueue.global(qos: .userInteractive).async {
            self.loading = true
            let results = Parser.parse(text: line)
            if results.count > 0 {
                selectedElement = nil
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
                TermDeinflection(term: TermDB(term: "君", reading: "きみ", definitionTags: [], wordTypes: [], score: 200, definitions: Data(), sequenceNumber: 1, termTags: [], dictionary: DictionaryDB(id: 1, revision: "", title: "", format: 3)), deinflection: Deinflection(text: "君", inflections: [], types: []))
            ]),
            ParsingResult(original: "は", results: [
                TermDeinflection(term: TermDB(term: "は", reading: "は", definitionTags: [], wordTypes: [], score: 200, definitions: Data(), sequenceNumber: 1, termTags: [], dictionary: DictionaryDB(id: 1, revision: "", title: "", format: 3)), deinflection: Deinflection(text: "は", inflections: [], types: []))
            ]),
            ParsingResult(original: "学校", results: [
                TermDeinflection(term: TermDB(term: "学校", reading: "がっこう", definitionTags: [], wordTypes: [], score: 200, definitions: Data(), sequenceNumber: 1, termTags: [], dictionary: DictionaryDB(id: 1, revision: "", title: "", format: 3)), deinflection: Deinflection(text: "学校", inflections: [], types: []))
            ]),
            ParsingResult(original: "を", results: [
                TermDeinflection(term: TermDB(term: "を", reading: "を", definitionTags: [], wordTypes: [], score: 200, definitions: Data(), sequenceNumber: 1, termTags: [], dictionary: DictionaryDB(id: 1, revision: "", title: "", format: 3)), deinflection: Deinflection(text: "を", inflections: [], types: []))
            ]),
            ParsingResult(original: "何だと", results: [
                TermDeinflection(term: TermDB(term: "何だと", reading: "なんだと", definitionTags: [], wordTypes: [], score: 200, definitions: Data(), sequenceNumber: 1, termTags: [], dictionary: DictionaryDB(id: 1, revision: "", title: "", format: 3)), deinflection: Deinflection(text: "何だと", inflections: [], types: []))
            ]),
            ParsingResult(original: "思っている", results: [
                TermDeinflection(
                    term: TermDB(
                        term: "思う",
                        reading: "おもう",
                        definitionTags: ["★", "priority form"],
                        wordTypes: [],
                        score: 200,
                        definitions:
                            "[{\"type\":\"structured-content\",\"content\":[{\"style\":{\"listStyleType\":\"\\\"＊\\\"\"},\"lang\":\"ja\",\"content\":[{\"tag\":\"li\",\"content\":[{\"data\":{\"code\":\"v5u\"},\"title\":\"Godan verb with 'u' ending\",\"style\":{\"fontSize\":\"0.8em\",\"color\":\"white\",\"cursor\":\"help\",\"borderRadius\":\"0.3em\",\"fontWeight\":\"bold\",\"marginRight\":\"0.25em\",\"padding\":\"0.2em 0.3em\",\"wordBreak\":\"keep-all\",\"verticalAlign\":\"text-bottom\",\"backgroundColor\":\"#565656\"},\"content\":\"5-dan\",\"tag\":\"span\"},{\"data\":{\"code\":\"vt\"},\"title\":\"transitive verb\",\"style\":{\"fontSize\":\"0.8em\",\"color\":\"white\",\"cursor\":\"help\",\"borderRadius\":\"0.3em\",\"fontWeight\":\"bold\",\"marginRight\":\"0.25em\",\"padding\":\"0.2em 0.3em\",\"wordBreak\":\"keep-all\",\"verticalAlign\":\"text-bottom\",\"backgroundColor\":\"#565656\"},\"content\":\"transitive\",\"tag\":\"span\"},{\"tag\":\"ol\",\"content\":[{\"data\":{\"sense-number\":\"1\"},\"style\":{\"paddingLeft\":\"0.25em\",\"listStyleType\":\"\\\"①\\\"\"},\"content\":[{\"tag\":\"ul\",\"data\":{\"content\":\"glossary\"},\"content\":[{\"tag\":\"li\",\"content\":\"to think\"},{\"tag\":\"li\",\"content\":\"to consider\"},{\"tag\":\"li\",\"content\":\"to believe\"},{\"tag\":\"li\",\"content\":\"to reckon\"}]},{\"data\":{\"content\":\"extra-info\"},\"style\":{\"marginLeft\":\"0.5em\"},\"content\":[{\"data\":{\"content\":\"sense-note\"},\"style\":{\"borderRadius\":\"0.4rem\",\"marginTop\":\"0.5rem\",\"borderWidth\":\"calc(3em / var(--font-size-no-units, 14))\",\"borderStyle\":\"none none none solid\",\"borderColor\":\"goldenrod\",\"padding\":\"0.5rem\",\"marginBottom\":\"0.5rem\",\"backgroundColor\":\"color-mix(in srgb, goldenrod 5%, transparent)\"},\"content\":[{\"tag\":\"div\",\"style\":{\"color\":\"#777\",\"fontStyle\":\"italic\",\"fontSize\":\"0.8em\"},\"content\":\"Note\"},{\"tag\":\"div\",\"style\":{\"marginLeft\":\"0.5rem\"},\"content\":\"想う has connotations of heart-felt\"}],\"tag\":\"div\"},{\"tag\":\"div\",\"content\":{\"data\":{\"sentence-key\":\"思う\",\"content\":\"example-sentence\",\"source\":\"143025\",\"source-type\":\"tat\"},\"style\":{\"borderRadius\":\"0.4rem\",\"marginTop\":\"0.5rem\",\"borderWidth\":\"calc(3em / var(--font-size-no-units, 14))\",\"borderStyle\":\"none none none solid\",\"borderColor\":\"var(--text-color, var(--fg, #333))\",\"padding\":\"0.5rem\",\"marginBottom\":\"0.5rem\",\"backgroundColor\":\"color-mix(in srgb, var(--text-color, var(--fg, #333)) 5%, transparent)\"},\"content\":[{\"data\":{\"content\":\"example-sentence-a\"},\"style\":{\"fontSize\":\"1.3em\"},\"content\":[\"晴れだと\",{\"tag\":\"span\",\"style\":{\"color\":\"color-mix(in srgb, lime, var(--text-color, var(--fg, #333)))\"},\"content\":\"思う\"},\"よ。\"],\"tag\":\"div\"},{\"data\":{\"content\":\"example-sentence-b\"},\"style\":{\"fontSize\":\"0.8em\"},\"content\":[\"I think it will be sunny.\",{\"data\":{\"content\":\"attribution-footnote\"},\"style\":{\"marginLeft\":\"0.25rem\",\"color\":\"#777\",\"verticalAlign\":\"top\",\"fontSize\":\"0.8em\"},\"content\":\"[1]\",\"tag\":\"span\"}],\"tag\":\"div\"}],\"tag\":\"div\"}}],\"tag\":\"div\"}],\"tag\":\"li\"},{\"data\":{\"sense-number\":\"2\"},\"style\":{\"paddingLeft\":\"0.25em\",\"listStyleType\":\"\\\"②\\\"\"},\"content\":{\"tag\":\"ul\",\"data\":{\"content\":\"glossary\"},\"content\":[{\"tag\":\"li\",\"content\":\"to think (of doing)\"},{\"tag\":\"li\",\"content\":\"to plan (to do)\"}]},\"tag\":\"li\"},{\"data\":{\"sense-number\":\"3\"},\"style\":{\"paddingLeft\":\"0.25em\",\"listStyleType\":\"\\\"③\\\"\"},\"content\":[{\"tag\":\"ul\",\"data\":{\"content\":\"glossary\"},\"content\":[{\"tag\":\"li\",\"content\":\"to judge\"},{\"tag\":\"li\",\"content\":\"to assess\"},{\"tag\":\"li\",\"content\":\"to regard\"}]},{\"data\":{\"content\":\"extra-info\"},\"style\":{\"marginLeft\":\"0.5em\"},\"content\":{\"tag\":\"div\",\"content\":{\"data\":{\"sentence-key\":\"思います\",\"content\":\"example-sentence\",\"source\":\"146024\",\"source-type\":\"tat\"},\"style\":{\"borderRadius\":\"0.4rem\",\"marginTop\":\"0.5rem\",\"borderWidth\":\"calc(3em / var(--font-size-no-units, 14))\",\"borderStyle\":\"none none none solid\",\"borderColor\":\"var(--text-color, var(--fg, #333))\",\"padding\":\"0.5rem\",\"marginBottom\":\"0.5rem\",\"backgroundColor\":\"color-mix(in srgb, var(--text-color, var(--fg, #333)) 5%, transparent)\"},\"content\":[{\"data\":{\"content\":\"example-sentence-a\"},\"style\":{\"fontSize\":\"1.3em\"},\"content\":[\"状況は深刻だと\",{\"tag\":\"span\",\"style\":{\"color\":\"color-mix(in srgb, lime, var(--text-color, var(--fg, #333)))\"},\"content\":\"思います\"},\"か。\"],\"tag\":\"div\"},{\"data\":{\"content\":\"example-sentence-b\"},\"style\":{\"fontSize\":\"0.8em\"},\"content\":[\"Do you regard the situation as serious?\",{\"data\":{\"content\":\"attribution-footnote\"},\"style\":{\"marginLeft\":\"0.25rem\",\"color\":\"#777\",\"verticalAlign\":\"top\",\"fontSize\":\"0.8em\"},\"content\":\"[2]\",\"tag\":\"span\"}],\"tag\":\"div\"}],\"tag\":\"div\"}},\"tag\":\"div\"}],\"tag\":\"li\"},{\"data\":{\"sense-number\":\"4\"},\"style\":{\"paddingLeft\":\"0.25em\",\"listStyleType\":\"\\\"④\\\"\"},\"content\":[{\"tag\":\"ul\",\"data\":{\"content\":\"glossary\"},\"content\":[{\"tag\":\"li\",\"content\":\"to imagine\"},{\"tag\":\"li\",\"content\":\"to suppose\"},{\"tag\":\"li\",\"content\":\"to dream\"}]},{\"data\":{\"content\":\"extra-info\"},\"style\":{\"marginLeft\":\"0.5em\"},\"content\":{\"tag\":\"div\",\"content\":{\"data\":{\"sentence-key\":\"思っている\",\"content\":\"example-sentence\",\"source\":\"185953\",\"source-type\":\"tat\"},\"style\":{\"borderRadius\":\"0.4rem\",\"marginTop\":\"0.5rem\",\"borderWidth\":\"calc(3em / var(--font-size-no-units, 14))\",\"borderStyle\":\"none none none solid\",\"borderColor\":\"var(--text-color, var(--fg, #333))\",\"padding\":\"0.5rem\",\"marginBottom\":\"0.5rem\",\"backgroundColor\":\"color-mix(in srgb, var(--text-color, var(--fg, #333)) 5%, transparent)\"},\"content\":[{\"data\":{\"content\":\"example-sentence-a\"},\"style\":{\"fontSize\":\"1.3em\"},\"content\":[{\"tag\":\"ruby\",\"content\":[\"我々\",{\"tag\":\"rt\",\"content\":\"われわれ\"}]},\"が\",{\"data\":{\"content\":\"example-keyword\"},\"style\":{\"color\":\"color-mix(in srgb, lime, var(--text-color, var(--fg, #333)))\"},\"content\":[{\"tag\":\"ruby\",\"content\":[\"思\",{\"tag\":\"rt\",\"content\":\"おも\"}]},\"っている\"],\"tag\":\"span\"},\"ほどには、それほど\",{\"tag\":\"ruby\",\"content\":[\"我々\",{\"tag\":\"rt\",\"content\":\"われわれ\"}]},\"は\",{\"tag\":\"ruby\",\"content\":[\"幸\",{\"tag\":\"rt\",\"content\":\"こう\"}]},{\"tag\":\"ruby\",\"content\":[\"福\",{\"tag\":\"rt\",\"content\":\"ふく\"}]},\"でもなければ、\",{\"tag\":\"ruby\",\"content\":[\"不\",{\"tag\":\"rt\",\"content\":\"ふ\"}]},{\"tag\":\"ruby\",\"content\":[\"幸\",{\"tag\":\"rt\",\"content\":\"こう\"}]},\"でもない。\"],\"tag\":\"div\"},{\"data\":{\"content\":\"example-sentence-b\"},\"style\":{\"fontSize\":\"0.8em\"},\"content\":[\"We are never as happy or as unhappy as we imagine.\",{\"data\":{\"content\":\"attribution-footnote\"},\"style\":{\"marginLeft\":\"0.25rem\",\"color\":\"#777\",\"verticalAlign\":\"top\",\"fontSize\":\"0.8em\"},\"content\":\"[3]\",\"tag\":\"span\"}],\"tag\":\"div\"}],\"tag\":\"div\"}},\"tag\":\"div\"}],\"tag\":\"li\"},{\"data\":{\"sense-number\":\"5\"},\"style\":{\"paddingLeft\":\"0.25em\",\"listStyleType\":\"\\\"⑤\\\"\"},\"content\":{\"tag\":\"ul\",\"data\":{\"content\":\"glossary\"},\"content\":[{\"tag\":\"li\",\"content\":\"to expect\"},{\"tag\":\"li\",\"content\":\"to look forward to\"}]},\"tag\":\"li\"},{\"data\":{\"sense-number\":\"6\"},\"style\":{\"paddingLeft\":\"0.25em\",\"listStyleType\":\"\\\"⑥\\\"\"},\"content\":{\"tag\":\"ul\",\"data\":{\"content\":\"glossary\"},\"content\":[{\"tag\":\"li\",\"content\":\"to feel\"},{\"tag\":\"li\",\"content\":\"to be (in a state of mind)\"},{\"tag\":\"li\",\"content\":\"to desire\"},{\"tag\":\"li\",\"content\":\"to want\"}]},\"tag\":\"li\"},{\"data\":{\"sense-number\":\"7\"},\"style\":{\"paddingLeft\":\"0.25em\",\"listStyleType\":\"\\\"⑦\\\"\"},\"content\":{\"tag\":\"ul\",\"data\":{\"content\":\"glossary\"},\"content\":[{\"tag\":\"li\",\"content\":\"to care (deeply) for\"},{\"tag\":\"li\",\"content\":\"to yearn for\"},{\"tag\":\"li\",\"content\":\"to worry about\"},{\"tag\":\"li\",\"content\":\"to love\"}]},\"tag\":\"li\"},{\"data\":{\"sense-number\":\"8\"},\"style\":{\"paddingLeft\":\"0.25em\",\"listStyleType\":\"\\\"⑧\\\"\"},\"content\":{\"tag\":\"ul\",\"data\":{\"content\":\"glossary\"},\"content\":[{\"tag\":\"li\",\"content\":\"to recall\"},{\"tag\":\"li\",\"content\":\"to remember\"}]},\"tag\":\"li\"}]}]},{\"data\":{\"content\":\"forms\"},\"style\":{\"marginTop\":\"0.5rem\"},\"content\":[{\"title\":\"spelling and reading variants\",\"style\":{\"fontSize\":\"0.8em\",\"color\":\"white\",\"cursor\":\"help\",\"borderRadius\":\"0.3em\",\"fontWeight\":\"bold\",\"marginRight\":\"0.25em\",\"padding\":\"0.2em 0.3em\",\"wordBreak\":\"keep-all\",\"verticalAlign\":\"text-bottom\",\"backgroundColor\":\"#565656\"},\"content\":\"forms\",\"tag\":\"span\"},{\"tag\":\"div\",\"style\":{\"marginTop\":\"0.2em\"},\"content\":{\"tag\":\"table\",\"content\":[{\"tag\":\"tr\",\"content\":[{\"tag\":\"th\"},{\"tag\":\"th\",\"style\":{\"fontSize\":\"1.2em\",\"fontWeight\":\"normal\",\"textAlign\":\"center\"},\"content\":\"思う\"},{\"tag\":\"th\",\"style\":{\"fontSize\":\"1.2em\",\"fontWeight\":\"normal\",\"textAlign\":\"center\"},\"content\":\"想う\"},{\"tag\":\"th\",\"style\":{\"fontSize\":\"1.2em\",\"fontWeight\":\"normal\",\"textAlign\":\"center\"},\"content\":\"憶う\"},{\"tag\":\"th\",\"style\":{\"fontSize\":\"1.2em\",\"fontWeight\":\"normal\",\"textAlign\":\"center\"},\"content\":\"念う\"}]},{\"tag\":\"tr\",\"content\":[{\"tag\":\"th\",\"style\":{\"fontWeight\":\"normal\"},\"content\":\"おもう\"},{\"tag\":\"td\",\"style\":{\"textAlign\":\"center\"},\"content\":{\"title\":\"high priority form\",\"style\":{\"cursor\":\"help\",\"background\":\"radial-gradient(green 50%, white 100%)\",\"clipPath\":\"circle()\",\"padding\":\"0 0.5em\",\"fontWeight\":\"bold\",\"color\":\"white\"},\"content\":\"△\",\"tag\":\"div\"}},{\"tag\":\"td\",\"style\":{\"textAlign\":\"center\"},\"content\":{\"title\":\"valid form/reading combination\",\"style\":{\"cursor\":\"help\",\"background\":\"radial-gradient(var(--text-color, var(--fg, #333)) 50%, white 100%)\",\"clipPath\":\"circle()\",\"padding\":\"0 0.5em\",\"fontWeight\":\"bold\",\"color\":\"var(--background-color, var(--canvas, #f8f9fa))\"},\"content\":\"◇\",\"tag\":\"div\"}},{\"tag\":\"td\",\"style\":{\"textAlign\":\"center\"},\"content\":{\"title\":\"rarely used form\",\"style\":{\"cursor\":\"help\",\"background\":\"radial-gradient(purple 50%, white 100%)\",\"clipPath\":\"circle()\",\"padding\":\"0 0.5em\",\"fontWeight\":\"bold\",\"color\":\"white\"},\"content\":\"▽\",\"tag\":\"div\"}},{\"tag\":\"td\",\"style\":{\"textAlign\":\"center\"},\"content\":{\"title\":\"rarely used form\",\"style\":{\"cursor\":\"help\",\"background\":\"radial-gradient(purple 50%, white 100%)\",\"clipPath\":\"circle()\",\"padding\":\"0 0.5em\",\"fontWeight\":\"bold\",\"color\":\"white\"},\"content\":\"▽\",\"tag\":\"div\"}}]}]}}],\"tag\":\"li\"}],\"tag\":\"ul\"},{\"data\":{\"content\":\"attribution\"},\"style\":{\"fontSize\":\"0.7em\",\"textAlign\":\"right\"},\"content\":[{\"tag\":\"a\",\"href\":\"https://www.edrdg.org/jmwsgi/entr.py?svc=jmdict&q=1589350\",\"content\":\"JMdict\"},\" | Tatoeba \",{\"tag\":\"a\",\"href\":\"https://tatoeba.org/en/sentences/show/143025\",\"content\":\"[1]\"},{\"tag\":\"a\",\"href\":\"https://tatoeba.org/en/sentences/show/146024\",\"content\":\"[2]\"},{\"tag\":\"a\",\"href\":\"https://tatoeba.org/en/sentences/show/185953\",\"content\":\"[3]\"}],\"tag\":\"div\"}]}]".data(using: .utf8)!,
                        sequenceNumber: 1,
                        termTags: [],
                        dictionary: DictionaryDB(id: 1, revision: "", title: "Jitandex", format: 3)
                    ),
                    deinflection: Deinflection(text: "思っている", inflections: [
                        InflectionRule.iru, InflectionRule.te
                    ], types: []))
            ]),
            ParsingResult(original: "のか", results: [
                TermDeinflection(term: TermDB(term: "のか", reading: "のか", definitionTags: [], wordTypes: [], score: 200, definitions: Data(), sequenceNumber: 1, termTags: [], dictionary: DictionaryDB(id: 1, revision: "", title: "", format: 3)), deinflection: Deinflection(text: "のか", inflections: [], types: []))
            ]),
            ParsingResult(original: "ね", results: [
                TermDeinflection(term: TermDB(term: "ね", reading: "ね", definitionTags: [], wordTypes: [], score: 200, definitions: Data(), sequenceNumber: 1, termTags: [], dictionary: DictionaryDB(id: 1, revision: "", title: "", format: 3)), deinflection: Deinflection(text: "ね", inflections: [], types: []))
            ]),
        ],
        selectedElement: 5
    )
}


struct ResultView: View {
    @State var result: TermDeinflection
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(result.term.term) (\(result.term.reading))")
                .font(.title)
            if !result.deinflection.inflections.isEmpty {
                HStack(spacing: 0) {
                    Text("🚂")
                        .font(.callout)
                    ForEach(result.deinflection.inflections.reversed()) { rule in
                        Text("«")
                            .font(.callout)
                            .padding([.horizontal], 3)
                        Text(rule.rawValue)
                            .font(.callout)
                    }
                }
                .foregroundStyle(Color(.gray))
            }
            HStack {
                ForEach(result.term.definitionTags) { tag in
                    if tag != "" {
                        Text(tag)
                            .font(.footnote)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color.cyan)
                            .roundedCorners(5, corners: .allCorners)
                    }
                }
                Text(result.term.dictionary.title)
                    .font(.footnote)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.purple)
                    .roundedCorners(5, corners: .allCorners)
            }
            //            Text(String(data: result.term.definitions, encoding: .utf8)!)
            ForEach(result.term.parseDefinition, id: \.self) { definition in
                switch (definition) {
                case .text(let s):
                    Text(s.content)
                        .padding(.bottom, 10)
                case .detailed(let d):
                    DetailedView(structuredContent: d)
                        .padding(.bottom, 10)
                        .onAppear {
//                            print(d)
                        }
                default:
                    Text("TO DO")
                        .padding(.bottom, 10)
                }
            }
        }
        .onAppear {
            //            print(result.term.parseDefinition)
        }
    }
}

struct DetailedView: View, Identifiable {
    var id: UUID = UUID()
    
    @State var structuredContent: StructuredContent
    
    var body: some View {
        switch structuredContent {
        case .text(let string):
            displayText(text: string.content)
//            Text(string.content)
//                .font(.footnote)
        case .array(let array):
            displayList(arr: array, prefix: nil)
        case .newline:
            Spacer()
        case .link(let l):
            DetailedView(structuredContent: l.data)
                .onTapGesture {
                    print("Open link \(l.href)")
                }
        case .container(let c):
            DetailedView(structuredContent: c.data)
                .background(c.backgroundColor)
                .roundedCorners(5, corners: .allCorners)
        case .inlineContainer(let c):
            DetailedView(structuredContent: c.data)
                .font(c.font)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(c.backgroundColor)
                .roundedCorners(5, corners: .allCorners)
        case .table(let table):
            DetailedView(structuredContent: table.data)
        case .numberedList(let c):
//            EmptyView()
            displayNumberedList(arr: c.content)
        case .list(let c):
//            EmptyView()
            displayList(arr: c.content, prefix: c.prefix)
        }
    }
    
    @ViewBuilder
    func displayContainer(elem: StructuredContentContainer) -> some View {
        switch elem.data {
        case .array(let array):
            displayList(arr: array, prefix: nil)
        case .text(let text):
            displayText(text: text.content)
        case .container(let container):
            displayContainer(elem: container)
        case .list(let list):
            displayList(arr: list.content, prefix: list.prefix)
        case .link(let link):
            displayLink(link: link)
        default:
            Text("@c>\(elem.data)")
//            EmptyView()
        }
    }
    
    @ViewBuilder
    func displayText(text: String) -> some View {
        Text("\(text)")
    }
    
    @ViewBuilder
    func displayInlineElement(elem: StructuredContentContainer) -> some View {
        switch elem.data {
        case .text(let s):
            displayText(text: s.content)
                .font(elem.font)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(elem.backgroundColor)
                .roundedCorners(5, corners: .allCorners)
        case .array(let arr):
            displayList(arr: arr, prefix: nil)
        case .container(let container):
            displayContainer(elem: container)
        default:
            Text("@ic>\(elem.data)")
        }
    }
    
    @ViewBuilder
    func displayLink(link: LinkContent) -> some View {
        switch link.data {
        case .text(let text):
            displayText(text: text.content)
        case .array(let arr):
            displayList(arr: arr, prefix: nil)
        case .container(let container):
            displayContainer(elem: container)
        default:
            Text("@lnk>\(link.data)")
        }
    }
    
    @ViewBuilder
    func displayListElement(arr: [StructuredContent]) -> some View {
        switch arr.first {
        case .inlineContainer(_), .text(_):
            if arr.count > 1 {
                HStack(spacing: 5) {
//                    Text("ca \(arr.count)")
                    ForEach(arr) { elem in
                        switch elem {
                        case .text(let s):
                            displayText(text: s.content)
//                            Text(s.content)
//                                .font(.callout)
                                .padding([.trailing], 5)
                        case .inlineContainer(let c):
                            displayInlineElement(elem: c)
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
                DetailedView(structuredContent: arr.first!)
//                Text("le>\(arr)")
            }
        default:
            if let elem = arr.first {
                switch elem {
                case .list(let list):
                    displayList(arr: list.content, prefix: list.prefix)
                case .numberedList(let list):
                    displayNumberedList(arr: list.content)
                    
                case .container(let container):
                    displayContainer(elem: container)
                case .link(let lnk):
                    displayLink(link: lnk)
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
    
    @ViewBuilder
    func displayList(arr: [[StructuredContent]], prefix: String?) -> some View {
        if arr.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading) {
//                Text("\(arr.count) \(arr)")
                ForEach(arr) { elems in
                    HStack(alignment: .top) {
                        if let prefix = prefix {
                            Text(prefix)
                        }
                        displayListElement(arr: elems)
                    }
                }
                .id(UUID())
            }
        }
    }
    
    @ViewBuilder
    func displayNumberedList(arr: [[StructuredContent]]) -> some View {
        if arr.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading) {
//                Text("n\(arr.count)")
                ForEach(Array(arr.enumerated()), id: \.offset) { i, elems in
                    HStack(alignment: .top) {
                        CircularText(text: "\(i+1)")
                            .padding([.top], 2)
                        displayListElement(arr: elems)
                    }
                }
                .id(UUID())
            }
        }
    }
    
}
