//
//  MangaReader.swift
//  riidaa
//
//  Created by Pierre on 2025/02/17.
//

import SwiftUI

/// The pages shown together, as indices into the volume in reading order.
enum PageSpreads {

    /// A page wider than tall is already a two-page spread, so it stands alone; with
    /// `coverAlone` the cover does too, so facing pages pair as they were printed.
    static func make(sizes: [CGSize], dual: Bool, coverAlone: Bool) -> [[Int]] {
        guard dual else { return sizes.indices.map { [$0] } }
        func isWide(_ index: Int) -> Bool { sizes[index].width > sizes[index].height }

        var spreads: [[Int]] = []
        var index = 0
        while index < sizes.count {
            let alone = (coverAlone && index == 0) || isWide(index)
                || index + 1 == sizes.count || isWide(index + 1)
            if alone {
                spreads.append([index])
                index += 1
            } else {
                spreads.append([index, index + 1])
                index += 2
            }
        }
        return spreads
    }
}

/// Holds the last spread layout, so the body's many reads of it don't each rebuild it.
private final class SpreadLayout {
    var key: (dual: Bool, coverAlone: Bool)?
    var spreads: [[Int]] = []
}

public struct MangaReader: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @EnvironmentObject var settings: SettingsModel

    @Binding var volume: MangaVolumeModel
    /// The page in reading order; in two-page mode, the first page of its spread.
    @State var currentPage: Int

    @State private var pages: [MangaPageModel] = []
    @State private var currentLine: SelectedLine? = nil

    @State private var menuVisible = false
    @State private var readerSize: CGSize
    @State private var lookupExpanded = false
    @State private var layout = SpreadLayout()
    @State private var prefetch: Task<Void, Never>? = nil
    @GestureState private var panelDrag: CGFloat = 0
    /// The panel isn't a system sheet, so VoiceOver has to be sent to it.
    @AccessibilityFocusState private var panelFocused: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var collapsedPanelHeight: CGFloat = 140

    /// The rendered page the open line sits on, for the Anki `picture` field. Resolved on
    /// demand so tapping a word never decodes an image that no one exports.
    private func currentPageImage() async -> UIImage? {
        guard let currentLine = currentLine,
              let page = pages.first(where: { $0.number == currentLine.page }) else { return nil }
        let crop = settings.ankiCropPicture
            ? currentLine.box.map { PictureCrop.rect(around: $0, in: CGSize(width: Int(page.width), height: Int(page.height))) }
            : nil
        return await PageImageCache.shared.uncachedImage(for: page, maxPixelSize: 1200, crop: crop)
    }

    private var currentSource: MangaSource? {
        guard let currentLine = currentLine else { return nil }
        return MangaSource(title: volume.manga.title, volume: volume.number, page: currentLine.page)
    }

    /// Sized from the window rather than the device orientation, which reads `.faceUp` when
    /// the iPad lies flat and ignores Split View. Not limited to iPad: an unfolded iPhone Duo
    /// is wide enough, and its fold then falls between the two pages. The height floor keeps
    /// ordinary iPhones in landscape on one page.
    var isDualPage: Bool {
        readerSize.width > readerSize.height && readerSize.height >= 500
    }

    private var spreads: [[Int]] {
        let key = (dual: isDualPage, coverAlone: settings.coverAlone)
        if layout.key?.dual != key.dual || layout.key?.coverAlone != key.coverAlone {
            layout.spreads = PageSpreads.make(
                sizes: pages.map { CGSize(width: Int($0.width), height: Int($0.height)) },
                dual: key.dual,
                coverAlone: key.coverAlone
            )
            layout.key = key
        }
        return layout.spreads
    }

    private var currentSpread: Int {
        spreads.firstIndex { $0.contains(currentPage) } ?? 0
    }

    /// Spreads left to right on screen.
    private var visualSpreads: [Int] {
        settings.isLTR ? Array(spreads.indices) : spreads.indices.reversed()
    }

    /// Regular-width sheets ignore detents and become a centered modal over the page, and
    /// compact-height ones (iPhones in landscape) fill the screen.
    private var usesLookupPanel: Bool {
        horizontalSizeClass == .regular || verticalSizeClass == .compact
    }

    private static var windowSize: CGSize {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.bounds.size }
            .first ?? .zero
    }

    public init(volume: Binding<MangaVolumeModel>, currentPage: Int) {
        self._volume = volume
        self._currentPage = State(initialValue: currentPage)
        self._readerSize = State(initialValue: MangaReader.windowSize)
        if let pages = volume.wrappedValue.pages.array as? [MangaPageModel] {
            self._pages = State(initialValue: pages)
        } else {
            self._pages = State(initialValue: [])
        }
    }

    /// Turns the page the way the swipe or arrow key points on screen.
    private func turnPage(_ edge: ZoomEdgeSwipe) {
        let visual = visualSpreads
        guard let position = visual.firstIndex(of: currentSpread) else { return }
        let target = position + (edge == .trailing ? 1 : -1)
        guard visual.indices.contains(target) else { return }
        currentPage = spreads[visual[target]][0]
    }

    /// Escape and VoiceOver's scrub close the lookup first, then the menu, then the reader.
    private func closeInnermost() {
        if currentLine != nil {
            currentLine = nil
        } else if menuVisible {
            menuVisible = false
        } else {
            dismiss()
        }
    }

    private func step(forward: Bool) {
        let target = currentSpread + (forward ? 1 : -1)
        guard spreads.indices.contains(target) else { return }
        currentPage = spreads[target][0]
    }

    /// Every page on screen counts as read, and progress points at the last of them.
    private func recordProgress() {
        guard spreads.indices.contains(currentSpread) else { return }
        let spread = spreads[currentSpread]
        let now = NSDate()
        for index in spread where pages[index].read_at == nil {
            pages[index].read_at = now
        }
        volume.lastReadPage = Int64(spread.last!)
        volume.last_read_at = now
        CoreDataManager.shared.saveContext()
    }

    private func prefetchAround() {
        let nearby = [currentSpread - 1, currentSpread + 1]
            .filter { spreads.indices.contains($0) }
            .flatMap { spreads[$0] }
            .map { pages[$0] }
        prefetch?.cancel()
        prefetch = Task {
            for page in nearby where !Task.isCancelled {
                _ = await PageImageCache.shared.image(for: page)
            }
        }
    }

    private func spreadLabel(_ spread: [Int]) -> String {
        let numbers = spread.map { String($0 + 1) }
        return (settings.isLTR ? numbers : numbers.reversed()).joined(separator: "-")
    }

    public var body: some View {
        let current = currentSpread
        GeometryReader { mainGeom in
            ZStack(alignment: .bottom) {
                TabView(selection: Binding(
                    get: { current },
                    set: { spread in
                        if spreads.indices.contains(spread) {
                            currentPage = spreads[spread][0]
                        }
                    }
                )) {
                    ForEach(visualSpreads, id: \.self) { spread in
                        spreadView(spreads[spread], isNear: abs(spread - current) <= 1)
                            .zoomable(isCurrent: spread == current, onEdgeSwipe: turnPage)
                            .onTapGesture(count: 1) {
                                menuVisible.toggle()
                            }
                            .tag(spread)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                // Rebuilt rather than re-paged when the spreads change, so the selection lands
                // on the right spread instead of whatever index the old layout had.
                .id("\(isDualPage)-\(settings.coverAlone)-\(settings.isLTR)")
                .transaction { txn in
                    txn.disablesAnimations = true
                }
                .onChange(of: currentPage) { _ in
                    currentLine = nil
                    recordProgress()
                    prefetchAround()
                }
                .onAppear {
                    prefetchAround()
                }
                .onDisappear {
                    prefetch?.cancel()
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

                if usesLookupPanel && currentLine != nil {
                    lookupPanel(in: mainGeom)
                        .transition(.move(edge: .bottom))
                        .zIndex(3)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: currentLine != nil)
            .onChange(of: currentLine != nil) { open in
                if open && usesLookupPanel {
                    panelFocused = true
                }
            }
            .sheet(isPresented: Binding(
                get: { currentLine != nil && !usesLookupPanel },
                set: { presented in if !presented && !usesLookupPanel { currentLine = nil } }
            )) {
                lookupSheet
            }
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { readerSize = proxy.size }
                    .onChange(of: proxy.size) { size in readerSize = size }
            }
            .ignoresSafeArea()
        }
        .background { keyboardShortcuts }
        .modifier(PencilControls(
            nextPage: { step(forward: true) },
            toggleMenu: {
                if currentLine != nil {
                    currentLine = nil
                } else {
                    menuVisible.toggle()
                }
            }
        ))
        .statusBarHidden(!menuVisible)
        .persistentSystemOverlays(menuVisible ? .automatic : .hidden)
        .accessibilityAction(.escape) { closeInnermost() }
        .modifier(AppAlerts())
    }

    private var keyboardShortcuts: some View {
        Group {
            Button("Previous page") { turnPage(.leading) }
                .keyboardShortcut(.leftArrow, modifiers: [])
            Button("Next page") { turnPage(.trailing) }
                .keyboardShortcut(.rightArrow, modifiers: [])
            Button("Forward") { step(forward: true) }
                .keyboardShortcut(.space, modifiers: [])
            Button("Back") { step(forward: false) }
                .keyboardShortcut(.space, modifiers: .shift)
            Button("Close") { closeInnermost() }
            .keyboardShortcut(.escape, modifiers: [])
            Button("Close volume") { dismiss() }
                .keyboardShortcut("w", modifiers: .command)
        }
        .opacity(0)
        .accessibilityHidden(true)
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
                    .frame(maxWidth: max(0, readerSize.width / 3 - 20), alignment: .leading)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.leading, 10)
            Spacer()

            let visual = visualSpreads
            let current = currentSpread
            SwiftUIWheelPicker(
                Binding(
                    get: { visual.firstIndex(of: current) ?? 0 },
                    set: { position in
                        if visual.indices.contains(position) {
                            currentPage = spreads[visual[position]][0]
                        }
                    }
                ),
                items: .constant(visual)
            ) { spread in
                GeometryReader { reader in
                    Text(spreadLabel(spreads[spread]))
                        .frame(width: reader.size.width, height: reader.size.height, alignment: .center)
                        .background(spread == current ? Color(.systemGray6) : Color.clear)
                        .roundedCorners(10, corners: .allCorners)
                }
            }
            .width(.VisibleCount(6))
            .scrollAlpha(0.4)
            .frame(height: 40)
            .accessibilityElement()
            .accessibilityLabel("Page")
            .accessibilityValue(spreads.indices.contains(current) ? spreadLabel(spreads[current]) : "")
            .accessibilityAdjustableAction { direction in
                step(forward: direction == .increment)
            }
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
        .modifier(AppAlerts())
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

    private func lookupPanel(in geometry: GeometryProxy) -> some View {
        let restingHeight = lookupExpanded ? geometry.size.height / 2 : collapsedPanelHeight
        return VStack(spacing: 0) {
            ZStack {
                Button {
                    lookupExpanded.toggle()
                } label: {
                    Capsule()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 36, height: 5)
                        .padding(.vertical, 15)
                        .padding(.horizontal, 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(lookupExpanded ? "Shrink lookup" : "Expand lookup")
                HStack {
                    Spacer()
                    Button {
                        currentLine = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Close lookup")
                    .accessibilityFocused($panelFocused)
                    .padding(.trailing, 12)
                }
            }
            .frame(height: 36)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 10)
                .updating($panelDrag) { value, drag, _ in
                    drag = value.translation.height
                }
                .onEnded { value in
                    if value.translation.height < -40 {
                        lookupExpanded = true
                    } else if value.translation.height > 40 {
                        if lookupExpanded {
                            lookupExpanded = false
                        } else {
                            currentLine = nil
                        }
                    }
                })

            MangaReaderParserView(
                line: currentLine?.text ?? "",
                source: currentSource,
                pageImage: currentPageImage
            )
        }
        .frame(height: min(geometry.size.height, max(80, restingHeight - panelDrag)))
        .padding(.bottom, geometry.safeAreaInsets.bottom)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedCorners(radius: 16, corners: [.topLeft, .topRight]))
        .shadow(color: .black.opacity(0.15), radius: 8, y: -2)
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(.easeInOut(duration: 0.25), value: lookupExpanded)
    }

    @ViewBuilder
    private func spreadView(_ spread: [Int], isNear: Bool) -> some View {
        if spread.count == 2 {
            let (left, right) = settings.isLTR ? (spread[0], spread[1]) : (spread[1], spread[0])
            doublePageDisplay(left: pages[left], right: pages[right], isNear: isNear)
        } else {
            pageDisplay(pages[spread[0]], isNear: isNear)
        }
    }

    private func pageDisplay(_ page: MangaPageModel, isNear: Bool) -> some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / Double(page.width),
                            geometry.size.height / Double(page.height))
            ZStack(alignment: .center) {
                PageImage(page: page, isNear: isNear)
                MangaReaderBoxes(
                    boxes: page.getBoxes(), pageNumber: page.number, scale: scale,
                    offsetX: Double(page.width) * scale / 2, offsetY: Double(page.height) * scale / 2,
                    currentLine: $currentLine
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func doublePageDisplay(left: MangaPageModel, right: MangaPageModel, isNear: Bool) -> some View {
        GeometryReader { geometry in
            let halfWidth = geometry.size.width / 2
            let leftScale = min(halfWidth / Double(left.width), geometry.size.height / Double(left.height))
            let rightScale = min(halfWidth / Double(right.width), geometry.size.height / Double(right.height))
            let leftOffsetX = Double(left.width) * leftScale / 2
            let rightOffsetX = Double(right.width) * rightScale / 2

            ZStack(alignment: .center) {
                HStack(spacing: 0) {
                    PageImage(page: left, isNear: isNear)
                        .frame(width: halfWidth, alignment: .trailing)
                    PageImage(page: right, isNear: isNear)
                        .frame(width: halfWidth, alignment: .leading)
                }
                MangaReaderBoxes(
                    boxes: left.getBoxes(), pageNumber: left.number, scale: leftScale,
                    offsetX: leftOffsetX, offsetY: Double(left.height) * leftScale / 2,
                    currentLine: $currentLine
                )
                .frame(width: halfWidth)
                .offset(x: -leftOffsetX)
                MangaReaderBoxes(
                    boxes: right.getBoxes(), pageNumber: right.number, scale: rightScale,
                    offsetX: rightOffsetX, offsetY: Double(right.height) * rightScale / 2,
                    currentLine: $currentLine
                )
                .offset(x: rightOffsetX)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

}

/// Apple Pencil double-tap turns the page and Pencil Pro's squeeze toggles the menu, unless the
/// reader has set the Pencil's action to Ignore in Settings.
private struct PencilControls: ViewModifier {
    let nextPage: () -> Void
    let toggleMenu: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 17.5, *) {
            content.modifier(PencilGestures(nextPage: nextPage, toggleMenu: toggleMenu))
        } else {
            content
        }
    }
}

@available(iOS 17.5, *)
private struct PencilGestures: ViewModifier {
    let nextPage: () -> Void
    let toggleMenu: () -> Void

    @Environment(\.preferredPencilDoubleTapAction) private var doubleTapAction
    @Environment(\.preferredPencilSqueezeAction) private var squeezeAction

    func body(content: Content) -> some View {
        content
            .onPencilDoubleTap { _ in
                if doubleTapAction != .ignore {
                    nextPage()
                }
            }
            .onPencilSqueeze { phase in
                if case .ended = phase, squeezeAction != .ignore {
                    toggleMenu()
                }
            }
    }
}

private struct PageImage: View {

    let page: MangaPageModel
    let isNear: Bool

    @State private var image: UIImage?
    @State private var failed = false

    init(page: MangaPageModel, isNear: Bool) {
        self.page = page
        self.isNear = isNear
        self._image = State(initialValue: PageImageCache.shared.cachedImage(for: page))
    }

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if failed {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                    Text("Page \(page.number) failed to load")
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Color.clear
            }
        }
        .task(id: isNear) {
            guard isNear else {
                image = nil
                failed = false
                return
            }
            guard image == nil else { return }
            let loaded = await PageImageCache.shared.image(for: page)
            guard !Task.isCancelled else { return }
            image = loaded
            failed = loaded == nil
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
