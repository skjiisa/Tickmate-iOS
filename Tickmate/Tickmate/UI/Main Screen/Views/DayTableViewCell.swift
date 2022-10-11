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
    
    private var stackView = UIStackView()
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
    
    func configure(with tracks: [Track], day: Int) {
        self.tracks = tracks
        self.day = day
        
        stackView.arrangedSubviews.forEach { view in
            view.removeConstraints(view.constraints)
            view.removeFromSuperview()
        }
        
        subscriptions.forEach { $0.cancel() }
        subscriptions.removeAll()
        
        tracks.enumerated().forEach { index, track in
            let tickController = TrackController.shared.tickController(for: track)
            let ticks = tickController.ticks(on: day)
            
            let button = self.button(for: track, tickController: tickController)
            configure(button: button, for: track, ticks: ticks)
            button.tag = index
            stackView.addArrangedSubview(button)
            NSLayoutConstraint.activate([
                // -12 matches the old SwiftUI implementation
                button.heightAnchor.constraint(equalTo: stackView.heightAnchor, constant: -10)
            ])
            
            // Set up publisher to respond to changes
            tickController.$ticks.sink { [weak self] allTicks in
                // We can't use the tickController's ticks(on:) convenience
                // function because it hasn't updated yet as of this sink call
                guard allTicks.indices.contains(day),
                      let self = self else { return }
                let ticks = Int(allTicks[day]?.count ?? 0)
                self.configure(button: button, for: track, ticks: ticks)
            }
            .store(in: &subscriptions)
        }
    }
    
    private func button(for track: Track, tickController: TickController) -> UIButton {
        if let button = buttons[track] {
            return button
        }
        
        // Create button
        let action = UIAction { [weak self] action in
            guard let self = self else { return }
            tickController.tick(day: self.day)
        }
        let button = UIButton(primaryAction: action)
        
        buttons[track] = button
        return button
    }
    
    private func configure(button: UIButton, for track: Track, ticks: Int) {
        button.backgroundColor = track.buttonColor(ticks: ticks)
        button.layer.cornerRadius = 4
        button.setTitle(track.buttonText(ticks: ticks), for: .normal)
        button.setTitleColor(track.textColor(), for: .normal)
        
        button.translatesAutoresizingMaskIntoConstraints = false
    }

}
