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

/// The main "host" view controller. Lays out:
///   * `tableViewContainer`  – embeds the `PageViewController` (the swipable group pages)
///   * `shadowView`          – the left "sidebar" that drops a shadow on the right edge
///                             while paging, giving the new design its distinctive look.
///   * `tableView`           – a 100pt-wide "ghost" table that displays date labels and
///                             stays in sync with whichever page's table is on screen.
class ViewController: UIViewController {

    //MARK: Properties

    /// 100pt-wide column on the left of the screen that contains the persistent date
    /// labels and casts the sidebar shadow over the page contents while paging.
    let shadowView = UIView()

    /// Container view that hosts the `PageViewController` as a child.
    let tableViewContainer = UIView()

    /// The "ghost" date-column table view rendered inside the shadow column.
    /// Its data source / delegate are this view controller; it shows the day label
    /// for each row (Today / Yesterday / weekday + date).
    let tableView = UITableView()

    /// Embedded page view controller.
    private(set) lazy var pageViewController = PageViewController()

    var scrollController: ScrollController = .shared
    private var subscribers = Set<AnyCancellable>()
    private var drop: DispatchWorkItem?
    private var impact: DispatchWorkItem?

    /// Height of the per-page header (shown above each track table). Used to mask
    /// the sidebar/shadow off so the per-page header always covers them.
    static let headerHeight: CGFloat = 44

    //MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.title = "Tickmate"
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: nil,
            action: nil
        )

        setUpHierarchy()
        setUpShadow()
        setUpTableView()
        setUpPageViewController()
        setUpScrollSync()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Recompute the masks now that the view has been sized.
        applyMasks()
    }

    //MARK: Setup

    private func setUpHierarchy() {
        // Use Auto Layout for everything; matches the storyboard frames.
        for v in [tableViewContainer, shadowView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }

        let safe = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // tableViewContainer fills the safe area horizontally and vertically;
            // page contents render full-width but are visually inset by the shadow.
            tableViewContainer.topAnchor.constraint(equalTo: safe.topAnchor),
            tableViewContainer.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            tableViewContainer.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            tableViewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // shadowView is the 100pt-wide left column.
            shadowView.topAnchor.constraint(equalTo: safe.topAnchor),
            shadowView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shadowView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            shadowView.widthAnchor.constraint(equalToConstant: 100),
        ])

        // Add the date-column table view inside the shadow column.
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemBackground
        tableView.isUserInteractionEnabled = false
        tableView.alwaysBounceVertical = true
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.clipsToBounds = true
        shadowView.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: shadowView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor),
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
        // Embed the page view controller as a child.
        addChild(pageViewController)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        tableViewContainer.addSubview(pageViewController.view)
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: tableViewContainer.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: tableViewContainer.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: tableViewContainer.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: tableViewContainer.bottomAnchor),
        ])
        pageViewController.didMove(toParent: self)
    }

    private func setUpScrollSync() {
        // Sync scroll position
        scrollController.$contentOffset.sink { [weak self] contentOffset in
            self?.tableView.contentOffset = contentOffset
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
        // These two masks recreate the storyboard's layered effect:
        //   * The sidebar is hidden behind the per-page header (top 44pt) so the
        //     header appears to "cover" the sidebar.
        //   * The shadow is masked similarly, but extended past the trailing edge
        //     so the shadow falls on the page content to the right.
        let bounds = view.bounds

        let sidebarMask = CALayer()
        sidebarMask.backgroundColor = UIColor.black.cgColor
        sidebarMask.frame = CGRect(
            x: 0,
            y: Self.headerHeight,
            width: shadowView.bounds.width,
            height: bounds.height * 2
        )
        // Apply to the shadowView's contents (so the labels are clipped) but not
        // to the shadow layer itself, otherwise the shadow disappears too. We do
        // that by giving the date-column tableView its own clipped frame.
        tableView.layer.mask = sidebarMask

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
        365 // TickController.numDays
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        " "
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DateLabelCell.reuseID, for: indexPath)
        let day = /*TickController.numDays*/ 365 - indexPath.row - 1
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

//MARK: Table View Delegate

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        Self.headerHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let day = 365 - indexPath.row - 1
        let baseHeight: CGFloat = 44
        let insets = TrackController.shared.insets(day: day)
        if insets != nil {
            return baseHeight + 8 // Add 8 points of spacing for week separators
        }
        return baseHeight
    }
}
