//
//  ReaderSettings.swift
//  riidaa
//
//  Created by Pierre on 2025/04/15.
//

import SwiftUI

struct ReaderSettings: View {

    @EnvironmentObject var settings: SettingsModel

    var body: some View {
        Form {
            Section {
                Toggle("Left to Right Reader", isOn: settings.$isLTR)
                Toggle("Cover on Its Own", isOn: settings.$coverAlone)
            } footer: {
                Text("Cover on Its Own: in two-page mode, shows the cover by itself so facing pages pair as printed.")
            }

            Section {
                Toggle("Word Audio", isOn: settings.$wordAudioEnabled)
                if settings.wordAudioEnabled {
                    Toggle("Preload Word Audio", isOn: settings.$preloadWordAudio)
                }
            } footer: {
                Text("Adds a play button to lookups and an audio value to Anki exports. Preloading fetches the audio for every word in a bubble when you tap it, so it plays straight away, but sends those words to JapanesePod101 too.")
            }

            Section("Text boxes") {
                Toggle("Use Background Color", isOn: settings.$backgroundColorEnabled)
                if settings.backgroundColorEnabled {
                    ColorPicker("Background Color", selection: settings.backgroundColor)
                }
                Toggle("Use Border Color", isOn: settings.$borderColorEnabled)
                if settings.borderColorEnabled {
                    ColorPicker("Border Color", selection: settings.borderColor)
                    Stepper("Border width: \(settings.borderSize.formatted())", value: settings.$borderSize, in: 0...10, step: 0.5)
                }
                Stepper("Padding: \(settings.padding.formatted())", value: settings.$padding, in: 0...40, step: 0.5)
            }

            Section("Preview") {
                ZStack {
                    RoundedRectangle(cornerRadius: 50)
                        .fill(Color.white)
                        .frame(height: 150)
                    Text("ここは日本語で書かれます")
                        .foregroundStyle(Color.black)
                        .font(.title2)
                        .padding(settings.padding)
                        .overlay {
                            Rectangle()
                                .fill(settings.backgroundColorEnabled ? settings.backgroundColor.wrappedValue : Color.clear)
                                .border(settings.borderColorEnabled ? settings.borderColor.wrappedValue : Color.clear, width: settings.borderSize)
                        }
                }
                .accessibilityHidden(true)
            }
        }
        .navigationTitle("Reader")
    }
}

#Preview {
    NavigationStack {
        ReaderSettings()
            .environmentObject(SettingsModel())
    }
}
