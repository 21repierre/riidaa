//
//  MangaReader.swift
//  riidaa
//
//  Created by Pierre on 2025/02/17.
//

import SwiftUI
import LazyPager
//import Zoomable

public struct MangaReader: View {
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var settings: SettingsModel
    
    @Binding var volume: MangaVolumeModel
    @State var currentPage: Int
    
    @State private var pages: [MangaPageModel] = []
    @State private var currentLine: SelectedLine? = nil
    
    @State private var menuVisible = false
    @State private var pageHeight = 0.0
    @State private var ready = false
    
    @State private var orientation = UIDeviceOrientation.landscapeLeft// UIDevice.current.orientation
    
    private var displayedPages: [MangaPageModel] {
        settings.isLTR ? pages : pages.reversed()
    }

    /// The rendered page the open line sits on, for the Anki `picture` field. Resolved on
    /// demand so tapping a word never decodes an image that no one exports.
    private func currentPageImage() -> UIImage? {
        guard let currentLine = currentLine else { return nil }
        return pages.first { $0.number == currentLine.page }?.getImage()
    }

    private var currentSource: MangaSource? {
        guard let currentLine = currentLine else { return nil }
        return MangaSource(title: volume.manga.title, volume: volume.number, page: currentLine.page)
    }

    
    var isDualPage: Bool {
                UIDevice.current.userInterfaceIdiom == .pad && (UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight)
//        true
    }
    
    public init(volume: Binding<MangaVolumeModel>, currentPage: Int) {
        self._volume = volume
        self._currentPage = State(initialValue: currentPage)
        if let pages = volume.wrappedValue.pages.array as? [MangaPageModel] {
            self._pages = State(initialValue: pages)
        } else {
            self._pages = State(initialValue: [])
        }
    }
    
    private func tag(for page: MangaPageModel) -> Int {
        if isDualPage {
            return Int(page.number) - (settings.isLTR ? 1 : 2)
        }
        return Int(page.number) - 1
    }

    /// Turns the page for a swipe that ran out of room on a zoomed image.
    private func turnPage(_ edge: ZoomEdgeSwipe) {
        guard let index = displayedPages.firstIndex(where: { tag(for: $0) == currentPage }) else {
            return
        }
        let step = (isDualPage ? 2 : 1) * (edge == .trailing ? 1 : -1)
        let target = index + step
        guard displayedPages.indices.contains(target) else { return }
        currentPage = tag(for: displayedPages[target])
    }

    public var body: some View {
        GeometryReader { mainGeom in
            ZStack(alignment: .bottom) {
                TabView(selection: .init(get: {
                    if isDualPage {
                        currentPage - (currentPage%2)
                    } else {
                        currentPage
                    }
                }, set: {v in
                    if isDualPage {
                        if ready {
                            currentPage = v - (v%2)
                        }
                    } else {
                        currentPage = v
                    }
                })) {
                    if isDualPage {
                        let start = settings.isLTR ? 0 : displayedPages.count % 2
                        ForEach(Array(stride(from: start, to: displayedPages.count, by: 2)), id: \.self) { index in
                            VStack(spacing: 0) {
                                if index + 1 < displayedPages.count {
                                    doublePageDisplay(index1: index, index2: index + 1)
                                } else {
                                    pageDisplay(index: index)
                                }
                            }
                            .zoomable(onEdgeSwipe: turnPage)
                            .onTapGesture(count: 1) {
                                menuVisible.toggle()
                            }
                            .tag(Int(displayedPages[index].number) - (settings.isLTR ? 1 : 2))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onAppear {
                                ready = true
                            }
                        }
                    } else {
                        ForEach(displayedPages.indices, id: \.self) { index in
                            VStack {
                                pageDisplay(index: index)
                            }
                            .zoomable(onEdgeSwipe: turnPage)
                            .onTapGesture(count: 1) {
                                menuVisible.toggle()
                            }
                            .tag(Int(displayedPages[index].number) - 1)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .transaction { txn in
                    txn.disablesAnimations = true
                }
                .onChange(of: currentPage) { newPage in
                    self.currentLine = nil
                    if pages.indices.contains(newPage), pages[newPage].read_at == nil {
                        pages[newPage].read_at = NSDate()
                    }
                    volume.lastReadPage = Int64(newPage)
                    volume.last_read_at = NSDate()
                    DispatchQueue.main.async {
                        CoreDataManager.shared.saveContext()
                    }
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    if menuVisible {
                        topMenu
                            .transition(.move(edge: .top))
                    }
                    Spacer(minLength: 0)
                }
                .animation(.easeInOut(duration: 0.25), value: menuVisible)
                .zIndex(2)

            }
            .sheet(isPresented: Binding(
                get: { currentLine != nil },
                set: { presented in if !presented { currentLine = nil } }
            )) {
                lookupSheet
            }
        }
        .statusBarHidden(!menuVisible)
        .persistentSystemOverlays(menuVisible ? .automatic : .hidden)
        .onRotate { newRotation in
            orientation = newRotation
            if newRotation == .landscapeLeft || newRotation == .landscapeRight {
                ready = false
                currentPage -= (currentPage%2)
            }
        }
    }

    @ViewBuilder
    private var topMenu: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .scaleEffect(1.2)
                Text("\(volume.manga.title)")
                    .frame(maxWidth: UIScreen.main.bounds.width / 3 - 20, alignment: .leading)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.leading, 10)
            Spacer()

            SwiftUIWheelPicker(
                .init(get: {
                    if isDualPage {
                        return settings.isLTR ? currentPage / 2 : (pages.count - 1 - currentPage) / 2
                    } else {
                        return settings.isLTR ? currentPage : pages.count - 1 - currentPage
                    }
                }, set: {v in
                    if isDualPage {
                        currentPage = settings.isLTR ? v * 2 : max(0, pages.count - 1 - (v * 2))
                    } else {
                        currentPage = settings.isLTR ? v : pages.count - 1 - v
                    }
                }),
                items: .constant({
                    if isDualPage {
                        let c = (pages.count + 1) / 2
                        return settings.isLTR ? Array(0..<c) : Array(0..<c).reversed()
                    } else {
                        return settings.isLTR ? Array(0..<pages.count) : Array(0..<pages.count).reversed()
                    }
                }())
            ) { value in
                GeometryReader { reader in
                    if isDualPage {
                        let start = value * 2 + 1
                        let tmp: String = (start + 1) < pages.count ? (settings.isLTR ? "\(start)-\(start+1)" : "\(start+1)-\(start)") : "\(start)"
                        Text("\(tmp)")
                            .frame(width: reader.size.width, height: reader.size.height, alignment: .center)
                            .background(start-1 == currentPage ? Color(.systemGray6) : Color.clear)
                            .roundedCorners(10, corners: .allCorners)
                    } else {
                        Text("\(value + 1)")
                            .frame(width: reader.size.width, height: reader.size.height, alignment: .center)
                            .background(value == currentPage ? Color(.systemGray6) : Color.clear)
                            .roundedCorners(10, corners: .allCorners)
                    }
                }
            }
            .width(.VisibleCount(6))
            .scrollAlpha(0.4)
            .frame(height: 40)
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    /// The lookup panel, as a system sheet.
    @ViewBuilder
    private var lookupSheet: some View {
        let content = MangaReaderParserView(
            line: currentLine?.text ?? "",
            source: currentSource,
            pageImage: currentPageImage
        )
        .padding(.top, 10)
        .presentationDetents([.height(140), .medium, .large])
        .presentationDragIndicator(.visible)

        if #available(iOS 16.4, *) {
            content
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationContentInteraction(.scrolls)
        } else {
            content
        }
    }

    @ViewBuilder
    public func pageDisplay(index: Int) -> some View {
        let page = displayedPages[index]
        GeometryReader { geometry in
            let scale = min(geometry.size.width / Double(page.width),
                            geometry.size.height / Double(page.height))
            let offsetY = Double(page.height) * scale / 2
            let offsetX = Double(page.width) * scale / 2
            ZStack(alignment: .center) {
                if abs(index - (settings.isLTR ? self.currentPage : displayedPages.count - self.currentPage)) <= 10
                {
                    if let imageData = page.getImage() {
                        Image(uiImage: imageData)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 400)
                        Text("Page \(page.number) failed to load")
                            .frame(maxHeight: .infinity)
                            .background(Color(.systemBackground))
                            .foregroundColor(.primary)
                    }
                } else {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                }
                MangaReaderBoxes(boxes: page.getBoxes(), pageNumber: page.number, scale: scale, offsetX: offsetX, offsetY: offsetY, currentLine: $currentLine)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .onAppear {
                pageHeight = Double(page.height) * scale
            }
        }
    }
    
    @ViewBuilder
    public func doublePageDisplay(index1: Int, index2: Int) -> some View {
        let page1 = displayedPages[index1]
        let page2 = displayedPages[index2]
        GeometryReader { geometry in
            let halfWidth = geometry.size.width / 2
            let scale1 = min(halfWidth / Double(page1.width),
                             geometry.size.height / Double(page1.height))
            let scale2 = min(halfWidth / Double(page2.width),
                             geometry.size.height / Double(page2.height))
            
            let offsetY1 = Double(page1.height) * scale1 / 2
            let offsetY2 = Double(page2.height) * scale2 / 2
            
            let offsetX1 = Double(page1.width) * scale1 / 2
            let offsetX2 = Double(page2.width) * scale2 / 2

            ZStack(alignment: .center) {
                if abs(index1 - (settings.isLTR ? self.currentPage : displayedPages.count - self.currentPage)) <= 10
                {
                    HStack(spacing: 0) {
                        if let imageData = page1.getImage() {
                            Image(uiImage: imageData)
                                .resizable()
                                .scaledToFit()
                                .frame(width: halfWidth, alignment: .trailing)
//                                .clipped()
                        } else {
                            Text("Page \(page1.number) failed to load")
                                .frame(maxHeight: .infinity)
                                .background(Color(.systemBackground))
                                .foregroundColor(.primary)
                        }
                        if let imageData = page2.getImage() {
                            Image(uiImage: imageData)
                                .resizable()
                                .scaledToFit()
                                .frame(width: halfWidth, alignment: .leading)
                            //                                .clipped()
                        } else {
                            Text("Page \(page2.number) failed to load")
                                .frame(maxHeight: .infinity)
                                .background(Color(.systemBackground))
                                .foregroundColor(.primary)
                        }
                    }
                } else {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                }
                MangaReaderBoxes(boxes: page1.getBoxes(), pageNumber: page1.number, scale: scale1, offsetX: offsetX1, offsetY: offsetY1, currentLine: $currentLine)
                    .frame(width: halfWidth)
                    .offset(x: -offsetX1)
                MangaReaderBoxes(boxes: page2.getBoxes(), pageNumber: page2.number, scale: scale2, offsetX: offsetX2, offsetY: offsetY2, currentLine: $currentLine)
                    .offset(x: offsetX2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .onAppear {
                pageHeight = max(Double(page1.height) * scale2, Double(page2.height) * scale2)
            }
        }
    }
    
}


#Preview {
    MangaReader(volume: .init(get: {
        CoreDataManager.sampleManga.volumes[0] as! MangaVolumeModel
    }, set: { _ in }), currentPage: 2)
    .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
    .environmentObject(SettingsModel())
}
