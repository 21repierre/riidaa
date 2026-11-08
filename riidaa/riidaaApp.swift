//
//  riidaaApp.swift
//  riidaa
//
//  Created by Pierre on 2025/02/12.
//

import SwiftUI
import Apollo

@main
struct riidaaApp: App {
    
    @ObservedObject var CoreController = CoreDataManager.shared
    @StateObject var appManager: AppManager = AppManager.shared
    @StateObject var settings: SettingsModel = SettingsModel()
    
    var body: some Scene {
        WindowGroup {
            if let error = CoreController.loadError {
                StoreUnavailableView(error: error)
            } else {
            HomeView()
                .modifier(AppAlerts())
                .environment(\.managedObjectContext, CoreController.context)
                .environmentObject(appManager)
                .environmentObject(settings)
                .onOpenURL { url in
                    settings.handleAnkiSetupCallback(url)
                    AnkiExport.handleCallback(url)
                }
                .overlay(alignment: .bottom) {
                    if appManager.isLoading {
                        DictionaryLoadingBanner(text: "Loading dictionaries…", fraction: nil)
                            .modifier(AboveTabBar())
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .overlay(alignment: .bottom) {
                    if !appManager.isLoading, let purging = appManager.purging {
                        DictionaryLoadingBanner(
                            text: "Clearing deleted dictionary… \(Int(purging.fraction * 100))%",
                            fraction: purging.fraction
                        )
                        .modifier(AboveTabBar())
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: appManager.isLoading)
                .animation(.easeInOut(duration: 0.25), value: appManager.purging)
            }
        }
    }
}

struct StoreUnavailableView: View {
    let error: Error

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "externaldrive.badge.xmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Library unavailable")
                .font(.headline)
            Text("リーダー could not open its library. Closing the app fully and reopening it will often be enough.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(error.localizedDescription)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(30)
    }
}

struct AppAlerts: ViewModifier {
    @ObservedObject private var store = CoreDataManager.shared
    @ObservedObject private var appManager = AppManager.shared
    @EnvironmentObject private var settings: SettingsModel

    func body(content: Content) -> some View {
        content
            .alert(
                "Couldn't save",
                isPresented: Binding(
                    get: { store.saveError != nil },
                    set: { shown in if !shown { store.saveError = nil } }
                ),
                actions: { Button("OK", role: .cancel) {} },
                message: { Text("The last change wasn't kept. \(store.saveError ?? "")") }
            )
            .alert(
                "Dictionary error",
                isPresented: Binding(
                    get: { appManager.lastError != nil },
                    set: { shown in if !shown { appManager.lastError = nil } }
                ),
                actions: { Button("OK", role: .cancel) {} },
                message: { Text(appManager.lastError ?? "") }
            )
            .alert(
                "Anki setup",
                isPresented: Binding(
                    get: { settings.ankiSetupError != nil },
                    set: { shown in if !shown { settings.ankiSetupError = nil } }
                ),
                actions: { Button("OK", role: .cancel) {} },
                message: { Text(settings.ankiSetupError ?? "") }
            )
    }
}

private struct AboveTabBar: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        if #available(iOS 18, *), horizontalSizeClass == .regular, UIDevice.current.userInterfaceIdiom == .pad {
            content.padding(.bottom, 16)
        } else {
            content.padding(.bottom, 60)
        }
    }
}

struct DictionaryLoadingBanner: View {
    let text: String
    var fraction: Double? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let fraction = fraction {
                ProgressView(value: fraction)
                    .frame(width: 60)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.thinMaterial, in: Capsule())
        .shadow(radius: 4, y: 2)
        .accessibilityLabel(text)
    }
}
