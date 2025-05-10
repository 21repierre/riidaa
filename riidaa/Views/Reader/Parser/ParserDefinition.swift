//
//  ParserDefinition.swift
//  riidaa
//
//  Created by Pierre on 2025/05/10.
//

import SwiftUI

struct ParserDefinition: View {
    
    @State var desc: InflectionDescription
    
    var body: some View {
        VStack(alignment: .leading) {
            DetailedView(structuredContent: desc.description)
            Spacer()
        }
        .padding(.horizontal, 20)
        .navigationTitle("\(desc.short) form")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    ParserDefinition(desc: InflectionRule.ya.description)
}
