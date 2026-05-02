//
//  DayTableViewCell.swift
//  PageView
//
//  Created by Elaine Lyons on 2/17/22.
//

import UIKit
import Combine

class DayTableViewCell: UITableViewCell {

    private var tracks: [Track] = []
    private var day: Int = 0
    private var weekSeparatorLines: Bool = true
    private var weekSeparatorSpaces: Bool = true
    
    private var stackView = UIStackView()
    private var separatorLine: UIView?
    private var buttons: [Track: UIButton] = [:]
    
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
    
    func configure(with tracks: [Track], day: Int, lines: Bool = true, spaces: Bool = true) {
        self.tracks = tracks
        self.day = day
        self.weekSeparatorLines = lines
        self.weekSeparatorSpaces = spaces
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
