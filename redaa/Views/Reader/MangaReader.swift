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
    
    @State private var parserHeight: CGFloat = 100
    private let expandedHeight: CGFloat = 400
    private let collapsedHeight: CGFloat = 100
    
    public init(volume: Binding<MangaVolumeModel>, currentPage: Int) {
        self._volume = volume
        self._currentPage = State(initialValue: currentPage)
        self._pages = State(initialValue: volume.wrappedValue.pages.array as? [MangaPageModel] ?? [])
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack {
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
//                                            .onAppear(perform: {
//                                                print("\(offsetX), \(offsetY), \(pages[index].width), \(pages[index].height), \(geometry.size), \(geometry.safeAreaInsets)")
//                                            })
                                            .border(Color.red, width: 1)
                                    } else {
                                        Text("Page \(index + 1) failed to load")
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .background(Color.black)
                                            .foregroundColor(.white)
                                    }
                                } else {
                                    Image(systemName: "xmark")
                                        .resizable()
                                        .scaledToFit()
                                }
                                MangaReaderBoxes(boxes: pages[index].getBoxes(), scale: scale, offsetX: offsetX, offsetY: offsetY, currentLine: $currentLine)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .padding(.bottom, collapsedHeight)
            .onChange(of: currentPage) { newPage in
                self.currentLine = ""
                volume.lastReadPage = Int64(newPage)
                DispatchQueue.main.async {
                    CoreDataManager.shared.saveContext()
                }
            }
//            .onChange(of: currentLine) { newLine in
//                print(newLine)
//            }
            
            GeometryReader { geometry in
                VStack {
                    Capsule()
                        .frame(width: 50, height: 6)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    
                    MangaReaderParserView(line: currentLine)
                        .frame(maxWidth: .infinity)
                        .frame(height: parserHeight - 20)
                }
                .background(Color(.systemBackground))
                .roundedCorners(16, corners: [.topLeft, .topRight])
                .frame(maxHeight: parserHeight)
                .offset(y: expandedHeight - parserHeight)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newHeight = parserHeight - value.translation.height
                            parserHeight = min(max(newHeight, collapsedHeight), expandedHeight)
                        }
                        .onEnded { _ in
                            withAnimation {
                                parserHeight = (parserHeight > (collapsedHeight + expandedHeight) / 2) ? expandedHeight : collapsedHeight
                            }
                        }
                )
            }
            .frame(height: expandedHeight)
        }
        .navigationTitle("\(currentPage + 1)/\(volume.pages.count)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

//#Preview {
//    MangaReader()
//}
