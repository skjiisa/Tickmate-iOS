//
//  SettingsView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 3/9/21.
//

import SwiftUI
import SwiftDate

struct SettingsView: View {
    
    @AppStorage(Defaults.customDayStart.rawValue) private var customDayStart: Bool = false
    @AppStorage(Defaults.weekSeparatorSpaces.rawValue) private var weekSeparatorSpaces: Bool = true
    @AppStorage(Defaults.weekSeparatorLines.rawValue) private var weekSeparatorLines: Bool = true
    @AppStorage(Defaults.weekStartDay.rawValue) private var weekStartDay = 2
    @AppStorage(Defaults.relativeDates.rawValue) private var relativeDates = true
    
    @EnvironmentObject private var trackController: TrackController
    
    @Binding var showing: Bool
    
    @Binding var timeOffset: Date
    @Binding var customDayStartChanged: Bool
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $customDayStart.animation()) {
                    TextWithCaption(
                        text: "Custom day rollover time",
                        caption: "For staying up past midnight")
                }
                
                if customDayStart {
                    DatePicker(selection: $timeOffset, displayedComponents: [.hourAndMinute]) {
                        TextWithCaption(
                            text: "New day start time",
                            caption: "")
                    }
                }
            }
            
            Section {
                Toggle(isOn: $relativeDates) {
                    TextWithCaption(text: "Use relative dates", caption: "Today, Yesterday")
                }
            }
            
            Section(header: Text("Week Separators")) {
                Toggle("Separator lines", isOn: $weekSeparatorLines)
                Toggle("Separator spaces", isOn: $weekSeparatorSpaces)
                Picker("Week starts on", selection: $weekStartDay) {
                    Text("Monday")
                        .tag(2)
                    Text("Tuesday")
                        .tag(3)
                    Text("Wednesday")
                        .tag(4)
                    Text("Thursday")
                        .tag(5)
                    Text("Friday")
                        .tag(6)
                    Text("Saturday")
                        .tag(7)
                    Text("Sunday")
                        .tag(1)
                }
            }
            
            Section(header: Text("App Information")) {
                Link("Support Website", destination: URL(string: "https://github.com/Isvvc/Tickmate-iOS/issues")!)
                Link("Email Support", destination: URL(string: "mailto:lyons@tuta.io")!)
                Link("Privacy Policy", destination: URL(string: "https://github.com/Isvvc/Tickmate-iOS/blob/main/Privacy%20Policy.txt")!)
                Link("Source Code", destination: URL(string: "https://github.com/Isvvc/Tickmate-iOS/")!)
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Done") {
                    showing = false
                }
            }
        }
        .onChange(of: customDayStart) { _ in
            customDayStartChanged = true
        }
        .onChange(of: timeOffset) { _ in
            customDayStartChanged = true
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView(showing: .constant(true), timeOffset: .constant(Date()), customDayStartChanged: .constant(false))
        }
    }
}
