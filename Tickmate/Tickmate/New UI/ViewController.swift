//
//  ViewController.swift
//  PageView
//
//  Created by Elaine Lyons on 2/10/22.
//

import UIKit
import SwiftUI
import Combine

/// Hosts the new UIKit-based main view inside SwiftUI.
struct NewUI: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        // The storyboard has been replaced with programmatic UIKit setup.
        let root = ViewController()
        let nav = UINavigationController(rootViewController: root)
        return nav
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
}

/// The main "host" view controller. Lays out three layers, mirroring the
/// original storyboard structure:
///   * `pageContainer`       – full-width, embeds the `PageViewController`
///                             (the swipeable group pages). Lowest z-order.
///   * `shadowView`          – 100pt-wide empty colored column behind the date
///                             column, used only to cast a shadow on the right
///                             edge while paging. Middle z-order.
///   * `tableViewContainer`  – 100pt-wide colored column that hosts the date
///                             label `tableView`. Highest z-order so the labels
///                             render in front of the page contents.
class ViewController: UIViewController {

    //MARK: Properties

    /// Full-width container view that hosts the `PageViewController` as a child.
    let pageContainer = UIView()

    /// 100pt-wide empty column that lives behind the date column. Has an opaque
    /// background so its layer can cast a shadow; no subviews.
    let shadowView = UIView()

    /// 100pt-wide column that contains the persistent date label `tableView`.
    /// Sits on top of `shadowView` and renders the dates over the page content.
    let tableViewContainer = UIView()

    /// Date-column table view. Lives inside `tableViewContainer`. Its data
    /// source / delegate are this view controller; it shows the day label
    /// (Today / Yesterday / weekday + date) for each row in sync with whichever
    /// page's track table is currently on screen.
    let tableView = UITableView()

    /// Embedded page view controller.
    private(set) lazy var pageViewController = PageViewController()

    var scrollController: ScrollController = .shared
    private var subscribers = Set<AnyCancellable>()
    private var drop: DispatchWorkItem?
    private var impact: DispatchWorkItem?

    @AppStorage(Defaults.todayAtTop.rawValue, store: UserDefaults(suiteName: groupID))
    private var todayAtTop: Bool = false

    /// Cached value used to detect when `todayAtTop` flips so the sidebar can
    /// be re-scrolled to match the page table's new "rest" edge.
    private var previousTodayAtTop: Bool = false

    /// Height of the per-page header (shown above each track table). Used to mask
    /// the sidebar/shadow off so the per-page header always covers them.
    static let headerHeight: CGFloat = 44

    //MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.title = "Tickmate"
        navigationItem.largeTitleDisplayMode = .never

        setUpNavigationBarButtons()
        setUpHierarchy()
        setUpShadow()
        setUpTableView()
        setUpPageViewController()
        setUpScrollSync()
    }

    private func setUpNavigationBarButtons() {
        // Left: gear → Settings sheet (mirrors SwiftUI ContentView toolbar).
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(presentSettings)
        )

        // Right: text.justify → Tracks sheet.
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "text.justify"),
            style: .plain,
            target: self,
            action: #selector(presentTracks)
        )
    }

    @objc private func presentSettings() {
        let host = UIHostingController(rootView: SettingsSheet(host: self))
        present(host, animated: true)
    }

    @objc private func presentTracks() {
        let host = UIHostingController(rootView: TracksSheet(host: self))
        present(host, animated: true)
    }

    /// Called by the SwiftUI sheets when the user taps Done. We can't bind a
    /// SwiftUI Binding directly to the UIViewController's modal state, so the
    /// sheets call this after flipping their `showing` flag to `false`.
    func dismissPresentedSheet() {
        presentedViewController?.dismiss(animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Recompute the masks now that the view has been sized.
        applyMasks()
    }

    //MARK: Setup

    private func setUpHierarchy() {
        // Mirror the original storyboard's three-layer structure. Add order
        // determines z-order: pageContainer is the back-most layer, shadowView
        // sits on top of it and casts its shadow over the page content,
        // tableViewContainer (with the date labels inside) is the front-most
        // layer so the labels render above everything.
        for v in [pageContainer, shadowView, tableViewContainer] {
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }

        // Both columns need an opaque background:
        //   * shadowView: so its CALayer has opaque content to cast a shadow
        //     from (without this, shadowOpacity has nothing to work with).
        //   * tableViewContainer: so the date labels render against a solid
        //     surface that hides whatever page content is underneath.
        shadowView.backgroundColor = .systemBackground
        tableViewContainer.backgroundColor = .systemBackground
        // Match the storyboard's userInteractionEnabled=NO on both columns so
        // taps fall through to whatever's underneath (the page table).
        shadowView.isUserInteractionEnabled = false
        tableViewContainer.isUserInteractionEnabled = false

        let safe = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // pageContainer fills the safe area horizontally and the full view
            // vertically (so page contents extend below the home indicator).
            pageContainer.topAnchor.constraint(equalTo: safe.topAnchor),
            pageContainer.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            pageContainer.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            pageContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // shadowView: 100pt-wide left column, behind the date column.
            shadowView.topAnchor.constraint(equalTo: safe.topAnchor),
            shadowView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shadowView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            shadowView.widthAnchor.constraint(equalToConstant: 100),

            // tableViewContainer: same geometry as shadowView, in front of it.
            tableViewContainer.topAnchor.constraint(equalTo: safe.topAnchor),
            tableViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableViewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableViewContainer.widthAnchor.constraint(equalToConstant: 100),
        ])

        // Add the date-column table view inside tableViewContainer.
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemBackground
        tableView.isUserInteractionEnabled = false
        tableView.alwaysBounceVertical = true
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.clipsToBounds = true
        tableViewContainer.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: tableViewContainer.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: tableViewContainer.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: tableViewContainer.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: tableViewContainer.bottomAnchor),
        ])
    }

    private func setUpShadow() {
        // Set up shadow geometry; opacity is animated based on `isPaging`.
        shadowView.layer.shadowRadius = 4
        shadowView.layer.shadowOpacity = 0
        shadowView.layer.shadowOffset = .zero
        shadowView.clipsToBounds = false
    }

    private func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DateLabelCell.self, forCellReuseIdentifier: DateLabelCell.reuseID)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }

    private func setUpPageViewController() {
        // Embed the page view controller as a child of the full-width
        // pageContainer (the back-most layer).
        addChild(pageViewController)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        // UIPageViewController.view defaults to a clear background; if any
        // ancestor were ever transparent, the system window would show
        // through. Lock it to systemBackground so what's behind never leaks.
        pageViewController.view.backgroundColor = .systemBackground
        pageContainer.addSubview(pageViewController.view)
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: pageContainer.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: pageContainer.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: pageContainer.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: pageContainer.bottomAnchor),
        ])
        pageViewController.didMove(toParent: self)
    }

    private func setUpScrollSync() {
        previousTodayAtTop = todayAtTop

        // Sync scroll position
        scrollController.$contentOffset.sink { [weak self] contentOffset in
            self?.tableView.contentOffset = contentOffset
        }
        .store(in: &subscribers)

        // Reload the date column whenever a relevant user default changes.
        // SwiftUI views with @AppStorage refresh automatically; UIViewControllers
        // don't, so we listen for the global UserDefaults.didChangeNotification.
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.applySettingsChange()
            }
            .store(in: &subscribers)

        scrollController.$isPaging.sink { [weak self] isPaging in
            guard let self = self else { return }
            if isPaging {
                self.drop?.cancel()
                self.impact?.cancel()
                UIView.animate(withDuration: 0.25) {
                    self.shadowView.layer.shadowOpacity = 0.5
                }
            } else {
                self.endPaging()
            }
        }
        .store(in: &subscribers)
    }

    private func applyMasks() {
        // Two masks, one per left-side column, both clipping out the top
        // `headerHeight` so the per-page header appears to cover the sidebar:
        //
        //   * The date column (`tableViewContainer`) gets a narrow mask the
        //     width of the column itself. This hides the date labels above
        //     y = headerHeight without affecting anything else.
        //   * The shadow column (`shadowView`) gets a wider mask (extending
        //     well past the trailing edge of the column) so the cast shadow
        //     can spill onto the page content to the right without being
        //     clipped along with the column itself.
        let bounds = view.bounds

        let sidebarMask = CALayer()
        sidebarMask.backgroundColor = UIColor.black.cgColor
        sidebarMask.frame = CGRect(
            x: 0,
            y: Self.headerHeight,
            width: tableViewContainer.bounds.width,
            height: bounds.height * 2
        )
        tableViewContainer.layer.mask = sidebarMask

        let shadowMask = CALayer()
        shadowMask.backgroundColor = UIColor.black.cgColor
        shadowMask.frame = CGRect(
            x: 0,
            y: Self.headerHeight,
            width: bounds.width * 2,
            height: bounds.height * 2
        )
        shadowView.layer.mask = shadowMask
    }

    //MARK: Settings

    /// Mirrors the per-page handler: rebuild the date-column rows whenever any
    /// UserDefaults value flips. If `todayAtTop` flipped, also snap the column
    /// to the matching edge so it stays in sync with the page tables.
    private func applySettingsChange() {
        let directionFlipped = todayAtTop != previousTodayAtTop
        previousTodayAtTop = todayAtTop

        tableView.reloadData()

        if directionFlipped {
            let row = todayAtTop ? 0 : TrackTableViewController.numDays - 1
            let position: UITableView.ScrollPosition = todayAtTop ? .top : .bottom
            // The page tables also re-scroll on this notification and publish
            // their new offset back to ScrollController; that publish would
            // immediately overwrite ours. Doing the scroll synchronously here
            // gives the user something correct to look at during the brief
            // window between our reload and the publisher's next runloop tick.
            tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: position, animated: false)
        }
    }

    //MARK: Private

    private func endPaging() {
        let drop = DispatchWorkItem { [weak self] in
            UIView.animate(withDuration: 0.25) {
                self?.shadowView.layer.shadowOpacity = 0
            }
        }
        self.drop = drop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.125, execute: drop)

        let impact = DispatchWorkItem {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
        self.impact = impact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: impact)
    }

}

//MARK: Table View Data Source

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        TrackTableViewController.numDays
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        " "
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DateLabelCell.reuseID, for: indexPath)
        let day = todayAtTop ? indexPath.row : TrackTableViewController.numDays - indexPath.row - 1
        if let dateCell = cell as? DateLabelCell {
            let label = TrackController.shared.dayLabel(day: day, compact: false)
            dateCell.configure(text: label.text, caption: label.caption)
        }
        return cell
    }
}

//MARK: Date Label Cell

/// Cell used in the persistent left-hand date column. Shows the day's
/// weekday/relative label (e.g. "Today" / "Mon") with the short date as a
/// caption beneath it (e.g. "5/2/26").
final class DateLabelCell: UITableViewCell {

    static let reuseID = "DateLabelCell"

    private let textStack = UIStackView()
    private let titleLabel = UILabel()
    private let captionLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

        captionLabel.font = .preferredFont(forTextStyle: .caption1)
        captionLabel.textColor = .secondaryLabel
        captionLabel.numberOfLines = 1
        captionLabel.lineBreakMode = .byTruncatingTail

        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.distribution = .fill
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(captionLabel)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -4),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(text: String, caption: String?) {
        titleLabel.text = text
        if let caption, !caption.isEmpty {
            captionLabel.text = caption
            captionLabel.isHidden = false
        } else {
            captionLabel.text = nil
            captionLabel.isHidden = true
        }
    }
}

//MARK: - SwiftUI sheet wrappers

/// SwiftUI wrapper for the Settings sheet. Set up so the same code path works
/// for the new-UI host (ViewController) as for the old SwiftUI ContentView.
private struct SettingsSheet: View {
    weak var host: ViewController?
    @State private var showing = true
    // SettingsView expects these via .environmentObject from ContentView. We
    // build them locally here so the sheet works when presented from UIKit.
    @StateObject private var trackController = TrackController.shared
    @StateObject private var storeController = StoreController()

    var body: some View {
        NavigationView {
            SettingsView(showing: $showing)
        }
        .environmentObject(trackController)
        .environmentObject(storeController)
        .onChange(of: showing) { newValue in
            if !newValue { host?.dismissPresentedSheet() }
        }
    }
}

/// SwiftUI wrapper for the Tracks sheet.
private struct TracksSheet: View {
    weak var host: ViewController?
    @Environment(\.managedObjectContext) private var moc
    @State private var showing = true
    @StateObject private var trackController = TrackController.shared
    @StateObject private var groupController = GroupController.shared
    @StateObject private var vcContainer = ViewControllerContainer()

    var body: some View {
        NavigationView {
            TracksView(showing: $showing)
        }
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(trackController)
        .environmentObject(groupController)
        .environmentObject(vcContainer)
        .onChange(of: showing) { newValue in
            if !newValue { host?.dismissPresentedSheet() }
        }
    }
}

//MARK: Table View Delegate

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        Self.headerHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let day = todayAtTop ? indexPath.row : TrackTableViewController.numDays - indexPath.row - 1
        let baseHeight: CGFloat = 44
        if TrackController.shared.shouldShowSeparatorBelow(day: day) {
            return baseHeight + 8 // Add 8 points of spacing for week separators
        }
        return baseHeight
    }
}
