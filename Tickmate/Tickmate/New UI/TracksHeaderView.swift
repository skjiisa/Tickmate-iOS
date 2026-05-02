//
//  TracksHeaderView.swift
//  Tickmate
//
//  Created by Elaine on 3/19/24.
//

import UIKit

// The original version of this file was written by Trae using Claude-3.5-Sonnet

/// Notified when the user taps one of the per-track icon buttons in the
/// page header. The host VC presents the matching `TrackView` sheet.
protocol TracksHeaderViewDelegate: AnyObject {
    func tracksHeader(_ header: TracksHeaderView, didTap track: Track)
}

class TracksHeaderView: UIView {

    // MARK: Properties

    weak var delegate: TracksHeaderViewDelegate?

    /// Tracks whose buttons are currently in the stack view, keyed by the
    /// button instance. We keep this so the tap handler can find the original
    /// Track without resorting to the deprecated objectID.hashValue trick.
    private var trackForButton: [UIButton: Track] = [:]

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let divider: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: Setup

    private func setupViews() {
        backgroundColor = .systemBackground

        addSubview(stackView)
        addSubview(divider)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 120),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: divider.topAnchor, constant: -4),

            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    // MARK: Configuration

    func configure(with tracks: [Track]) {
        // Remove existing track buttons
        stackView.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
        trackForButton.removeAll()

        // Add new track buttons
        for track in tracks {
            let button = createTrackButton(for: track)
            stackView.addArrangedSubview(button)
            trackForButton[button] = track
        }
    }

    private func createTrackButton(for track: Track) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemFill
        button.layer.cornerRadius = 3
        button.clipsToBounds = true

        if let systemImage = track.systemImage {
            let imageConfig = UIImage.SymbolConfiguration(scale: .medium)
            let image = UIImage(systemName: systemImage, withConfiguration: imageConfig)?
                .withRenderingMode(.alwaysTemplate)
            button.setImage(image, for: .normal)
            button.imageView?.contentMode = .center
            button.tintColor = .label
        }

        button.addTarget(self, action: #selector(trackButtonTapped(_:)), for: .touchUpInside)

        return button
    }

    // MARK: Actions

    @objc private func trackButtonTapped(_ sender: UIButton) {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()

        guard let track = trackForButton[sender] else { return }
        delegate?.tracksHeader(self, didTap: track)
    }
}
