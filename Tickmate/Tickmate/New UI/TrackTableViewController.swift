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

class TrackTableViewController: UITableViewController {

    //MARK: Properties

    /// Total number of days rendered in the page. Mirrors the SwiftUI
    /// `TicksView` constant.
    static let numDays = 365

    var index = 0
    var scrollController: ScrollController = .shared

    private let tracksContainer = TracksContainer()

    @AppStorage(Defaults.weekSeparatorLines.rawValue)
    private var weekSeparatorLines: Bool = true

    @AppStorage(Defaults.weekSeparatorSpaces.rawValue)
    private var weekSeparatorSpaces: Bool = true

    @AppStorage(Defaults.todayAtTop.rawValue, store: UserDefaults(suiteName: groupID))
    private var todayAtTop: Bool = false

    @AppStorage(Defaults.todayLock.rawValue, store: UserDefaults(suiteName: groupID))
    private var todayLock: Bool = false

    var group: TrackGroup? {
        didSet {
            guard let group else { return }
            //TODO: Create FRC
            let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()

            fetchRequest.sortDescriptors = TrackController.sortDescriptors
            // Match SwiftUI TicksView.standardPredicate: enabled, not archived,
            // belonging to this group.
            fetchRequest.predicate = NSPredicate(
                format: "enabled == YES AND isArchived == NO AND %@ IN groups",
                group
            )

            if let tracks = try? PersistenceController.shared.container.viewContext.fetch(fetchRequest) {
                load(tracks: tracks)
            }
        }
    }

    private var initialized = false
    private var subscriptions: Set<AnyCancellable> = []
    private let headerView = TracksHeaderView()
    private weak var trackController: TrackController? = .shared

    func load(tracks: [Track]) {
        tracksContainer.tracks = tracks
    }

    //MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.canCancelContentTouches = true

        tableView.register(DayTableViewCell.self, forCellReuseIdentifier: "DayCell")
        tableView.delegate = self
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.scrollsToTop = todayAtTop
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
            guard let self, tableView.superview != nil else { return }
            tableView.visibleCells
                .compactMap { $0 as? DayTableViewCell }
                .forEach { $0.reconfigure(with: tracks) }

            headerView.configure(with: tracks)
        }.store(in: &subscriptions)

        // Surface the SwiftUI todayLock alert as a UIAlertController so the
        // new UI can use the existing TrackController plumbing unchanged.
        trackController?.$todayLockAlert
            .compactMap { $0 }
            .sink { [weak self] alert in
                self?.presentTodayLockAlert(alert)
            }
            .store(in: &subscriptions)

        // TODO: REMOVE THIS!!!
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            print("!!!!!!!!!! removing first track")
            self.tracksContainer.tracks.removeFirst()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollToInitialPosition()
    }

    /*
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        guard parent == nil else { return }

        print("!!!!!!!! TrackTableViewController.didMove(toParent:)", index)
        delegate?.isRemoved()
    }
     */

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
        if initialized {
            scrollController.contentOffset = tableView.contentOffset
        }
    }

    //MARK: Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Self.numDays
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

    //MARK: Table View Delegate

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        44
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let day = day(forRow: indexPath.row)
        let baseHeight: CGFloat = 44
        if weekSeparatorSpaces && TrackController.shared.shouldShowSeparatorBelow(day: day) {
            return baseHeight + 8 // Add 8 points of spacing for week separators
        }
        return baseHeight
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        self.headerView
    }

    //MARK: Scroll View Delegate

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // This function gets called on view load with a value of zero,
        // resetting the scroll position every time a new screen loads.
        // This guard prevents that. The end functions below allow it
        // to still sync position when it is 0.
        guard scrollView.contentOffset != .zero,
              !scrollController.isPaging else { return }
        scrollController.contentOffset = scrollView.contentOffset
    }

    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollController.contentOffset = scrollView.contentOffset
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollController.contentOffset = scrollView.contentOffset
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Avoid unnecessary calls to setter as that seems to flash it
        if !tableView.showsVerticalScrollIndicator {
            tableView.showsVerticalScrollIndicator = true
        }
        scrollController.initialized = true
        initialized = true
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollController.contentOffset = scrollView.contentOffset
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

    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        // When today is at the top, let the OS scroll to top for us.
        // Otherwise, scroll to today (which is at the bottom) instead.
        if todayAtTop {
            return true
        }
        scrollToToday(animated: true)
        return false
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
