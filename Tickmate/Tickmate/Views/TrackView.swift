//
//  TrackView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 2/23/21.
//

import SwiftUI
import UserNotifications

//MARK: TrackView

struct TrackView: View {
    
    //MARK: Properties
    
    @Environment(\.managedObjectContext) private var moc
    
    @AppStorage(StoreController.Products.groups.rawValue) private var groupsUnlocked: Bool = false
    
    @EnvironmentObject private var vcContainer: ViewControllerContainer
    @EnvironmentObject private var trackController: TrackController
    
    @ObservedObject var track: Track
    @Binding var selection: Track?
    let sheet: Bool
    
    @StateObject private var groups = TrackGroups()
    @State private var draftTrack = TrackRepresentation()
    @State private var enabled = true
    @State private var initialized = false
    @State private var showingSymbolPicker = false
    @State private var actionSheet: Action?
    @State private var fixTextField = false
    @State private var reminderTime = Date()
    @State private var notificationDeniedAlert: AlertItem?
    
    private var groupsEnabled: Bool {
        groupsUnlocked && !track.isArchived
    }

    @ViewBuilder
    private var groupsFooter: some View {
        if !groupsUnlocked {
            Text("Unlock the groups upgrade from the settings page.")
        } else if track.isArchived {
            Text("Unarchive to add to groups.")
        }
    }

    private var notificationToggleBinding: Binding<Bool> {
        Binding(
            get: { draftTrack.notificationMinute != nil },
            set: { isOn in
                if isOn {
                    checkNotificationPermission()
                    draftTrack.notificationMinute = 540
                } else {
                    draftTrack.notificationMinute = nil
                }
                setEditMode()
            }
        )
    }
    
    //MARK: Body
    
    var body: some View {
        Form {
            Section(footer: groupsFooter) {
                Toggle("Enabled", isOn: $enabled)
                NavigationLink(destination: GroupsPicker(track: track, groups: groups)) {
                    HStack {
                        Text("Groups")
                        Spacer()
                        Text(groups.name)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(!groupsEnabled)
            }
            
            nameSection
            
            settingsSection

            reminderSection

            if !vcContainer.editMode.isEditing {
                footerSection
            }
        }
        .navigationTitle("Track details")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                StateEditButton(editMode: $vcContainer.editMode, doneText: "Save") {
                    if vcContainer.editMode == .inactive {
                        save()
                    }
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                if sheet || vcContainer.editMode.isEditing {
                    Button(vcContainer.editMode.isEditing ? "Cancel" : "Done") {
                        vcContainer.editMode.isEditing ? cancel() : (selection = nil)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(vcContainer.editMode.isEditing)
        .onChange(of: vcContainer.editMode) { value in
            if !value.isEditing {
                correctedKeyboardDismiss()
            }
        }
        .onAppear {
            if !initialized {
                enabled = track.enabled
                groups.load(track)
                draftTrack.load(track: track)
                if let notificationMinute = draftTrack.notificationMinute {
                    let minutes = Int(notificationMinute)
                    let hours = minutes / 60
                    let mins = minutes % 60
                    var components = DateComponents()
                    components.hour = hours
                    components.minute = mins
                    if let date = Calendar.current.date(from: components) {
                        reminderTime = date
                    }
                }
                initialized = true
            }
            setEditMode()
        }
        .alert(item: $notificationDeniedAlert) { _ in
            Alert(
                title: Text("Notifications Disabled"),
                message: Text("To enable notifications, please allow notifications in Settings."),
                primaryButton: .default(Text("Open Settings")) {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                    draftTrack.notificationMinute = nil
                    setEditMode()
                },
                secondaryButton: .cancel {
                    draftTrack.notificationMinute = nil
                    setEditMode()
                }
            )
        }
        .onDisappear {
            if enabled != track.enabled {
                track.enabled = enabled
                PersistenceController.save(context: moc)
            }
            vcContainer.deactivateEditMode()
        }
    }
    
    // MARK: Name section

    private var nameSection: some View {
        Section(header: Text("Name")) {
            TextField("Name", text: $draftTrack.name)
                .introspect(.textField, on: .iOS(.v14, .v15, .v16, .v17)) { textField in
                    vcContainer.textField = textField
                    vcContainer.shouldReturn = {
                        correctedKeyboardDismiss()
                        setEditMode()
                        return false
                    }
                    vcContainer.textFieldShouldEnableEditMode = true
                    textField.delegate = vcContainer
                }
                .id(fixTextField)
                .onAppear {
                    guard #available(iOS 15, *) else { return }
                    guard #unavailable(iOS 17) else { return }
                    guard !fixTextField else { return }
                    fixTextField = true
                }
        }
    }

    // MARK: Settings section

    private var settingsSection: some View {
        Section(header: Text("Settings")) {
            Toggle(isOn: $draftTrack.multiple.onChange(setEditMode)) {
                TextWithCaption(
                    text: "Allow multiple",
                    caption: "Multiple ticks on a day will be counted."
                        + " Long press to decrease counter.")
            }

            Toggle(isOn: $draftTrack.reversed.animation().onChange(setEditMode)) {
                TextWithCaption(
                    text: "Reversed",
                    caption: "Days will be ticked by default."
                        + " Tapping a day will untick it."
                        + " Good for tracking abstaining from bad habits.")
            }

            if draftTrack.reversed {
                DatePicker(selection: $draftTrack.startDate.onChange(setEditMode), in: Date.distantPast...trackController.date, displayedComponents: [.date]) {
                    TextWithCaption(
                        text: "Start date",
                        caption: "Days after this will automatically be ticked unless you untick them.")
                }
            }

            ColorPicker("Color", selection: $draftTrack.color.onChange(setEditMode), supportsOpacity: false)

            NavigationLink(
                destination: SymbolPicker(selection: $draftTrack.systemImage.onChange({ _ in
                    showingSymbolPicker = false
                    setEditMode()
                })),
                isActive: $showingSymbolPicker) {
                HStack {
                    Text("Symbol")
                    Spacer()
                    if let symbol = draftTrack.systemImage {
                        Image(systemName: symbol)
                            .imageScale(.large)
                    }
                }
            }
        }
    }

    // MARK: Reminder section

    @ViewBuilder
    private var reminderSection: some View {
        if !draftTrack.reversed {
            Section(header: Text("Reminder")) {
                Toggle(isOn: notificationToggleBinding) {
                    TextWithCaption(
                        text: "Daily reminder",
                        caption: "Get notified if this track hasn't been completed by a set time.")
                }

                if draftTrack.notificationMinute != nil {
                    DatePicker("Time", selection: $reminderTime, displayedComponents: [.hourAndMinute])
                        .onChange(of: reminderTime) { _ in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                            let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
                            draftTrack.notificationMinute = Int16(minutes)
                            setEditMode()
                        }
                }
            }
        }
    }

    // MARK: Footer section

    private var footerSection: some View {
        Section {
            if #available(iOS 15, *) {
                Button("Delete", role: .destructive) {
                    actionSheet = .delete
                }
            } else {
                Button("Delete") {
                    actionSheet = .delete
                }
                .accentColor(.red)
            }
            
            Button(track.isArchived ? "Unarchive" : "Archive") {
                actionSheet = track.isArchived ? .unarchive : .archive
            }
        }
        .actionSheet(item: $actionSheet, content: self.actionSheet(for:))
    }
    
    private enum Action: Hashable, Identifiable {
        var id: Action { self }
        case delete
        case archive
        case unarchive
    }
    
    private func actionSheet(for action: Action) -> ActionSheet {
        switch action {
        case .delete:
            ActionSheet(
                title: Text("Are you sure you want to delete \(draftTrack.name.isEmpty ? "this track" : draftTrack.name)?"),
                buttons: [
                    .destructive(Text("Delete"), action: self.delete),
                    .cancel()
                ]
            )
        case .archive:
            ActionSheet(
                title: Text(Strings.archiveActionSheetTitle),
                message: Text(Strings.archiveActionSheetMessage),
                buttons: [
                    .destructive(Text("Archive"), action: self.archive),
                    .cancel(),
                ]
            )
        case .unarchive:
            ActionSheet(
                title: Text("Unarchive track?"),
                buttons: [
                    .default(Text("Unarchive"), action: self.unarchive),
                    .cancel(),
                ]
            )
        }
    }
    
    //MARK: Functions
    
    private func correctedKeyboardDismiss() {
        dismissKeyboard()
        if let correctedText = vcContainer.textField?.text {
            draftTrack.name = correctedText
        }
    }
    
    private func setEditMode(_: Any? = nil) {
        vcContainer.editMode = draftTrack == track ? .inactive : .active
    }
    
    private func save() {
        correctedKeyboardDismiss()
        trackController.save(draftTrack, to: track, context: moc)
    }
    
    private func cancel() {
        if track.name == "New Track",
           track.ticks?.anyObject() == nil {
            // This is a brand new track. Delete it instead of exiting edit mode
            delete()
        } else {
            withAnimation {
                draftTrack.load(track: track)
                // In case the user entered edit mode without making any changes,
                // which would mean onChange(of: draftTrack) wouldn't get called.
                setEditMode()
            }
        }
    }
    
    private func delete() {
        selection = nil
        NotificationController.cancel(for: track)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation {
                trackController.objectWillChange.send()
                trackController.delete(track: track, context: moc)
                PersistenceController.save(context: moc)
            }
        }
    }

    private func archive() {
        NotificationController.cancel(for: track)
        track.archive()
        PersistenceController.save(context: moc)
        selection = nil
    }

    private func unarchive() {
        track.isArchived = false
        PersistenceController.save(context: moc)
        NotificationController.reschedule(track: track, context: moc)
    }

    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    NotificationController.requestPermission { granted in
                        if !granted {
                            notificationDeniedAlert = AlertItem(title: "Notifications Disabled")
                        }
                    }
                case .denied:
                    notificationDeniedAlert = AlertItem(title: "Notifications Disabled")
                case .authorized, .provisional, .ephemeral:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    // MARK: Strings
    
    private enum Strings {
        static var archiveActionSheetTitle: LocalizedStringKey = "Are you sure?"
        static var archiveActionSheetMessage: LocalizedStringKey = "Archiving a track will hide it from the main track list. It will still be viewable from the archived tracks page at the bottom of the track list."
    }
}

//MARK: GroupsPicker

struct GroupsPicker: View {
    
    @EnvironmentObject private var trackController: TrackController
    @EnvironmentObject private var groupController: GroupController
    
    @ObservedObject var track: Track
    @ObservedObject var groups: TrackGroups
    
    private var allGroups: [TrackGroup] {
        groupController.fetchedResultsController.fetchedObjects ?? []
    }
    
    var body: some View {
        Form {
            ForEach(allGroups) { group in
                Button {
                    withAnimation(.interactiveSpring()) {
                        groups.toggle(group, in: track)
                    }
                } label: {
                    HStack {
                        Text(group.displayName)
                        if groups.contains(group) {
                            Spacer()
                            Image(systemName: "checkmark")
                            #if os(iOS)
                                .foregroundColor(.accentColor)
                            #endif
                            // TODO: This only seems to animate when hiding
                                .transition(.scale)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("Groups")
        .onDisappear {
            withAnimation {
                groups.save(to: track)
                trackController.scheduleSave()
            }
        }
    }
}

//MARK: Previews

struct TrackView_Previews: PreviewProvider {
        
    static var track: Track = {
        try! PersistenceController.preview.container.viewContext.fetch(Track.fetchRequest()).first!
    }()
    
    static var previews: some View {
        NavigationView {
            TrackView(track: track, selection: .constant(nil), sheet: false)
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(ViewControllerContainer())
                .environmentObject(TrackController())
                .environmentObject(GroupController())
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
