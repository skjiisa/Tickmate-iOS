//
//  BackupView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 5/12/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct BackupView: View {
    @EnvironmentObject private var trackController: TrackController

    @State private var selectedTracks: Set<Track> = []
    @State private var allAreSelected = false
    @State private var includeSettings = true
    @State private var exportFile: BackupFile?
    @State private var isExporting = false

    @State private var isImporting = false
    @State private var pendingImportURL: URL?
    @State private var isImportInProgress = false

    @State private var activeAlert: ActiveAlert?

    private enum ActiveAlert: Identifiable {
        case importConfirm
        case result(title: String, message: String)

        var id: String {
            switch self {
            case .importConfirm: return "importConfirm"
            case .result(let title, _): return "result-\(title)"
            }
        }
    }

    private struct BackupFile: Identifiable {
        let url: URL
        var id: URL { url }
    }

    private var allTracks: [Track] {
        let active = trackController.fetchedResultsController.fetchedObjects ?? []
        let archived = trackController.archivedTracksFRC.fetchedObjects ?? []
        return active + archived
    }

    var body: some View {
        List {
            exportSection
            importSection
        }
        .navigationTitle("Backup & Restore")
        .sheet(item: $exportFile) { file in
            ShareSheet(activityItems: [file.url])
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.tickmateBackup, .json, .sqliteDatabase],
            onCompletion: didPickImportFile
        )
        .alert(item: $activeAlert) { item in
            switch item {
            case .importConfirm:
                return Alert(
                    title: Text("Import Backup"),
                    message: Text("Replace will delete all existing data before importing. Merge will add imported data alongside existing data.\n\nChanges will sync to all your devices via iCloud."),
                    primaryButton: .destructive(Text("Replace All")) {
                        performImport(mode: .replace)
                    },
                    secondaryButton: .default(Text("Merge")) {
                        performImport(mode: .merge)
                    }
                )
            case .result(let title, let message):
                return Alert(title: Text(title), message: Text(message))
            }
        }
    }

    // MARK: - Export

    private var exportSection: some View {
        Section {
            Toggle("Include Settings", isOn: $includeSettings)

            Button(allAreSelected ? "Deselect All" : "Select All") {
                if allAreSelected {
                    selectedTracks.removeAll()
                } else {
                    selectedTracks = Set(allTracks)
                }
            }

            ForEach(allTracks, id: \.self) { track in
                Button {
                    selectedTracks.toggle(track)
                } label: {
                    HStack {
                        Image(systemName: selectedTracks.contains(track) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedTracks.contains(track) ? .accentColor : .secondary)
                        if let systemImage = track.systemImage {
                            Image(systemName: systemImage)
                                .resizable()
                                .scaledToFit()
                                .padding(6)
                                .frame(width: 36, height: 36)
                                .foregroundColor(track.lightText ? .white : .black)
                                .background(
                                    Color(rgb: Int(track.color))
                                        .cornerRadius(4)
                                )
                        }
                        Text(track.name ?? "Unnamed Track")
                            .foregroundColor(.primary)
                        if track.isArchived {
                            Text("(Archived)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }

            Button("Export Backup") {
                exportBackup()
            }
            .disabled(selectedTracks.isEmpty && !includeSettings)
        } header: {
            Text("Export")
        } footer: {
            Text("Groups containing selected tracks will be included automatically.")
        }
        .onAppear {
            selectedTracks = Set(allTracks)
        }
        .onChange(of: selectedTracks) { _ in
            allAreSelected = selectedTracks.count == allTracks.count
        }
    }

    // MARK: - Import

    private var importSection: some View {
        Section {
            Button("Import from File") {
                isImporting = true
            }
            .disabled(isImportInProgress)

            if isImportInProgress {
                HStack {
                    ProgressView()
                    Text("Importing...")
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Import")
        } footer: {
            Text("Import a .tickmatebackup or .json file previously exported from Tickmate, or a .db database exported from Tickmate for Android.")
        }
    }

    // MARK: - Actions

    private func exportBackup() {
        guard !isExporting else { return }
        isExporting = true
        defer { isExporting = false }

        do {
            let url = try BackupController.export(
                tracks: Array(selectedTracks),
                includeSettings: includeSettings
            )
            exportFile = BackupFile(url: url)
        } catch {
            activeAlert = .result(title: "Export Failed", message: error.localizedDescription)
        }
    }

    private func didPickImportFile(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            pendingImportURL = url
            activeAlert = .importConfirm
        case .failure(let error):
            activeAlert = .result(title: "Could not open file", message: error.localizedDescription)
        }
    }

    private func performImport(mode: ImportMode) {
        guard let url = pendingImportURL else { return }
        isImportInProgress = true

        DispatchQueue.main.async {
            do {
                try BackupController.importBackup(
                    from: url,
                    mode: mode,
                    restoreSettings: true
                )
                activeAlert = .result(title: "Import Successful", message: "Your data has been restored.")
            } catch {
                activeAlert = .result(title: "Import Failed", message: error.localizedDescription)
            }
            pendingImportURL = nil
            isImportInProgress = false
        }
    }
}

struct BackupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BackupView()
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(TrackController(preview: true))
    }
}
