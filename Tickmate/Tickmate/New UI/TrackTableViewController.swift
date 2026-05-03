//
//  TrackTableViewController.swift
//  PageView
//
//  Created by Elaine Lyons on 2/10/22.
//

import UIKit
import SwiftUI
import Combine
import CoreData

/// Per-page view controller. Owns:
///   * `headerView`  – the TracksHeaderView (per-track icon buttons + bottom
///                      divider) pinned to the top of the page.
///   * `tableView`   – the day rows below the header.
///
/// Used to be a `UITableViewController` (so its view _was_ the table and
/// `headerView` rode along as a section header). That made the header sticky
/// for free, but plain-style table sticky section headers pick up an iOS
/// translucency / material effect when content scrolls underneath, which we
/// don't want here. Promoting to a plain `UIViewController` lets the header
/// live as a sibling of the table — always visible, always opaque, no
/// section-header machinery involved.
class TrackTableViewController: UIViewController {

    //MARK: Properties

    /// Total number of days rendered in the page. Mirrors the SwiftUI
    /// `TicksView` constant.
    static let numDays = 365

    var index = 0
    var scrollController: ScrollController = .shared

    /// Day rows. Owned explicitly now that we're no longer a UITableViewController.
    let tableView = UITableView()

    private let tracksContainer = TracksContainer()

    @AppStorage(Defaults.weekSeparatorLines.rawValue)
    private var weekSeparatorLines: Bool = true

    @AppStorage(Defaults.weekSeparatorSpaces.rawValue)
    private var weekSeparatorSpaces: Bool = true

    @AppStorage(Defaults.todayAtTop.rawValue, store: UserDefaults(suiteName: groupID))
    private var todayAtTop: Bool = false

    @AppStorage(Defaults.todayLock.rawValue, store: UserDefaults(suiteName: groupID))
    private var todayLock: Bool = false

    /// FRC backing the on-screen tracks list. Set up by `load(predicate:)`.
    /// Owning the FRC here means rename / archive / reorder / add / remove
    /// operations propagate live without the host page VC having to feed us
    /// new snapshots on every Core Data change.
    private var tracksFRC: NSFetchedResultsController<Track>?

    private var subscriptions: Set<AnyCancellable> = []
    private let headerView = TracksHeaderView()
    private weak var trackController: TrackController? = .shared

    /// Cached value used to detect when `todayAtTop` flips so the table can be
    /// re-scrolled to the appropriate "rest" edge.
    private var previousTodayAtTop: Bool = false

    /// Build a fresh FRC for the given track-fetching predicate and start
    /// observing it. The host page VC always calls this exactly once, right
    /// after init, with the predicate appropriate to the page (all tracks /
    /// ungrouped tracks / tracks in a group).
    func load(predicate: NSPredicate) {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.sortDescriptors = TrackController.sortDescriptors
        fetchRequest.predicate = predicate

        let frc = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        frc.delegate = self
        do {
            try frc.performFetch()
        } catch {
            NSLog("Error fetching tracks: \(error)")
        }
        tracksFRC = frc
        tracksContainer.tracks = frc.fetchedObjects ?? []
    }

    //MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        // Lay out header and table as siblings. The header sits at the top
        // of the page (full width, fixed height matching the date sidebar's
        // section header). The table fills the rest, all the way to the
        // bottom of the parent so cells can scroll behind the home indicator.
        headerView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: ViewController.headerHeight),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tableView.canCancelContentTouches = true
        // Belt-and-braces: ensure the page table has an opaque background so
        // the page VC's underlying scroll view never peeks through if any
        // ancestor is somehow transparent.
        tableView.backgroundColor = .systemBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DayTableViewCell.self, forCellReuseIdentifier: "DayCell")
        tableView.scrollsToTop = todayAtTop
        previousTodayAtTop = todayAtTop
        headerView.delegate = self
        scrollToInitialPosition()

        scrollController.$isPaging.sink { [weak self] isPaging in
            guard let self = self else { return }

            if isPaging {
                self.tableView.showsVerticalScrollIndicator = false
            } else {
                // We only want to flash the scroll bar if the table is scrolled
                // away from its "rest" edge.
                let position: CGFloat
                if self.todayAtTop {
                    position = 0
                } else {
                    position = self.tableView.contentSize.height - self.tableView.bounds.size.height + self.tableView.contentInset.bottom
                }
                let offset = self.tableView.contentOffset.y
                let needsFlash = self.todayAtTop ? offset > position : offset < position
                if needsFlash {
                    self.tableView.showsVerticalScrollIndicator = true
                    self.tableView.flashScrollIndicators()
                }
                // If we set showsVerticalScrollIndicator to true here it'll show it, so leave it off
                // until the user actually starts scrolling again (see scrollViewWillBeginDragging).
            }
        }.store(in: &subscriptions)

        tracksContainer.$tracks.sink { [weak self] tracks in
            guard let self else { return }
            // Always reconfigure the header. The previous version of this
            // handler bailed out when `tableView.superview == nil`, but the
            // publisher fires synchronously inside viewDidLoad — before the
            // page VC has inserted our view into its scroll view — so the
            // very first emission for a freshly loaded page used to be
            // silently dropped. The result was that the per-track icon
            // buttons in the header didn't appear until a tick or any other
            // event re-published `tracksContainer.tracks`. Configuring the
            // header is cheap and the headerView holds onto its state
            // independently of being attached, so we can safely do it here.
            headerView.configure(with: tracks)

            // visibleCells returns an empty array on a non-attached table,
            // so this is a no-op in the early case rather than a hazard.
            tableView.visibleCells
                .compactMap { $0 as? DayTableViewCell }
                .forEach { $0.reconfigure(with: tracks) }
        }.store(in: &subscriptions)

        // Surface the SwiftUI todayLock alert as a UIAlertController so the
        // new UI can use the existing TrackController plumbing unchanged.
        trackController?.$todayLockAlert
            .compactMap { $0 }
            .sink { [weak self] alert in
                self?.presentTodayLockAlert(alert)
            }
            .store(in: &subscriptions)

        // Reload the table whenever any user default we depend on flips.
        // Unlike SwiftUI views where @AppStorage drives invalidation for free,
        // a UIViewController has to watch UserDefaults explicitly. Both the
        // standard suite (week separator preferences) and the app-group suite
        // (todayAtTop / todayLock) post their own didChange notifications.
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.applySettingsChange()
            }
            .store(in: &subscriptions)

        // Same handler is invoked when the host VC tells us the day may have
        // changed (app returned from background). applySettingsChange does the
        // right thing — reloadData re-runs cellForRowAt which re-evaluates
        // dayLabel against TrackController.date.
        NotificationCenter.default
            .publisher(for: .tickmateDataShouldRefresh)
            .sink { [weak self] _ in
                self?.applySettingsChange()
            }
            .store(in: &subscriptions)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollToInitialPosition()
    }

    //MARK: Settings

    /// Called whenever any UserDefaults value changes. Cheap to over-call:
    /// `tableView.reloadData()` only rebuilds the visible cells (the table
    /// keeps its scroll position), and `cellForRowAt` reads the latest
    /// `@AppStorage` values when it configures each cell.
    private func applySettingsChange() {
        // Always keep scrollsToTop in sync with the current direction.
        tableView.scrollsToTop = todayAtTop

        let directionFlipped = todayAtTop != previousTodayAtTop
        previousTodayAtTop = todayAtTop

        tableView.reloadData()

        if directionFlipped {
            // The "rest" edge has moved (top ↔ bottom). Snap to today on the
            // new edge so the user isn't left staring at a year ago.
            scrollToToday(animated: false)
        }
    }

    //MARK: Day <-> Row Mapping

    /// Maps a row in the table to the day it represents.
    /// When `todayAtTop` is on, row 0 == today (day 0). Otherwise row 0 ==
    /// the oldest day (numDays - 1) and the last row is today.
    func day(forRow row: Int) -> Int {
        todayAtTop ? row : Self.numDays - row - 1
    }

    /// Inverse of `day(forRow:)`.
    func row(forDay day: Int) -> Int {
        todayAtTop ? day : Self.numDays - day - 1
    }

    //MARK: Private

    /// Move the table to its "rest" edge. With `todayAtTop` on that's the
    /// top of the view; otherwise it's the bottom (so today is just above
    /// the safe area).
    private func scrollToInitialPosition() {
        guard !tableView.isDragging, !tableView.isDecelerating else { return }

        guard scrollController.initialized else {
            scrollToToday()
            return
        }

        let scrollPosition = scrollController.contentOffset
        self.tableView.contentOffset = scrollPosition
    }

    private func scrollToToday(animated: Bool = false) {
        let indexPath = IndexPath(row: row(forDay: 0), section: 0)
        let position: UITableView.ScrollPosition = todayAtTop ? .top : .bottom
        tableView.scrollToRow(at: indexPath, at: position, animated: animated)
        // Always publish the resulting offset back to ScrollController so the
        // sidebar's date column scrolls to match. Previously this was gated on
        // `initialized`, which meant the very first scroll-to-today on launch
        // never reached the sidebar — leaving it stuck at offset zero showing
        // year-old dates instead of today.
        // Layout may not be complete yet when this is called from viewDidLoad,
        // so defer the read of `tableView.contentOffset` until the next runloop
        // tick to ensure scrollToRow has actually moved the table.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.scrollController.contentOffset = self.tableView.contentOffset
        }
    }

    //MARK: Today Lock

    private func presentTodayLockAlert(_ alert: AlertItem) {
        // Each TrackTableViewController in the page view will subscribe to
        // the same publisher. Only the visible one should present.
        guard view.window != nil, presentedViewController == nil else { return }

        let controller = UIAlertController(
            title: alert.title,
            message: alert.message,
            preferredStyle: .alert
        )
        controller.addAction(UIAlertAction(title: "OK", style: .default))
        present(controller, animated: true) { [weak self] in
            // Match the SwiftUI dismiss behaviour by clearing the alert item.
            self?.trackController?.todayLockAlert = nil
        }
    }

}

//MARK: - UITableViewDataSource

extension TrackTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Self.numDays
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DayCell", for: indexPath)

        if let dayCell = cell as? DayTableViewCell {
            let day = day(forRow: indexPath.row)
            // canEdit mirrors TicksView: today is always editable; other days
            // are editable only when today-lock is off.
            let canEdit = day == 0 || !todayLock
            dayCell.configure(
                with: tracksContainer.tracks,
                day: day,
                lines: weekSeparatorLines,
                spaces: weekSeparatorSpaces,
                canEdit: canEdit,
                delegate: self
            )
        }

        scrollToInitialPosition()
        return cell
    }
}

//MARK: - UITableViewDelegate (and UIScrollViewDelegate via inheritance)

extension TrackTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let day = day(forRow: indexPath.row)
        let baseHeight: CGFloat = 44
        if weekSeparatorSpaces && TrackController.shared.shouldShowSeparatorBelow(day: day) {
            return baseHeight + 8 // Add 8 points of spacing for week separators
        }
        return baseHeight
    }

    // No `viewForHeaderInSection` / `heightForHeaderInSection`: the per-page
    // TracksHeaderView lives outside the table now (see viewDidLoad), so
    // there's no section header at all.

    //MARK: Scroll View Delegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // This function gets called on view load with a value of zero,
        // resetting the scroll position every time a new screen loads.
        // This guard prevents that. The end functions below allow it
        // to still sync position when it is 0.
        guard scrollView.contentOffset != .zero,
              !scrollController.isPaging else { return }
        scrollController.contentOffset = scrollView.contentOffset
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollController.contentOffset = scrollView.contentOffset
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollController.contentOffset = scrollView.contentOffset
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Avoid unnecessary calls to setter as that seems to flash it
        if !tableView.showsVerticalScrollIndicator {
            tableView.showsVerticalScrollIndicator = true
        }
        scrollController.initialized = true
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollController.contentOffset = scrollView.contentOffset
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        // When today is at the top, let the OS scroll to top for us.
        // Otherwise, scroll to today (which is at the bottom) instead.
        if todayAtTop {
            return true
        }
        scrollToToday(animated: true)
        return false
    }
}

//MARK: - NSFetchedResultsControllerDelegate

extension TrackTableViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // The TracksContainer publisher is what the visible cells and the
        // header observe; just re-publish the full set when CoreData reports
        // any change. The track count for a group page should never be large
        // enough for this to matter performance-wise.
        guard let frc = controller as? NSFetchedResultsController<Track> else { return }
        tracksContainer.tracks = frc.fetchedObjects ?? []
    }
}

//MARK: - DayTableViewCellDelegate

extension TrackTableViewController: DayTableViewCellDelegate {
    func dayCell(_ cell: DayTableViewCell, didTapLockedDayAt day: Int) {
        // Forward to TrackController so it can run the same two-tap-then-alert
        // logic the SwiftUI version uses.
        trackController?.didTapLockedDay()
    }
}

//MARK: - TracksHeaderViewDelegate

extension TrackTableViewController: TracksHeaderViewDelegate {
    func tracksHeader(_ header: TracksHeaderView, didTap track: Track) {
        // Mirror the SwiftUI .sheet(item: $showingTrack) behaviour: present
        // TrackView for the tapped track wrapped in its own NavigationView.
        let host = UIHostingController(rootView: TrackSheet(track: track, host: self))
        present(host, animated: true)
    }

    /// Called by the SwiftUI TrackSheet when the user taps Done; the host
    /// handles the actual UIKit dismiss.
    func dismissTrackSheet() {
        presentedViewController?.dismiss(animated: true)
    }
}

//MARK: - SwiftUI sheet wrapper

private struct TrackSheet: View {
    let track: Track
    weak var host: TrackTableViewController?

    @State private var selection: Track?
    @StateObject private var trackController = TrackController.shared
    @StateObject private var groupController = GroupController.shared
    @StateObject private var vcContainer = ViewControllerContainer()

    var body: some View {
        NavigationView {
            TrackView(track: track, selection: $selection, sheet: true)
        }
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(trackController)
        .environmentObject(groupController)
        .environmentObject(vcContainer)
        .onAppear { selection = track }
        // TrackView sets selection back to nil to dismiss; relay that to the
        // UIKit host so it can actually run the dismiss animation.
        .onChange(of: selection) { newValue in
            if newValue == nil { host?.dismissTrackSheet() }
        }
    }
}
