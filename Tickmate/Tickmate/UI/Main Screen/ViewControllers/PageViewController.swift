//
//  PageViewController.swift
//  PageView
//
//  Created by Elaine Lyons on 2/10/22.
//

import SwiftUI
import Combine

class PageViewController: UIPageViewController {
    
    //MARK: Properties
    
    var scrollPosition: CGPoint = .zero
    var scrollController: ScrollController = .shared
    var trackController: TrackController = .shared
    var groupController: GroupController = .shared
    
    private var allTracksPage: [Page] {
        // Update logic to force it if groups not unlocked
        UserDefaults.standard.showAllTracks ? [Page.allTracks] : []
    }
    private var ungroupedTracksPage: [Page] {
        UserDefaults.standard.showUngroupedTracks ? [Page.ungrouped] : []
    }
    private var groups: [TrackGroup] {
        UserDefaults.standard.groupsUnlocked ? groupController.fetchedResultsController.fetchedObjects ?? [] : []
    }
    private var groupsPages: [Page] {
        groups.map { .group($0) }
    }
    
    private var page: Int = 0
    private var pages: [Page] = []
    
    private var subscriptions = Set<AnyCancellable>()
    private var shouldReloadPages = false
    
    
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
        print("!!!!!!! Reloading pages")
        pages = allTracksPage + ungroupedTracksPage + groupsPages
        
        if let initialVC = trackVC(for: page) {
            setViewControllers([initialVC], direction: .forward, animated: true)
        }
    }
    
    private func trackVC(for index: Int) -> TrackTableViewController? {
        guard pages.indices.contains(index),
              let trackVC = storyboard?.instantiateViewController(withIdentifier: "TrackTable") as? TrackTableViewController
        else { return nil }
        
        let page = pages[index]
        
        trackVC.index = index
        
        switch page {
        case .allTracks:
            let tracks = trackController.fetchedResultsController.fetchedObjects ?? []
            trackVC.load(tracks: tracks)
        case .ungrouped:
            // TODO: Update
            let tracks = trackController.fetchedResultsController.fetchedObjects?.prefix(4)
            trackVC.load(tracks: Array(tracks ?? []))
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

//MARK: Page View Controller Data Source

extension PageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        trackVC(for: (index(of: viewController) ?? page) - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        trackVC(for: (index(of: viewController) ?? page) + 1)
    }
}

//MARK: Page View Controller Delegate

extension PageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let trackVC = previousViewControllers.first as? TrackTableViewController else { return }
        page = trackVC.index
    }
}

//MARK: Scroll View Delegate

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
