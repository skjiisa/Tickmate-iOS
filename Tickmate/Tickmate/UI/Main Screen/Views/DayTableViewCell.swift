//
//  DayTableViewCell.swift
//  PageView
//
//  Created by Elaine Lyons on 2/17/22.
//

import UIKit

class DayTableViewCell: UITableViewCell {

    private var tracks: [Track] = []
    private var day: Int = 0
    
    private var stackView = UIStackView()
    private var buttons: [Track: UIButton] = [:]
    
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
        
        tracks.enumerated().forEach { index, track in
            let button = self.button(for: track)
            configure(button: button, for: track)
            button.tag = index
            stackView.addArrangedSubview(button)
            NSLayoutConstraint.activate([
                // -12 matches the old SwiftUI implementation
                button.heightAnchor.constraint(equalTo: stackView.heightAnchor, constant: -10)
            ])
        }
    }
    
    private func button(for track: Track) -> UIButton {
        if let button = buttons[track] {
            return button
        }
        
        // Create button
        let action = UIAction { action in
            print(track.name)
        }
        let button = UIButton(primaryAction: action)
        
        buttons[track] = button
        return button
    }
    
    private func configure(button: UIButton, for track: Track) {
        let ticks = TrackController.shared.tickController(for: track).ticks(on: day)
        
        button.backgroundColor = track.buttonColor(ticks: ticks)
        button.layer.cornerRadius = 4
        button.setTitle(track.buttonText(ticks: ticks), for: .normal)
        button.setTitleColor(track.textColor(), for: .normal)
        
        button.translatesAutoresizingMaskIntoConstraints = false
    }

}
