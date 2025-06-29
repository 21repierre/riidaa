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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Toggle("Left to Right Reader", isOn: settings.$isLTR)
                
                
                Toggle("Use Background Color", isOn: settings.$backgroundColorEnabled)
                if settings.backgroundColorEnabled {
                    ColorPicker("Background Color", selection: settings.backgroundColor)
                        .padding(.leading)
                }
                
                Toggle("Use Border Color", isOn: settings.$borderColorEnabled)
                if settings.borderColorEnabled {
                    ColorPicker("Border Color", selection: settings.borderColor)
                        .padding(.leading)
                    Stepper("Border width: \(settings.borderSize.formatted())", value: settings.$borderSize, in: 0...10, step: 0.5)
                }
                Stepper("Padding: \(settings.padding.formatted())", value: settings.$padding, in: 0...40, step: 0.5)
                
                // preview
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
                .padding(.top, 40)
            }
            .padding()
        }
        .navigationTitle("Reader")
    }
}

#Preview {
    ReaderSettings()
        .environmentObject(SettingsModel())
}
