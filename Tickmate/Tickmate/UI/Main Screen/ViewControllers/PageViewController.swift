//
//  PageViewController.swift
//  PageView
//
//  Created by Elaine Lyons on 2/10/22.
//

import SwiftUI

class PageViewController: UIPageViewController {
    
    //MARK: Properties
    
    var scrollPosition: CGPoint = .zero
    var scrollController: ScrollController = .shared
    var trackController: TrackController = .shared
    var groupController: GroupController = .shared
    private var page: Int = 0

    private var showAllTracks = false
    private var showUngroupedTracks = true
    private var groupsUnlocked = true
    
    private var pages = [Page]()
    
    //MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self
        
        //TODO: Make this respond to publishers and/or FRC delegate
        let groups = groupsUnlocked ? groupController.fetchedResultsController.fetchedObjects ?? [] : []
        
        let allTracks = showAllTracks ? [Page.allTracks] : []
        let ungroupedTracks = showUngroupedTracks ? [Page.ungrouped] : []
        
        pages = allTracks + ungroupedTracks + groups.map { .group($0) }
        
        if let initialVC = trackVC(for: page) {
            setViewControllers([initialVC], direction: .forward, animated: true)
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
    }
    
    //MARK: Private
    
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
