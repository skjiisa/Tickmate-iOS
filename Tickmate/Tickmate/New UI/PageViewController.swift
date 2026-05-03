//
//  PageViewController.swift
//  PageView
//
//  Created by Elaine Lyons on 2/10/22.
//

import SwiftUI
import Combine
import CoreData

class PageViewController: UIPageViewController {

    //MARK: Init

    /// Programmatic initializer (replaces the storyboard instantiation).
    init() {
        super.init(transitionStyle: .scroll,
                   navigationOrientation: .horizontal,
                   options: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: Properties
    
    var scrollPosition: CGPoint = .zero
    var scrollController: ScrollController = .shared
    var trackController: TrackController = .shared
    var groupController: GroupController = .shared
    
    private var groupsUnlocked: Bool {
        UserDefaults.standard.groupsUnlocked
    }
    
    // All Tracks
    private var showingAllTracks: Bool {
        UserDefaults.standard.showAllTracks || groups.count == 0 || !groupsUnlocked
    }
    private var allTracksPage: [Page] {
        showingAllTracks ? [Page.allTracks] : []
    }
    
    // Ungrouped Tracks
    private var showingUngroupedTracks: Bool {
        UserDefaults.standard.showUngroupedTracks && ungroupedTracksFRC.fetchedObjects?.count ?? 0 > 0 && groupsUnlocked
    }
    private var ungroupedTracksPage: [Page] {
        showingUngroupedTracks ? [Page.ungrouped] : []
    }
    
    // Groups
    private var groups: [TrackGroup] {
        groupsUnlocked ? groupController.fetchedResultsController.fetchedObjects ?? [] : []
    }
    private var groupsPages: [Page] {
        groups.map { .group($0) }
    }
    
    // Page

    /// The currently displayed page index. Persisted to UserDefaults under
    /// `Defaults.groupPage` so the app launches back into the same group as
    /// the user was last viewing — mirrors the SwiftUI ContentView behavior.
    private var page: Int {
        get { UserDefaults.standard.integer(forKey: Defaults.groupPage.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: Defaults.groupPage.rawValue) }
    }
    private var pages: [Page] = []
    
    // Refreshing
    private var subscriptions = Set<AnyCancellable>()
    
    //MARK: FetchedResultsController
    
    lazy private var ungroupedTracksFRC: NSFetchedResultsController<Track> = {
        let context = PersistenceController.shared.container.viewContext

        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.sortDescriptors = TrackController.sortDescriptors
        // Match SwiftUI TicksView: enabled, not archived, no groups.
        fetchRequest.predicate = NSPredicate(format: "enabled == YES AND isArchived == NO AND groups.@count == 0")
        
        let frc = NSFetchedResultsController<Track>(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        frc.delegate = self
        
        do {
            try frc.performFetch()
        } catch {
            NSLog("Error performing Tracks fetch: \(error)")
        }
        
        return frc
    }()
    
    //MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self

        reloadPages()

        // Refresh the page list whenever any input that determines it changes.
        // The previous version of this controller deferred refreshing to the
        // next viewWillAppear via a `shouldReloadPages` flag, but viewWillAppear
        // doesn't fire when a presented modal sheet (Settings / Tracks) is
        // dismissed — so toggling "Show All Tracks" or adding a group never
        // actually updated the pages until the user re-opened the whole tab.

        // 1. Settings flips (showAllTracks / showUngroupedTracks / groupsUnlocked).
        let keyPaths: [KeyPath<UserDefaults, Bool>] = [\.showAllTracks, \.showUngroupedTracks, \.groupsUnlocked]
        keyPaths.forEach { keyPath in
            UserDefaults.standard
                .publisher(for: keyPath)
                .dropFirst()
                .sink { [weak self] _ in
                    self?.refreshPagesIfNeeded()
                }
                .store(in: &subscriptions)
        }

        // 2. Group add / remove / rename. GroupController fires its
        //    objectWillChange in NSFetchedResultsController.controllerWillChangeContent,
        //    so the FRC's fetchedObjects haven't actually been updated yet at
        //    this point — defer one runloop tick to read the current set.
        groupController.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.refreshPagesIfNeeded() }
            }
            .store(in: &subscriptions)

        // 3. Ungrouped track count crossing 0 ↔ >0 is handled by the
        //    NSFetchedResultsControllerDelegate impl below (the page VC owns
        //    ungroupedTracksFRC for exactly this purpose).

        // Find the underlying horizontal UIScrollView so we can publish paging
        // state via ScrollController for the sidebar shadow animation.
        _ = view.subviews.first { (view: UIView) -> Bool in
            if let scrollView = view as? UIScrollView,
               !(scrollView is UITableView) {
                scrollView.delegate = self
                return true
            }
            return false
        }
    }
    
    //MARK: Private

    /// Initial page setup. Always rebuilds the list and shows the persisted
    /// page index. Use `refreshPagesIfNeeded()` for subsequent updates.
    private func reloadPages() {
        pages = allTracksPage + ungroupedTracksPage + groupsPages

        // Defensive: SwiftUI ContentView does the same. If the persisted page
        // index ever falls outside the current page list (e.g. groups were
        // removed since launch), snap it back to 0 so we don't dead-end on
        // a non-existent page.
        if page < 0 || page >= pages.count {
            page = 0
        }

        if let initialVC = trackVC(for: page) {
            setViewControllers([initialVC], direction: .forward, animated: false)
        }
    }

    /// Recomputes the page list and rebuilds the visible page only when the
    /// list has actually changed — same number of pages in the same order
    /// with the same identities short-circuits early.
    ///
    /// Tries to preserve the user's current page across the rebuild: if the
    /// page they were on still exists (same group, or the same special
    /// allTracks/ungrouped slot), they stay on it even if other pages were
    /// inserted before / removed after it.
    private func refreshPagesIfNeeded() {
        let newPages = allTracksPage + ungroupedTracksPage + groupsPages
        guard !pageLists(newPages, equalTo: pages) else { return }

        let currentPage = pages.indices.contains(page) ? pages[page] : nil
        pages = newPages

        if let currentPage,
           let preservedIndex = pages.firstIndex(where: { samePage($0, currentPage) }) {
            page = preservedIndex
        } else if page < 0 || page >= pages.count {
            page = 0
        }

        if let initialVC = trackVC(for: page) {
            setViewControllers([initialVC], direction: .forward, animated: false)
        }
    }

    private func pageLists(_ a: [Page], equalTo b: [Page]) -> Bool {
        guard a.count == b.count else { return false }
        return zip(a, b).allSatisfy(samePage)
    }

    private func samePage(_ a: Page, _ b: Page) -> Bool {
        switch (a, b) {
        case (.allTracks, .allTracks), (.ungrouped, .ungrouped):
            return true
        case (.group(let g1), .group(let g2)):
            return g1.objectID == g2.objectID
        default:
            return false
        }
    }

    /// Build a TrackTableViewController for the page at `index`, configured
    /// with the right Core Data predicate so it can manage its own FRC and
    /// react to track add / remove / rename / reorder live.
    private func trackVC(for index: Int) -> TrackTableViewController? {
        guard pages.indices.contains(index) else { return nil }
        let trackVC = TrackTableViewController()
        trackVC.index = index

        // All three cases share the same "enabled and not archived" base
        // predicate (matches SwiftUI TicksView.standardPredicate). The All
        // Tracks page no longer reuses TrackController's FRC because that
        // one only filters isArchived — `enabled == NO` tracks would have
        // shown there but not in the SwiftUI version.
        let predicate: NSPredicate
        switch pages[index] {
        case .allTracks:
            predicate = NSPredicate(format: "enabled == YES AND isArchived == NO")
        case .ungrouped:
            predicate = NSPredicate(format: "enabled == YES AND isArchived == NO AND groups.@count == 0")
        case .group(let group):
            predicate = NSPredicate(format: "enabled == YES AND isArchived == NO AND %@ IN groups", group)
        }
        trackVC.load(predicate: predicate)
        return trackVC
    }
    
    private func index(of viewController: UIViewController) -> Int? {
        (viewController as? TrackTableViewController)?.index
    }
    
    //MARK: Page
    
    enum Page {
        case allTracks
        case ungrouped
        case group(TrackGroup)
    }

}

//MARK: - Page View Controller Data Source

extension PageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        trackVC(for: (index(of: viewController) ?? page) - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        trackVC(for: (index(of: viewController) ?? page) + 1)
    }
}

//MARK: - Page View Controller Delegate

extension PageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        // Only persist when the swipe actually went through. If the user
        // started a swipe and then dragged it back, completed will be false
        // and we should keep the existing index.
        guard completed,
              let trackVC = pageViewController.viewControllers?.first as? TrackTableViewController
        else { return }
        page = trackVC.index
    }
}

//MARK: - Scroll View Delegate

extension PageViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollController.isPaging = true
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // if statement to avoid unnecessary publish events
        if !decelerate {
            scrollController.isPaging = false
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollController.isPaging = false
    }
}

//MARK: - Fetched Results Controller Delegate

extension PageViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // ungroupedTracksFRC is the only FRC the page VC owns. When its
        // fetched count crosses 0 ↔ >0 the "Ungrouped" page should appear or
        // disappear; refreshPagesIfNeeded compares signatures so non-meaningful
        // changes (a track moving between groups while still ungrouped, etc.)
        // are no-ops.
        refreshPagesIfNeeded()
    }
}
