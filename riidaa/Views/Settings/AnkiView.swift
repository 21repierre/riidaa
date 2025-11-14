//
//  AnkiView.swift
//  riidaa
//
//  Created by Pierre on 2025/11/10.
//

import SwiftUI

struct AnkiView: View {
    
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 20) {
                if let infos = settings.ankiInfo {
                    HStack {
                        Text("Choose profile:")
                            .font(.headline)
                        
                        Picker("Profile", selection: $settings.ankiProfile) {
                            ForEach(infos.profiles) { profile in
                                Text(profile.name).tag(profile as AnkiInfo.Profile?)
                            }
                        }
                        .pickerStyle(.menu)
                        Spacer()
                    }
                    .padding(.top)
                    
                    HStack {
                        Text("Choose deck:")
                            .font(.headline)
                        
                        Picker("Deck", selection: $settings.ankiDeck) {
                            ForEach(infos.decks) { deck in
                                Text(deck.name).tag(deck as AnkiInfo.Deck?)
                            }
                        }
                        .pickerStyle(.menu)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Choose format:")
                            .font(.headline)
                        
                        Picker("Format", selection: $settings.ankiNoteType) {
                            ForEach(infos.notetypes) { noteType in
                                Text(noteType.name).tag(noteType as AnkiInfo.NoteType?)
                            }
                        }
                        .pickerStyle(.menu)
                        Spacer()
                    }
                    
                    if let noteType = settings.ankiNoteType {
                        HStack {
                            Text("Choose field for word:")
                                .font(.headline)
                            
                            Picker("field", selection: $settings.ankiFieldWord) {
                                Text("None").tag(nil as String?)
                                ForEach(noteType.fields) { field in
                                    Text(field.name).tag(field.name as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            Spacer()
                        }
                        
                        HStack {
                            Text("Choose field for reading:")
                                .font(.headline)
                            
                            Picker("field", selection: $settings.ankiFieldReading) {
                                Text("None").tag(nil as String?)
                                ForEach(noteType.fields) { field in
                                    Text(field.name).tag(field.name as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            Spacer()
                        }
                        
                        HStack {
                            Text("Choose field for meaning:")
                                .font(.headline)
                            
                            Picker("field", selection: $settings.ankiFieldMeaning) {
                                Text("None").tag(nil as String?)
                                ForEach(noteType.fields) { field in
                                    Text(field.name).tag(field.name as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            Spacer()
                        }
                        
                        HStack {
                            Text("Choose field for sentence:")
                                .font(.headline)
                            
                            Picker("field", selection: $settings.ankiFieldExample) {
                                Text("None").tag(nil as String?)
                                ForEach(noteType.fields) { field in
                                    Text(field.name).tag(field.name as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            Spacer()
                        }
                    }
                    
                }
                Spacer()
                
                
            }
            .padding()
            
            Button("Refresh Anki informations") {
                fetchAnkiDecks()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(7)
            .padding()
        }
        .navigationTitle("Reader")
        .onOpenURL { url in
            if url.scheme == "riidaa" {
                if url.host() == "anki-setup" {
                    let pasteboardType = "net.ankimobile.json"
                    if let data = UIPasteboard.general.data(forPasteboardType: pasteboardType) {
                        UIPasteboard.general.setData(Data(), forPasteboardType: pasteboardType)
                        do {
                            let decoder = JSONDecoder()
                            let infos = try decoder.decode(AnkiInfo.self, from: data)
                            DispatchQueue.main.async {
                                settings.ankiInfo = infos
                                if let profile = infos.profiles.first {
                                    settings.ankiProfile = profile
                                }
                                if let deck = infos.decks.first {
                                    settings.ankiDeck = deck
                                }
                                if let noteType = infos.notetypes.first {
                                    settings.ankiNoteType = noteType
                                }
                            }
                        } catch {
                            print("failed decoding Anki infos: \(error)")
                            
                        }
                    }
                }
            }
        }
//        .onAppear {
//            do {
//                let data = Data(base64Encoded: "eyJkZWNrcyI6W3sibmFtZSI6IkNvcmUyLjNrIFZlcnNpb24gMyJ9LHsibmFtZSI6IkRlZmF1bHQifSx7Im5hbWUiOiJLYWlzaGkgMS41ayJ9LHsibmFtZSI6InJpaWRhYSJ9LHsibmFtZSI6IlJSVEsgSSAtIFJlY29nbml0aW9uIFJlbWVtYmVyaW5nIFRoZSBLYW5qaSJ9LHsibmFtZSI6IlJSVEsgSSAtIFJlY29nbml0aW9uIFJlbWVtYmVyaW5nIFRoZSBLYW5qaTo6UlJUSyBSZWNvZ25pdGlvbiBSZW1lbWJlcmluZyBUaGUgS2FuamkgdjIifSx7Im5hbWUiOiJWb2NhYnVsYWlyZSBKQTIwMCJ9LHsibmFtZSI6IllvbWljaGFuIn1dLCJub3RldHlwZXMiOlt7ImtpbmQiOiJub3JtYWwiLCJuYW1lIjoiQmFzaWMiLCJmaWVsZHMiOlt7Im5hbWUiOiJGcm9udCJ9LHsibmFtZSI6IkJhY2sifV19LHsibmFtZSI6IkJhc2ljIChhbmQgcmV2ZXJzZWQgY2FyZCkiLCJraW5kIjoibm9ybWFsIiwiZmllbGRzIjpbeyJuYW1lIjoiRnJvbnQifSx7Im5hbWUiOiJCYWNrIn1dfSx7ImtpbmQiOiJub3JtYWwiLCJuYW1lIjoiQmFzaWMgKHR5cGUgaW4gdGhlIGFuc3dlcikiLCJmaWVsZHMiOlt7Im5hbWUiOiJGcm9udCJ9LHsibmFtZSI6IkJhY2sifV19LHsia2luZCI6ImNsb3plIiwibmFtZSI6IkNsb3plIiwiZmllbGRzIjpbeyJuYW1lIjoiVGV4dCJ9LHsibmFtZSI6IkJhY2sgRXh0cmEifV19LHsibmFtZSI6ImNvcmUyLjNrLWFuaW1lLWNhcmQiLCJmaWVsZHMiOlt7Im5hbWUiOiJXb3JkIn0seyJuYW1lIjoiUmVhZGluZyJ9LHsibmFtZSI6Ikdsb3NzYXJ5In0seyJuYW1lIjoiU2VudGVuY2UifSx7Im5hbWUiOiJTZW50ZW5jZS1FbmdsaXNoIn0seyJuYW1lIjoiUGljdHVyZSJ9LHsibmFtZSI6IkF1ZGlvIn0seyJuYW1lIjoiU2VudGVuY2UtQXVkaW8ifSx7Im5hbWUiOiJIaW50In1dLCJraW5kIjoibm9ybWFsIn0seyJuYW1lIjoiSGVpc2lnIOabuOOBjeaWuS0yODY4MCIsImtpbmQiOiJub3JtYWwiLCJmaWVsZHMiOlt7Im5hbWUiOiJLYW5qaSJ9LHsibmFtZSI6IktleXdvcmQifSx7Im5hbWUiOiJNeSBTdG9yeSJ9LHsibmFtZSI6IlN0cm9rZSBDb3VudCJ9LHsibmFtZSI6IkhlaXNpZyBOdW1iZXIifV19LHsiZmllbGRzIjpbeyJuYW1lIjoiT2NjbHVzaW9uIn0seyJuYW1lIjoiSW1hZ2UifSx7Im5hbWUiOiJIZWFkZXIifSx7Im5hbWUiOiJCYWNrIEV4dHJhIn0seyJuYW1lIjoiQ29tbWVudHMifV0sIm5hbWUiOiJJbWFnZSBPY2NsdXNpb24iLCJraW5kIjoiY2xvemUifSx7ImZpZWxkcyI6W3sibmFtZSI6IlZlcnNpb24ifSx7Im5hbWUiOiJTZXF1ZW5jZSJ9LHsibmFtZSI6IkltYWdlIn0seyJuYW1lIjoiVGV4dCJ9XSwibmFtZSI6IkluZm9Ob3RlIiwia2luZCI6Im5vcm1hbCJ9LHsibmFtZSI6IkphcGFuZXNlIHdvcmQiLCJmaWVsZHMiOlt7Im5hbWUiOiJLYW5qaSJ9LHsibmFtZSI6IkthbmEgLSBGdXJpZ2FuYSJ9LHsibmFtZSI6Ik1lYW5pbmcifV0sImtpbmQiOiJub3JtYWwifSx7ImZpZWxkcyI6W3sibmFtZSI6IlZlcnNpb24ifSx7Im5hbWUiOiJTZXF1ZW5jZSJ9LHsibmFtZSI6IlNvdXJjZSJ9LHsibmFtZSI6IkF1ZGlvIn0seyJuYW1lIjoiSW1hZ2UifSx7Im5hbWUiOiJSZW1hcmtzRnJvbnQifSx7Im5hbWUiOiJSZW1hcmtzQmFjayJ9LHsibmFtZSI6IlF1ZXN0aW9uTGluayJ9LHsibmFtZSI6IlJlZmVyZW5jZXMifSx7Im5hbWUiOiJPdGhlci1Gcm9udCJ9LHsibmFtZSI6Ik90aGVyLUJhY2sifSx7Im5hbWUiOiJKbGFiLUthbmppIn0seyJuYW1lIjoiSmxhYi1LYW5qaVNwYWNlZCJ9LHsibmFtZSI6IkpsYWItSGlyYWdhbmEifSx7Im5hbWUiOiJKbGFiLUthbmppQ2xvemUifSx7Im5hbWUiOiJKbGFiLUxlbW1hIn0seyJuYW1lIjoiSmxhYi1IaXJhZ2FuYUNsb3plIn0seyJuYW1lIjoiSmxhYi1UcmFuc2xhdGlvbiJ9LHsibmFtZSI6IkpsYWItRGljdGlvbmFyeUxvb2t1cCJ9LHsibmFtZSI6IkpsYWItTWV0YWRhdGEifSx7Im5hbWUiOiJKbGFiLVJlbWFya3MifSx7Im5hbWUiOiJKbGFiLUxpc3RlbmluZ0Zyb250In0seyJuYW1lIjoiSmxhYi1MaXN0ZW5pbmdCYWNrIn0seyJuYW1lIjoiSmxhYi1DbG96ZUZyb250In0seyJuYW1lIjoiSmxhYi1DbG96ZUJhY2sifV0sImtpbmQiOiJub3JtYWwiLCJuYW1lIjoiSmxhYk5vdGUtSmxhYkNvbnZlcnRlZC0xIn0seyJmaWVsZHMiOlt7Im5hbWUiOiJXb3JkIn0seyJuYW1lIjoiV29yZCBSZWFkaW5nIn0seyJuYW1lIjoiV29yZCBNZWFuaW5nIn0seyJuYW1lIjoiV29yZCBGdXJpZ2FuYSJ9LHsibmFtZSI6IldvcmQgQXVkaW8ifSx7Im5hbWUiOiJTZW50ZW5jZSJ9LHsibmFtZSI6IlNlbnRlbmNlIE1lYW5pbmcifSx7Im5hbWUiOiJTZW50ZW5jZSBGdXJpZ2FuYSJ9LHsibmFtZSI6IlNlbnRlbmNlIEF1ZGlvIn0seyJuYW1lIjoiTm90ZXMifSx7Im5hbWUiOiJQaXRjaCBBY2NlbnQifSx7Im5hbWUiOiJQaXRjaCBBY2NlbnQgTm90ZXMifSx7Im5hbWUiOiJGcmVxdWVuY3kifSx7Im5hbWUiOiJQaWN0dXJlIn1dLCJuYW1lIjoiS2Fpc2hpIDEuNWsiLCJraW5kIjoibm9ybWFsIn0seyJuYW1lIjoiS2Fpc2hpIDEuNWsrIiwiZmllbGRzIjpbeyJuYW1lIjoiV29yZCJ9LHsibmFtZSI6IldvcmQgUmVhZGluZyJ9LHsibmFtZSI6IldvcmQgTWVhbmluZyJ9LHsibmFtZSI6IldvcmQgRnVyaWdhbmEifSx7Im5hbWUiOiJXb3JkIEF1ZGlvIn0seyJuYW1lIjoiU2VudGVuY2UifSx7Im5hbWUiOiJTZW50ZW5jZSBNZWFuaW5nIn0seyJuYW1lIjoiU2VudGVuY2UgRnVyaWdhbmEifSx7Im5hbWUiOiJTZW50ZW5jZSBBdWRpbyJ9LHsibmFtZSI6Ik5vdGVzIn0seyJuYW1lIjoiUGl0Y2ggQWNjZW50In0seyJuYW1lIjoiUGl0Y2ggQWNjZW50IE5vdGVzIn0seyJuYW1lIjoiRnJlcXVlbmN5In0seyJuYW1lIjoiUGljdHVyZSJ9XSwia2luZCI6Im5vcm1hbCJ9LHsia2luZCI6Im5vcm1hbCIsImZpZWxkcyI6W3sibmFtZSI6IldvcmQifSx7Im5hbWUiOiJXb3JkIFJlYWRpbmcifSx7Im5hbWUiOiJXb3JkIE1lYW5pbmcifSx7Im5hbWUiOiJXb3JkIEZ1cmlnYW5hIn0seyJuYW1lIjoiV29yZCBBdWRpbyJ9LHsibmFtZSI6IlNlbnRlbmNlIn0seyJuYW1lIjoiU2VudGVuY2UgTWVhbmluZyJ9LHsibmFtZSI6IlNlbnRlbmNlIEZ1cmlnYW5hIn0seyJuYW1lIjoiU2VudGVuY2UgQXVkaW8ifSx7Im5hbWUiOiJOb3RlcyJ9LHsibmFtZSI6IlBpdGNoIEFjY2VudCJ9LHsibmFtZSI6IlBpdGNoIEFjY2VudCBOb3RlcyJ9LHsibmFtZSI6IkZyZXF1ZW5jeSJ9LHsibmFtZSI6IlBpY3R1cmUifV0sIm5hbWUiOiJLYWlzaGkgMS41aysrIn0seyJmaWVsZHMiOlt7Im5hbWUiOiJLYW5qaSJ9LHsibmFtZSI6IkthbmEifSx7Im5hbWUiOiJONUthbmppIn0seyJuYW1lIjoiRW5nbGlzaCJ9LHsibmFtZSI6IlBPUyJ9LHsibmFtZSI6IjJuZERlZiJ9LHsibmFtZSI6Ik90aGVyRGVmIn0seyJuYW1lIjoiQXVkaW8ifV0sIm5hbWUiOiJVbHRpbWF0ZSBMYXlvdXQiLCJraW5kIjoibm9ybWFsIn0seyJraW5kIjoibm9ybWFsIiwiZmllbGRzIjpbeyJuYW1lIjoiRnJvbnQifSx7Im5hbWUiOiJCYWNrIn0seyJuYW1lIjoiU2VudGVuY2UifSx7Im5hbWUiOiJTZW50ZW5jZSBObyB3b3JkIn0seyJuYW1lIjoiUmVhZGluZyJ9LHsibmFtZSI6IkthbmppIn0seyJuYW1lIjoiQXVkaW8ifV0sIm5hbWUiOiJZb21pY2hhbiJ9XSwicHJvZmlsZXMiOlt7Im5hbWUiOiLjg6bjg7zjgrbjg7wgMSJ9XX0=")
//                let decoder = JSONDecoder()
//                let infos = try decoder.decode(AnkiInfo.self, from: data!)
//                DispatchQueue.main.async {
//                    print("INFOS \(infos)")
//                    settings.ankiInfo = infos
//                }
//            }catch {
//            }
//        }
    }
    
    func fetchAnkiDecks() {
        guard let url = URL(string: "anki://x-callback-url/infoForAdding?x-success=\("riidaa://anki-setup".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            return
        }
        UIApplication.shared.open(url, options: [:])
    }
}

#Preview {
    AnkiView()
        .environmentObject(SettingsModel())
}
