//
//  MangaReader.swift
//  redaa
//
//  Created by Pierre on 2025/02/17.
//

import SwiftUI
import LazyPager

public struct MangaReader: View {
    
    @Binding var volume: MangaVolumeModel
    @State var currentPage: Int
    
    @State private var pages: [MangaPageModel] = [] // Store computed array
    @State private var currentLine = ""
    
    public init(volume: Binding<MangaVolumeModel>, currentPage: Int) {
        self._volume = volume
        self._currentPage = State(initialValue: currentPage)
        self._pages = State(initialValue: volume.wrappedValue.pages.array as? [MangaPageModel] ?? [])
    }
    
    public var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    if let imageData = pages[index].getImage() {
                        VStack {
                            GeometryReader { geometry in
                                let scale = min(geometry.size.width / Double(pages[index].width),
                                                geometry.size.height / Double(pages[index].height))
                                let offset = (geometry.size.height - Double(pages[index].height) * scale) / 2
                                ZStack {
                                    Image(uiImage: imageData)
                                        .resizable()
                                        .scaledToFit()
//                                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                                        .onAppear(perform: {
                                            print(offset, geometry.size.height)
                                        })
                                    
                                    MangaReaderBoxes(boxes: pages[index].getBoxes(), scale: scale, offset: offset, currentLine: $currentLine)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            if currentLine != "" {
                                Text(currentLine)
                                    .onAppear(perform: {
                                        print("appear \(currentLine)")
                                    })
                            }
                        }
                    } else {
                        Text("Page \(index + 1)")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                            .foregroundColor(.white)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Horizontal paging
            .overlay(
                HStack {
                    Spacer()
                    Text("\(currentPage + 1) / \(volume.pages.count)")
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .padding()
                },
                alignment: .bottomTrailing
            )
            .onChange(of: currentPage) { newPage in
                volume.lastReadPage = Int64(newPage)
                DispatchQueue.main.async {
                    CoreDataManager.shared.saveContext()
                }
            }
        }
    }
}

//#Preview {
    //    MangaReader()
//}
