//
//  test.swift
//  riidaa
//
//  Created by Pierre on 2025/04/17.
//

import SwiftUI

struct test: View {
    var body: some View {
        ScrollView {
            test2(wt: .v)
        }
    }
}

struct test2: View {
    
    @State var wt: WordType
    
    var body: some View {
        HStack(alignment: .center, spacing: 30) {
            Text(wt.rawValue)
                .font(.title)
            VStack(alignment: .leading, spacing: 40) {
                ForEach(WordType.childrenMap[wt] ?? [], id:\.rawValue) { wt2 in
                    test2(wt: wt2)
                }
            }
        }
        .border(.red)
    }
}

#Preview {
    test()
}
