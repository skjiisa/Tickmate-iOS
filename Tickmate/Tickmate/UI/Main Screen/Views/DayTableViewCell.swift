//
//  DayTableViewCell.swift
//  PageView
//
//  Created by Elaine Lyons on 2/17/22.
//

import UIKit

class DayTableViewCell: UITableViewCell {

    private var tracks: [Track] = []
    
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
    
    func configure(with tracks: [Track]) {
        self.tracks = tracks
        
        stackView.arrangedSubviews.forEach { view in
            view.removeConstraints(view.constraints)
            view.removeFromSuperview()
        }
        
        tracks.enumerated().forEach { index, track in
            let button = self.button(for: track)
            button.tag = index
            stackView.addArrangedSubview(button)
            NSLayoutConstraint.activate([
                // -12 matches the old SwiftUI Tickmate
                button.heightAnchor.constraint(equalTo: stackView.heightAnchor, constant: -10)
            ])
        }
    }
    
    private func button(for track: Track) -> UIButton {
        if let button = buttons[track] {
            return button
        }
        
        // Create button
        let button = UIButton(primaryAction: UIAction { action in
            print(track.name)
        })
        //TODO: Make Track convenience functions for color
        button.backgroundColor = UIColor(rgb: Int(track.color))
        button.layer.cornerRadius = 4
        //TODO: Update foreground color
        button.tintColor = .white
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        buttons[track] = button
        return button
    }

}
