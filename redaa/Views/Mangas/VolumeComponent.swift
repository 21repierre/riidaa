//
//  VolumeComponent.swift
//  redaa
//
//  Created by Pierre on 2025/02/17.
//

import SwiftUI

struct VolumeComponent: View {
    
    @ObservedObject var volume: MangaVolumeModel
    
    var body: some View {
        let totalPages = volume.pages.count
        NavigationLink(destination: MangaReader(volume: .init(get: {
            return volume
        }, set: {_ in}), currentPage: Int(volume.lastReadPage))) {
            VStack {
                Text("Volume \(volume.number)")
                Text("\(volume.lastReadPage+1)/\(totalPages)")
            }
        }
    }
}
//
//#Preview {
//    VolumeComponent()
//}
