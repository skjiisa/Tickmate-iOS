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
    @AppStorage(Defaults.customDayStartMinutes.rawValue) private var minutes: Int = 60
    @AppStorage(Defaults.weekSeparatorSpaces.rawValue) private var weekSeparatorSpaces: Bool = true
    @AppStorage(Defaults.weekSeparatorLines.rawValue) private var weekSeparatorLines: Bool = true
    
    @EnvironmentObject private var trackController: TrackController
    
    @Binding var showing: Bool
    
    @State private var timeOffset: Date = Date()
    
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
            
            Section(header: Text("Week Separators")) {
                Toggle("Separator lines", isOn: $weekSeparatorLines)
                Toggle("Separator spaces", isOn: $weekSeparatorSpaces)
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
        .onAppear {
            if let date = DateInRegion(components: { dateComponents in
                dateComponents.minute = minutes
            }, region: .current) {
                timeOffset = date.date
            }
        }
        .onChange(of: customDayStart, perform: updateCustomDayStart)
        .onChange(of: timeOffset, perform: updateCustomDayStart)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func updateCustomDayStart(_: Any? = nil) {
        let components = timeOffset.in(region: .current).dateComponents
        minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        trackController.setCustomDayStart(minutes: minutes)
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView(showing: .constant(true))
        }
    }
}
