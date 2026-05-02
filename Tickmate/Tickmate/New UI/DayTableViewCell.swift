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
}

class DayTableViewCell: UITableViewCell {

    private var tracks: [Track] = []
    private var day: Int = 0
    private var weekSeparatorLines: Bool = true
    private var weekSeparatorSpaces: Bool = true
    /// Whether tap/long-press should mutate ticks. When `false` (today-lock
    /// engaged on a non-today day) interactions just notify the delegate.
    private var canEdit: Bool = true

    private var stackView = UIStackView()
    private var separatorLine: UIView?
    private var buttons: [Track: UIButton] = [:]

    /// Maps each tick button to its long-press recognizer (so we can rebuild
    /// recognizer state cleanly when the cell is reconfigured).
    private var longPressRecognizers: [UIButton: UILongPressGestureRecognizer] = [:]
    /// Set of buttons that are currently scaled up because the user is
    /// holding them down. Used to revert the scale on cancel/end.
    private var pressedButtons: Set<UIButton> = []

    weak var delegate: DayTableViewCellDelegate?

    private var subscriptions = Set<AnyCancellable>()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 4
        stackView.autoresizesSubviews = true

        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 120),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
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

        // Configure week separator spacing
        if weekSeparatorSpaces {
            let insets = TrackController.shared.insets(day: day)
            if insets == .top {
                contentView.layoutMargins.top = 8
            } else if insets == .bottom {
                contentView.layoutMargins.bottom = 8
            } else {
                contentView.layoutMargins.top = 0
                contentView.layoutMargins.bottom = 0
            }
        } else {
            contentView.layoutMargins = .zero
        }

        // Configure week separator line
        if weekSeparatorLines && TrackController.shared.shouldShowSeparatorBelow(day: day) {
            let line = UIView()
            line.backgroundColor = .gray
            line.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(line)
            NSLayoutConstraint.activate([
                line.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 120),
                line.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                line.heightAnchor.constraint(equalToConstant: 4)
            ])
            line.layer.cornerRadius = 2
            line.clipsToBounds = true
            separatorLine = line
        }

        subscriptions.forEach { $0.cancel() }
        subscriptions.removeAll()

        // Reset any leftover scaling from the previous configuration.
        pressedButtons.forEach { $0.transform = .identity }
        pressedButtons.removeAll()

        tracks.enumerated().forEach { index, track in
            let tickController = TrackController.shared.tickController(for: track)
            let ticks = tickController.ticks(on: day)

            let button = self.button(for: track, tickController: tickController)
            self.configure(button: button, for: track, ticks: ticks)
            button.tag = index
            stackView.addArrangedSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                // -12 matches the old SwiftUI implementation
                button.heightAnchor.constraint(equalTo: stackView.heightAnchor, constant: -10)
            ])

            // Make sure the long-press recognizer is hooked up. Only attach
            // one for tracks that allow multiple ticks per day.
            configureLongPress(for: button, track: track, tickController: tickController)

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

        let button = UIButton(primaryAction: UIAction { [weak tickController, weak self] _ in
            guard let self, let tickController else { return }
            // If today-lock is engaged on a previous day, route the tap to the
            // delegate (which will surface the alert via TrackController) and
            // bail out without mutating any ticks.
            guard self.canEdit else {
                self.delegate?.dayCell(self, didTapLockedDayAt: self.day)
                return
            }
            UISelectionFeedbackGenerator().selectionChanged()
            tickController.tick(day: self.day)
        })

        buttons[track] = button
        return button
    }

    private func configureLongPress(for button: UIButton, track: Track, tickController: TickController) {
        // Tear down any old recognizer so we never have stale state when a
        // cell is reused with a different track / canEdit value.
        if let existing = longPressRecognizers.removeValue(forKey: button) {
            button.removeGestureRecognizer(existing)
        }

        // Only attach a recognizer to "multiple"-mode tracks; single-tick
        // tracks already untick on a normal tap, so a long press would be
        // redundant (and would cause a double mutation).
        guard track.multiple else { return }

        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        recognizer.minimumPressDuration = 0.5
        // Don't cancel the underlying touch — we still want the button to
        // appear pressed while the user holds it.
        recognizer.cancelsTouchesInView = false
        button.addGestureRecognizer(recognizer)
        longPressRecognizers[button] = recognizer
    }

    @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard let button = recognizer.view as? UIButton,
              let track = buttons.first(where: { $0.value === button })?.key else { return }
        let tickController = TrackController.shared.tickController(for: track)

        switch recognizer.state {
        case .began:
            // Mirror the SwiftUI scale-up animation while the user is holding.
            UIView.animate(withDuration: 0.6,
                           delay: 0,
                           options: [.beginFromCurrentState, .curveEaseInOut]) {
                button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }
            pressedButtons.insert(button)
        case .ended:
            // Animate the scale back down regardless of whether we end up
            // unticking. (If we don't untick — e.g. canEdit is false — the
            // animation is the only feedback the user gets.)
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           options: [.beginFromCurrentState, .curveEaseInOut]) {
                button.transform = .identity
            }
            pressedButtons.remove(button)

            guard canEdit else {
                delegate?.dayCell(self, didTapLockedDayAt: day)
                return
            }
            // `untick(day:)` returns false if there's no tick to remove,
            // in which case skip the haptic.
            if tickController.untick(day: day) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        case .cancelled, .failed:
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           options: [.beginFromCurrentState, .curveEaseInOut]) {
                button.transform = .identity
            }
            pressedButtons.remove(button)
        default:
            break
        }
    }

    func configure(button: UIButton, for track: Track, ticks: Int) {
        button.backgroundColor = track.buttonColor(ticks: ticks)
        button.layer.cornerRadius = 4
        button.setTitle(track.buttonText(ticks: ticks), for: .normal)
        button.setTitleColor(track.textColor(), for: .normal)
    }

}
