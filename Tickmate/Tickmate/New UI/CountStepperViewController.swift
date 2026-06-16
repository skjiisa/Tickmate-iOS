//
//  CountStepperViewController.swift
//  Tickmate
//
//  Created by Elaine Lyons on 6/15/26.
//

import UIKit
import Combine

/// Small popover content shown when the user taps a multiple-mode track cell
/// that already has a count of 1 or more. Presents a `−  +` stepper so the
/// count for that day can be adjusted up or down — replacing the old
/// long-press-to-decrement gesture.
///
/// There's no value label here: the count is already shown on the track button
/// the popover is anchored to. Increment/decrement route through the same
/// `TickController` the cell uses; we observe its `$ticks` publisher only to
/// disable `−` once the count reaches 0. There's no explicit clear button.
class CountStepperViewController: UIViewController {

    private let tickController: TickController
    private let day: Int

    private let decrementButton = UIButton(type: .system)
    private let incrementButton = UIButton(type: .system)

    private var subscriptions = Set<AnyCancellable>()

    init(tickController: TickController, day: Int) {
        self.tickController = tickController
        self.day = day
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .popover
        preferredContentSize = CGSize(width: 116, height: 48)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        decrementButton.setImage(UIImage(systemName: "minus"), for: .normal)
        decrementButton.accessibilityLabel = "Decrease count"
        decrementButton.addAction(UIAction { [weak self] _ in self?.decrement() }, for: .primaryActionTriggered)

        incrementButton.setImage(UIImage(systemName: "plus"), for: .normal)
        incrementButton.accessibilityLabel = "Increase count"
        incrementButton.addAction(UIAction { [weak self] _ in self?.increment() }, for: .primaryActionTriggered)

        let stack = UIStackView(arrangedSubviews: [decrementButton, incrementButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        // Keep the `−` button's enabled state in sync with the underlying tick
        // count so it can't drive the count below 0. We read from the published
        // array directly (rather than `ticks(on:)`) because the controller
        // updates the array before that convenience accessor reflects it.
        tickController.$ticks
            .sink { [weak self] allTicks in
                guard let self else { return }
                let count = allTicks.indices.contains(self.day)
                    ? Int(allTicks[self.day]?.count ?? 0)
                    : 0
                self.decrementButton.isEnabled = count > 0
            }
            .store(in: &subscriptions)

        decrementButton.isEnabled = tickController.ticks(on: day) > 0
    }

    private func increment() {
        UISelectionFeedbackGenerator().selectionChanged()
        tickController.tick(day: day)
    }

    private func decrement() {
        // `untick(day:)` returns false if there's no tick to remove, in which
        // case skip the haptic.
        if tickController.untick(day: day) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }
}
