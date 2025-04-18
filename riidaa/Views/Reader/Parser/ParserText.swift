//
//  ParserText.swift
//  riidaa
//
//  Created by Pierre on 2025/04/18.
//

import SwiftUI

struct ParserText: View {
    
    @State var text: String
    
    var body: some View {
        Text("\(text)")
    }
}

#Preview {
    ParserText(text: "blabla")
}
