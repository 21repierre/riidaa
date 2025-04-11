//
//  VolumeComponent.swift
//  riidaa
//
//  Created by Pierre on 2025/02/17.
//

import SwiftUI

struct VolumeComponent: View {
    
    @ObservedObject var volume: MangaVolumeModel
    
    var body: some View {
        let totalPages = volume.pages.count
        let currentPage = volume.lastReadPage + 1
        let progress = totalPages > 0 ? Double(currentPage) / Double(totalPages) : 0
        NavigationLink(destination: MangaReader(volume: .init(get: {
            return volume
        }, set: {_ in}), currentPage: Int(volume.lastReadPage))) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Volume \(volume.number)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(currentPage) / \(totalPages)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(maxWidth: .infinity, maxHeight: 4)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .padding(.trailing, 10)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}
//
//#Preview {
//    VolumeComponent(
//        volume: CoreDataManager.sampleVolume
//    )
//        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
//
//}
#Preview {
    VolumeListView(
        manga: CoreDataManager.sampleManga
    )
    .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
    .onAppear(perform: {
        print(CoreDataManager.sampleManga)
    })
}
