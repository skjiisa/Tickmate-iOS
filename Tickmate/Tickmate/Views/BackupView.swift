//
//  BackupView.swift
//  Tickmate
//
//  Created by Elaine Lyons on 5/12/26.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Export

struct BackupExportView: View {
    @EnvironmentObject private var trackController: TrackController

    @State private var selectedTracks: Set<Track> = []
    @State private var allAreSelected = false
    @State private var includeSettings = true
    @State private var exportFile: BackupFile?
    @State private var isExporting = false

    @State private var resultAlert: ResultAlert?

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
            } footer: {
                Text("Groups containing selected tracks will be included automatically.")
            }
        }
        .navigationTitle("Export Backup")
        .sheet(item: $exportFile) { file in
            ShareSheet(activityItems: [file.url])
        }
        .alert(item: $resultAlert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message))
        }
        .onAppear {
            selectedTracks = Set(allTracks)
        }
        .onChange(of: selectedTracks) { _ in
            allAreSelected = selectedTracks.count == allTracks.count
        }
    }

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
            resultAlert = ResultAlert(title: "Export Failed", message: error.localizedDescription)
        }
    }
}

// MARK: - Import

struct BackupImportView: View {
    @State private var isImporting = false
    @State private var pendingImportURL: URL?
    @State private var isImportInProgress = false

    @State private var activeAlert: ActiveAlert?

    private enum ActiveAlert: Identifiable {
        case importConfirm
        case result(ResultAlert)

        var id: String {
            switch self {
            case .importConfirm: return "importConfirm"
            case .result(let alert): return "result-\(alert.title)"
            }
        }
    }

    var body: some View {
        List {
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
            } footer: {
                Text("Import a .tickmatebackup or .json file previously exported from Tickmate, or a .db database exported from Tickmate on another platform.")
            }
        }
        .navigationTitle("Import Backup")
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
            case .result(let alert):
                return Alert(title: Text(alert.title), message: Text(alert.message))
            }
        }
    }

    private func didPickImportFile(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            pendingImportURL = url
            activeAlert = .importConfirm
        case .failure(let error):
            activeAlert = .result(ResultAlert(title: "Could not open file", message: error.localizedDescription))
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
                activeAlert = .result(ResultAlert(title: "Import Successful", message: "Your data has been restored."))
            } catch {
                activeAlert = .result(ResultAlert(title: "Import Failed", message: error.localizedDescription))
            }
            pendingImportURL = nil
            isImportInProgress = false
        }
    }
}

private struct ResultAlert: Identifiable {
    let title: String
    let message: String
    var id: String { title }
}

struct BackupView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                BackupExportView()
            }
            NavigationView {
                BackupImportView()
            }
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(TrackController(preview: true))
    }
}
