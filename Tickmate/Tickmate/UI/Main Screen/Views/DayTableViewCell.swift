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
    private var buttons: [Track: TickButton] = [:]
    
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
            button.configure(for: track, ticks: ticks)
            button.tag = index
            stackView.addArrangedSubview(button)
            NSLayoutConstraint.activate([
                // -12 matches the old SwiftUI implementation
                button.heightAnchor.constraint(equalTo: stackView.heightAnchor, constant: -10)
            ])
            
            // Set up publisher to respond to changes
            tickController.$ticks.sink { allTicks in
                // We can't use the tickController's ticks(on:) convenience
                // function because it hasn't updated yet as of this sink call
                guard allTicks.indices.contains(day) else { return }
                let ticks = Int(allTicks[day]?.count ?? 0)
                button.configure(for: track, ticks: ticks)
            }
            .store(in: &subscriptions)
        }
    }
    
    private func button(for track: Track, tickController: TickController) -> TickButton {
        if let button = buttons[track] {
            return button
        }
        
        let button = TickButton(for: track, tickController: tickController, day: day)
        
        buttons[track] = button
        return button
    }

}
