//
//  DayTableViewCell.swift
//  PageView
//
//  Created by Elaine Lyons on 2/17/22.
//

import UIKit
import Combine

/// Tells the host view controller about a tap on a locked day.
/// Used to drive the SwiftUI `TrackController.didTapLockedDay()` flow that
/// shows an alert after two consecutive taps.
protocol DayTableViewCellDelegate: AnyObject {
    func dayCell(_ cell: DayTableViewCell, didTapLockedDayAt day: Int)

    /// Asks the host to present the count stepper for a multiple-mode track
    /// that already has a count of 1 or more. Anchored to `sourceView` (the
    /// tapped tick button).
    func dayCell(
        _ cell: DayTableViewCell,
        didRequestStepperFor track: Track,
        day: Int,
        from sourceView: UIView
    )
}

class DayTableViewCell: UITableViewCell {

    private var tracks: [Track] = []
    private var day: Int = 0
    private var weekSeparatorLines: Bool = true
    private var weekSeparatorSpaces: Bool = true
    /// Whether tap/long-press should mutate ticks. When `false` (today-lock
    /// engaged on a non-today day) interactions just notify the delegate.
    private var canEdit: Bool = true

    /// Leading inset for the week-separator line: flush with the trailing edge
    /// of the date column (`ViewController.tableViewContainer`, 100pt wide and
    /// opaque, overlaid on the left of the full-width page table). Keeping it
    /// here avoids the line poking out from under the date grid as the page
    /// slides during horizontal paging.
    static let separatorLeadingInset: CGFloat = 100

    /// Leading inset for the normal cell separators: a touch further in than the
    /// week-separator line, so the (thicker) week line reads as slightly wider /
    /// more prominent. Still clears the date column so it doesn't poke out under
    /// the date grid while paging.
    static let normalSeparatorLeadingInset: CGFloat = separatorLeadingInset + 8

    /// Base whitespace opened up between weeks (below the buttons of the row
    /// above each separator) when separator spaces are enabled. Tuned to match
    /// the gap the SwiftUI `TicksView` produces via its invisible spacer +
    /// default `VStack` spacing.
    static let weekSeparatorBaseSpacing: CGFloat = 18
    /// Thickness of the week-separator line.
    static let weekSeparatorLineHeight: CGFloat = 4

    /// Extra height the host adds (via `heightForRowAt`) to the row above each
    /// week separator, which we pull the stack up by here so it becomes visible
    /// space below the buttons. When the line is drawn it adds its own height
    /// to the gap and is centered within it — mirroring `TicksView`, whose
    /// spacer is `lines ? lineHeight : 0`, so weeks sit the same distance apart
    /// whether or not the line is shown. Both `heightForRowAt` implementations
    /// must use this so the date column and page tables stay scroll-synced.
    static func weekSeparatorExtraHeight(lines: Bool) -> CGFloat {
        weekSeparatorBaseSpacing + (lines ? weekSeparatorLineHeight : 0)
    }

    private var stackView = UIStackView()
    /// Top/bottom constraints between `stackView` and the cell's `contentView`.
    /// We squeeze the stack view away from one edge to make room for
    /// week-separator spacing — `heightForRowAt` makes the row
    /// `weekSeparatorExtraHeight` taller for the row above each separator, and
    /// the constant on `stackBottomConstraint` pulls the stack up so the extra
    /// height becomes visible space between weeks instead of vanishing into the
    /// cell.
    private var stackTopConstraint: NSLayoutConstraint!
    private var stackBottomConstraint: NSLayoutConstraint!
    private var separatorLine: UIView?
    private var buttons: [Track: UIButton] = [:]

    weak var delegate: DayTableViewCellDelegate?

    private var subscriptions = Set<AnyCancellable>()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 4
        stackView.autoresizesSubviews = true

        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        stackTopConstraint = stackView.topAnchor.constraint(equalTo: contentView.topAnchor)
        stackBottomConstraint = stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 120),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackTopConstraint,
            stackBottomConstraint,
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    func reconfigure(with tracks: [Track]) {
        self.tracks = tracks
        updateUI()
    }

    func configure(
        with tracks: [Track],
        day: Int,
        lines: Bool = true,
        spaces: Bool = true,
        canEdit: Bool = true,
        delegate: DayTableViewCellDelegate? = nil
    ) {
        self.tracks = tracks
        self.day = day
        self.weekSeparatorLines = lines
        self.weekSeparatorSpaces = spaces
        self.canEdit = canEdit
        if let delegate { self.delegate = delegate }
        updateUI()
    }

    private func updateUI() {
        let day = self.day

        // Remove existing views
        stackView.arrangedSubviews.forEach { view in
            view.removeConstraints(view.constraints)
            view.removeFromSuperview()
        }
        separatorLine?.removeFromSuperview()
        separatorLine = nil

        // Configure week separator spacing. The row's height (set by the host
        // `heightForRowAt`) is `weekSeparatorExtraHeight` taller for the row
        // directly above each separator; here we shrink the stack view by the
        // same amount so that height becomes a visible gap between weeks rather
        // than padding that expands the buttons. Spacing is always added on the
        // bottom edge so the gap sits in display order between this week and
        // the next.
        let needsSeparatorSpace = weekSeparatorSpaces
            && TrackController.shared.shouldShowSeparatorBelow(day: day)
        stackTopConstraint.constant = 0
        stackBottomConstraint.constant = needsSeparatorSpace
            ? -Self.weekSeparatorExtraHeight(lines: weekSeparatorLines)
            : 0

        // Configure week separator line. When separator spacing is present we
        // center the line vertically within the gap (matching SwiftUI, where
        // the line sits midway between the two weeks); otherwise it pins to the
        // row's bottom edge.
        if weekSeparatorLines && TrackController.shared.shouldShowSeparatorBelow(day: day) {
            let line = UIView()
            line.backgroundColor = .gray
            line.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(line)
            // We're inside `weekSeparatorLines`, so the gap includes the line's
            // height; center the line within it. With spaces off there's no
            // gap, so the line pins to the bottom edge.
            let lineBottomInset = needsSeparatorSpace
                ? (Self.weekSeparatorExtraHeight(lines: true) - Self.weekSeparatorLineHeight) / 2
                : 0
            NSLayoutConstraint.activate([
                // Span the same width as the normal cell separators — flush with
                // the date column's trailing edge through to the trailing edge —
                // rather than the narrower button column.
                line.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.separatorLeadingInset),
                line.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -lineBottomInset),
                line.heightAnchor.constraint(equalToConstant: Self.weekSeparatorLineHeight)
            ])
            line.layer.cornerRadius = Self.weekSeparatorLineHeight / 2
            line.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            line.clipsToBounds = true
            separatorLine = line
        }

        subscriptions.forEach { $0.cancel() }
        subscriptions.removeAll()

        tracks.enumerated().forEach { index, track in
            let tickController = TrackController.shared.tickController(for: track)
            let ticks = tickController.ticks(on: day)

            let button = self.button(for: track, tickController: tickController)
            self.configure(button: button, for: track, ticks: ticks)
            button.tag = index
            stackView.addArrangedSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: 34)
            ])

            // Set up publisher to respond to changes
            tickController.$ticks.sink { [weak self] allTicks in
                // We can't use the tickController's ticks(on:) convenience
                // function because it hasn't updated yet as of this sink call
                guard allTicks.indices.contains(day) else { return }
                let ticks = Int(allTicks[day]?.count ?? 0)
                self?.configure(button: button, for: track, ticks: ticks)
            }
            .store(in: &subscriptions)
        }
    }

    private func button(for track: Track, tickController: TickController) -> UIButton {
        if let button = buttons[track] {
            return button
        }

        let button = UIButton(primaryAction: UIAction { [weak tickController, weak track, weak self] action in
            guard let self, let tickController, let track,
                  let button = action.sender as? UIButton else { return }
            // If today-lock is engaged on a previous day, route the tap to the
            // delegate (which will surface the alert via TrackController) and
            // bail out without mutating any ticks.
            guard self.canEdit else {
                self.delegate?.dayCell(self, didTapLockedDayAt: self.day)
                return
            }
            // For a multiple-mode track that already has a count, a tap opens
            // the stepper so the user can adjust up or down. The first tick
            // (0 -> 1) still happens on a plain tap, so adding a single count
            // stays fast and the stepper only appears once there's a count to
            // adjust.
            if track.multiple, tickController.ticks(on: self.day) >= 1 {
                self.delegate?.dayCell(self, didRequestStepperFor: track, day: self.day, from: button)
                return
            }
            UISelectionFeedbackGenerator().selectionChanged()
            tickController.tick(day: self.day)
        })

        buttons[track] = button
        return button
    }

    func configure(button: UIButton, for track: Track, ticks: Int) {
        button.backgroundColor = track.buttonColor(ticks: ticks)
        button.layer.cornerRadius = 4
        button.setTitle(track.buttonText(ticks: ticks), for: .normal)
        button.setTitleColor(track.textColor(), for: .normal)
    }

}
