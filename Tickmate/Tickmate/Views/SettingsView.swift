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
    @AppStorage(Defaults.weekStartDay.rawValue) private var weekStartDay = 2
    @AppStorage(Defaults.relativeDates.rawValue) private var relativeDates = true
    
    @EnvironmentObject private var trackController: TrackController
    @EnvironmentObject private var storeController: StoreController
    
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
            
            Section(header: Text("Premium Features"), footer: Text("Groups allow you to swipe left and right between different sets of tracks from the main screen")) {
                ForEach(storeController.products, id: \.productIdentifier) { product in
                    Button {
                        storeController.purchase(product)
                    } label: {
                        HStack {
                            TextWithCaption(product.localizedTitle, caption: product.localizedDescription)
                                .foregroundColor(.primary)
                            Spacer()
                            if storeController.purchased.contains(product.productIdentifier) {
                                Text("Purchased!")
                                    .foregroundColor(.secondary)
                            } else {
                                Text(product.price, formatter: storeController.priceFormatter)
                                .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .disabled(storeController.purchased.contains(product.productIdentifier))
                }
                
                #if DEBUG
                Button("Reset purchases (debug feature)") {
                    StoreController.Products.allCases.forEach {
                        UserDefaults.standard.set(false, forKey: $0.rawValue)
                        storeController.purchased.remove($0.rawValue)
                    }
                }
                #endif
            }
            
            Section(header: Text("App Information")) {
                Link("Support Website", destination: URL(string: "https://github.com/Isvvc/Tickmate-iOS/issues")!)
                Link("Email Support", destination: URL(string: "mailto:lyons@tuta.io")!)
                Link("Privacy Policy", destination: URL(string: "https://github.com/Isvvc/Tickmate-iOS/blob/main/Privacy%20Policy.txt")!)
                Link("Source Code", destination: URL(string: "https://github.com/Isvvc/Tickmate-iOS/")!)
            }
            
            Section {
                NavigationLink("Acknowledgements", destination: AcknowledgementsView())
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
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
            storeController.fetchProducts()
        }
        .onChange(of: customDayStart, perform: updateCustomDayStart)
        .onChange(of: timeOffset, perform: updateCustomDayStart)
        .onChange(of: weekStartDay) { value in
            trackController.weekStartDay = value
        }
        .onChange(of: relativeDates) { value in
            trackController.relativeDates = value
        }
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
        .environmentObject(TrackController())
        .environmentObject(StoreController())
    }
}
