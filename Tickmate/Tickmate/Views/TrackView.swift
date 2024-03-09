//
//  TrackView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 2/23/21.
//

import SwiftUI

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
    
    private var groupsFooter: some View {
        groupsUnlocked
            ? AnyView(EmptyView())
            : AnyView(Text("Unlock the groups upgrade from the settings page"))
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
                .disabled(!groupsUnlocked)
            }
            
            Section(header: Text("Name")) {
                TextField("Name", text: $draftTrack.name)
                    .introspect(.textField, on: .iOS(.v14, .v15, .v16, .v17)) { textField in
                        vcContainer.textField = textField
                        vcContainer.shouldReturn = {
                            // There is a bug with SwiftUI TextFields that causes them
                            // to revert autocorrect changes on return. Dismissing the
                            // keyboad before returning fixes the issue visually. Setting
                            // the name to the UITextField's text fixes it mechanically.
                            correctedKeyboardDismiss()
                            setEditMode()
                            return false
                        }
                        vcContainer.textFieldShouldEnableEditMode = true
                        textField.delegate = vcContainer
                    }
                    .id(fixTextField)
                    .onAppear {
                        // iOS 15 doesn't seem to like actually loading the text field's text on appear
                        guard #available(iOS 15, *) else { return }
                        guard #unavailable(iOS 17) else { return }
                        guard !fixTextField else { return }
                        fixTextField = true
                    }
            }
            
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
                initialized = true
            }
            setEditMode()
        }
        .onDisappear {
            if enabled != track.enabled {
                track.enabled = enabled
                PersistenceController.save(context: moc)
            }
            vcContainer.deactivateEditMode()
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation {
                trackController.objectWillChange.send()
                trackController.delete(track: track, context: moc)
                PersistenceController.save(context: moc)
            }
        }
    }
    
    private func archive() {
        track.isArchived = true
        trackController.scheduleSave()
    }
    
    private func unarchive() {
        track.isArchived = false
        trackController.scheduleSave()
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
