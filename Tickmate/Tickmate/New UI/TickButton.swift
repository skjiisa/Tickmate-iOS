//
//  TickButton.swift
//  Tickmate
//
//  Created by Elaine Lyons on 10/11/22.
//

import UIKit

class TickButton: UIButton {
    
    convenience init(for track: Track, tickController: TickController, day: Int) {
        let action = UIAction { action in
            UISelectionFeedbackGenerator().selectionChanged()
            tickController.tick(day: day)
        }
        self.init(primaryAction: action)
    }

    func configure(for track: Track, ticks: Int) {
        backgroundColor = track.buttonColor(ticks: ticks)
        layer.cornerRadius = 4
        setTitle(track.buttonText(ticks: ticks), for: .normal)
        setTitleColor(track.textColor(), for: .normal)
        
        translatesAutoresizingMaskIntoConstraints = false
    }

}
