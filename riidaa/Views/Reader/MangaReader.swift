//
//  MangaReader.swift
//  riidaa
//
//  Created by Pierre on 2025/02/17.
//

import SwiftUI
import LazyPager

public struct MangaReader: View {
    
    @Binding var volume: MangaVolumeModel
    @State var currentPage: Int
    
    @State private var pages: [MangaPageModel] = []
    @State private var currentLine: String? = nil
    
    @State private var offset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    @State private var pageHeight = 0.0
    
    public init(volume: Binding<MangaVolumeModel>, currentPage: Int) {
        self._volume = volume
        self._currentPage = State(initialValue: currentPage)
        self._pages = State(initialValue: volume.wrappedValue.pages.array as? [MangaPageModel] ?? [])
    }
    
    public var body: some View {
        GeometryReader { mainGeom in
            let minHeight = min(mainGeom.size.height * 0.2, mainGeom.size.height - pageHeight)
            let maxHeight = mainGeom.size.height * 0.8
            let tHeight1 = (maxHeight + minHeight)/3
            let tHeight2 = 2 * tHeight1
            
            ZStack(alignment: .bottom) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        //                        VStack {
                        GeometryReader { geometry in
                            let scale = min(geometry.size.width / Double(pages[index].width),
                                            geometry.size.height / Double(pages[index].height))
                            let offsetY = Double(pages[index].height) * scale / 2
                            let offsetX = Double(pages[index].width) * scale / 2
                            ZStack {
                                if abs(index - self.currentPage) <= 2 {
                                    if let imageData = pages[index].getImage() {
                                        Image(uiImage: imageData)
                                            .resizable()
                                            .scaledToFit()
                                    } else {
                                        Text("Page \(index + 1) failed to load")
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .background(Color(.systemBackground))
                                            .foregroundColor(.primary)
                                    }
                                } else {
                                    Image(systemName: "xmark")
                                        .resizable()
                                        .scaledToFit()
                                }
                                MangaReaderBoxes(boxes: pages[index].getBoxes(), scale: scale, offsetX: offsetX, offsetY: offsetY, currentLine: $currentLine)
                            }
                            .frame(maxWidth: .infinity, alignment: .top)
                            .onAppear {
                                pageHeight = Double(pages[index].height) * scale
                            }
                        }
                        //                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentPage) { newPage in
                    self.currentLine = nil
                    volume.lastReadPage = Int64(newPage)
                    DispatchQueue.main.async {
                        CoreDataManager.shared.saveContext()
                    }
                }
                
                VStack(alignment: .center, spacing: 0) {
                    Capsule()
                        .frame(width: 50, height: 6)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                        .padding(.bottom, 5)
                    
                    // Text("\(minHeight + offset-dragOffset) \(tHeight1) \(tHeight2) \(dragOffset)")
                    MangaReaderParserView(line: currentLine ?? "")
                        .frame(maxWidth: .infinity)
                }
                .frame(height: max(min(minHeight + offset-dragOffset, maxHeight), minHeight), alignment: .top)
                .background(Color(.systemGray6))
                .roundedCorners(20, corners: [.topLeft, .topRight])
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .updating($dragOffset) { value, state, tr in
                            state = value.translation.height
                        }
                        .onEnded { value in
                            if minHeight + offset-value.translation.height > tHeight2 {
                                offset = maxHeight - minHeight
                            } else if minHeight + offset-value.translation.height < tHeight1 || value.translation.height > 0 {
                                offset = 0
                            } else {
                                offset = maxHeight - minHeight
                            }
                        }
                )
                .animation(.easeIn(duration: 0.15), value: offset)
            }
        }
        .navigationTitle("\(currentPage + 1)/\(volume.pages.count)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MangaReader(volume: .init(get: {
        CoreDataManager.sampleVolume
    }, set: { _ in }), currentPage: 0)
    .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
}
