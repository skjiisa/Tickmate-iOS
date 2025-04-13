//
//  TrackTableViewController.swift
//  PageView
//
//  Created by Elaine Lyons on 2/10/22.
//

import SwiftUI
import Combine
import CoreData

class TrackTableViewController: UITableViewController {
    
    //MARK: Properties
    
    var index = 0
    var scrollController: ScrollController = .shared
    
    private let tracksContainer = TracksContainer()
    
    var group: TrackGroup? {
        didSet {
            guard let group else { return }
            //TODO: Create FRC
            let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Track.index, ascending: true)]
            fetchRequest.predicate = NSPredicate(format: "enabled == YES AND %@ IN groups", group)
            
            if let tracks = try? PersistenceController.shared.container.viewContext.fetch(fetchRequest) {
                load(tracks: tracks)
            }
        }
    }
    
    private var initialized = false
    private var subscriptions: Set<AnyCancellable> = []
    private let headerView = TracksHeaderView()
    
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
        scrollToDelegate()
        
        scrollController.$isPaging.sink { [weak self] isPaging in
            guard let self = self else { return }
            
            if isPaging {
                self.tableView.showsVerticalScrollIndicator = false
            } else {
                // We only want to flash the scroll bar if the table is scrolled above the bottom.
                //TODO: Test this on a square screen with no Safe Area
                // Could even potentially add a bit more tolerance to this
                // so it doesn't flash them when only scrolled up a bit.
                //Note: If there's an added option to flip so today is at the top, make sure to adjust this
                let position = self.tableView.contentSize.height - self.tableView.bounds.size.height + self.tableView.contentInset.bottom
                if self.tableView.contentOffset.y < position {
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
        
        // TODO: REMOVE THIS!!!
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            print("!!!!!!!!!! removing first track")
            self.tracksContainer.tracks.removeFirst()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollToDelegate()
    }
    
    /*
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        guard parent == nil else { return }
        
        print("!!!!!!!! TrackTableViewController.didMove(toParent:)", index)
        delegate?.isRemoved()
    }
     */
    
    //MARK: Private
    
    private func scrollToDelegate() {
        guard !tableView.isDragging, !tableView.isDecelerating else { return }
        
        guard scrollController.initialized else {
            return scrollToBottom()
        }
        
        let scrollPosition = scrollController.contentOffset
        print(scrollPosition, "scrollToDelegate")
        self.tableView.contentOffset = scrollPosition
    }
    
    private func scrollToBottom(animated: Bool = false) {
        let indexPath = IndexPath(row: /*TickController.numDays*/365-1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
        if initialized {
            scrollController.contentOffset = tableView.contentOffset
            print(scrollController.contentOffset, "scrollToBottom")
        }
    }

    //MARK: Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        365 //TickController.numDays
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DayCell", for: indexPath)
        
//        let trackController = TrackController.shared
//        cell.contentConfiguration = UIHostingConfiguration {
//            DayRowProxy(tracksContainer: tracksContainer, day: /*TickController.numDays*/ 365 - indexPath.row - 1, spaces: false, lines: false, showDate: false)
//                .environmentObject(trackController)
//        }
        if let dayCell = cell as? DayTableViewCell {
            dayCell.configure(with: tracksContainer.tracks, day: 365 - indexPath.row - 1)
        }

        scrollToDelegate()
        return cell
    }
    
    //MARK: Table View Delegate
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        44
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
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
//        print(scrollView.contentOffset, "scrollViewDidScroll")
    }
    
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollController.contentOffset = scrollView.contentOffset
        print(scrollView.contentOffset, "scrollViewDidEndScrollingAnimation")
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollController.contentOffset = scrollView.contentOffset
        print(scrollView.contentOffset,
              "scrollViewDidEndDecelerating",
              "contentSize.height - bounds.size.height + contentInset.bottom",
              scrollView.contentSize.height - scrollView.bounds.size.height + scrollView.contentInset.bottom)
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        print("scrollViewWillBeginDragging")
        // Avoid unnecessary calls to setter as that seems to flash it
        if !tableView.showsVerticalScrollIndicator {
            tableView.showsVerticalScrollIndicator = true
        }
        scrollController.initialized = true
        initialized = true
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollController.contentOffset = scrollView.contentOffset
        print(scrollView.contentOffset, "scrollViewDidEndDragging")
    }
    
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        print("scroll to top")
        // Scroll to bottom instead
        scrollToBottom(animated: true)
        return false
    }

}
