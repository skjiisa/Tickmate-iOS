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
    private var shouldReloadPages = false
    
    //MARK: FetchedResultsController
    
    lazy private var ungroupedTracksFRC: NSFetchedResultsController<Track> = {
        let context = PersistenceController.shared.container.viewContext
        
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Track.index, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "enabled == YES AND groups.@count == 0")
        
        let frc = NSFetchedResultsController<Track>(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        frc.delegate = self
        
        do {
            try frc.performFetch()
            print("PageViewController FRC fetched.")
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
        
        // UserDefaults.standard.showAllTracks = true // for testing settings changes
        reloadPages()
        
        let keyPaths: [KeyPath<UserDefaults, Bool>] = [\.showAllTracks, \.showUngroupedTracks, \.groupsUnlocked]
        keyPaths.forEach { keyPath in
            UserDefaults.standard
                .publisher(for: keyPath)
                .dropFirst()
                .sink { [weak self] _ in
                    self?.shouldReloadPages = true
                }
                .store(in: &subscriptions)
        }
        
        _ = view.subviews.first { (view: UIView) -> Bool in
            if let scrollView = view as? UIScrollView,
               !(scrollView is UITableView) {
                print(scrollView)
                scrollView.delegate = self
                return true
            }
            return false
        }
        
        /* For testing settings changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            print("!!!!!!!!!! hiding 'all tracks' page")
            UserDefaults.standard.showAllTracks = false
            
            self.viewWillAppear(true)
        }
        */
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldReloadPages {
            reloadPages()
        }
    }
    
    //MARK: Private
    
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
            setViewControllers([initialVC], direction: .forward, animated: true)
        }
    }
    
    private func trackVC(for index: Int) -> TrackTableViewController? {
        guard pages.indices.contains(index) else { return nil }
        let trackVC = TrackTableViewController()

        let page = pages[index]
        
        trackVC.index = index
        
        switch page {
        case .allTracks:
            let tracks = trackController.fetchedResultsController.fetchedObjects ?? []
            trackVC.load(tracks: tracks)
        case .ungrouped:
            let tracks = ungroupedTracksFRC.fetchedObjects ?? []
            trackVC.load(tracks: tracks)
        case .group(let group):
            trackVC.group = group
        }
        
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
    // TODO: Check if number of ungrouped tracks changes to or from 0
}
