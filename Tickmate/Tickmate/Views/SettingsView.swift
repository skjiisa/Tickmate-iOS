//
//  SettingsView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 3/9/21.
//

import SwiftUI
import SwiftDate

struct SettingsView: View {
    
    @AppStorage(Defaults.customDayStart.rawValue, store: UserDefaults(suiteName: groupID))
    private var customDayStart: Bool = false
    @AppStorage(Defaults.customDayStartMinutes.rawValue, store: UserDefaults(suiteName: groupID))
    private var minutes: Int = 60
    @AppStorage(Defaults.weekStartDay.rawValue, store: UserDefaults(suiteName: groupID))
    private var weekStartDay = 2
    
    @AppStorage(Defaults.weekSeparatorSpaces.rawValue) private var weekSeparatorSpaces: Bool = true
    @AppStorage(Defaults.weekSeparatorLines.rawValue) private var weekSeparatorLines: Bool = true
    @AppStorage(Defaults.relativeDates.rawValue) private var relativeDates = true
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    
    @EnvironmentObject private var trackController: TrackController
    @EnvironmentObject private var storeController: StoreController
    
    @Binding var showing: Bool
    
    @State private var timeOffset: Date = Date()
    @State private var showingRestrictedPaymentsAlert = false
    
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
                if let product = storeController.groupsProduct {
                    Button {
                        storeController.isAuthorizedForPayments
                            ? storeController.purchase(product)
                            : (showingRestrictedPaymentsAlert = true)
                    } label: {
                        HStack {
                            TextWithCaption(product.localizedTitle, caption: product.localizedDescription)
                                .foregroundColor(.primary)
                            Spacer()
                            if storeController.purchased.contains(product.productIdentifier) {
                                Text("Purchased!")
                                    .foregroundColor(.secondary)
                            } else if storeController.purchasing.contains(product.productIdentifier) {
                                ProgressView()
                            } else {
                                Text(
                                    product.price,
                                    formatter: storeController.priceFormatter
                                )
                                #if os(iOS)
                                .foregroundColor(storeController.isAuthorizedForPayments ? .accentColor : .secondary)
                                #endif
                            }
                        }
                    }
                    .disabled(storeController.purchased.contains(product.productIdentifier))
                    .alert(isPresented: $showingRestrictedPaymentsAlert) {
                        Alert(title: Text("Access restricted"), message: Text("You don't have permission to make purchases on this account."))
                    }
                } else {
                    ProgressView()
                }
                
                Button("Restore purchases") {
                    storeController.restorePurchases()
                }
                .alert(alertItem: $storeController.restored)
                
                #if DEBUG
                Button("Reset purchases (debug feature)") {
                    StoreController.Products.allCases.forEach {
                        UserDefaults.standard.set(false, forKey: $0.rawValue)
                        storeController.removePurchased(id: $0.rawValue)
                    }
                }
                #endif
            }
            
            Section(header: Text("App Information")) {
                if let version = appVersion,
                   let build = appBuild {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(version) (\(build))")
                            .foregroundColor(.secondary)
                    }
                }
                NavigationLink("Acknowledgements", destination: AcknowledgementsView())
            }
            
            Section {
                Link("Support Website", destination: URL(string: "https://github.com/skjiisa/Tickmate-iOS/issues")!)
                Link("Email Support", destination: URL(string: "mailto:tickmate@lyons.app")!)
                Link("Privacy Policy", destination: URL(string: "https://github.com/skjiisa/Tickmate-iOS/blob/main/Privacy%20Policy.txt")!)
                Link("Source Code", destination: URL(string: "https://github.com/skjiisa/Tickmate-iOS/")!)
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            // A WWDC talk said to always put close buttons in the top left, at
            // least for visionOS. Do they mean _left_ left, or leading??
            ToolbarItem(placement: .topBarLeading) {
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
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(TrackController())
        .environmentObject(StoreController())
    }
}
