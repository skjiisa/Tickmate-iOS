//
//  DayTableViewCell.swift
//  Tickmate
//
//  Created by Elaine Lyons on 12/14/21.
//

import UIKit

class DayTableViewCell: UITableViewCell {
    
    private weak var stackView: UIStackView?
    private var numPages: Int = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func load(day: Int, numPages: Int) {
        if let stackView = stackView {
            // Update existing stack view
            if numPages == self.numPages {
                // Update existing
                stackView.arrangedSubviews.enumerated().forEach { page, view in
                    guard let label = view as? UILabel else { return }
                    label.text = "Page \(page), row \(day)"
                }
            } else {
                // Remove and recreate pages
                stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                createPages(day: day)
            }
        } else {
            setUpViews(startingDay: day, numPages: numPages)
        }
    }
    
    private func setUpViews(startingDay: Int, numPages: Int) {
        self.numPages = numPages
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        
        addConstraints([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        self.stackView = stackView
        
        createPages(day: startingDay)
    }
    
    private func createPages(day: Int) {
        guard let stackView = stackView else { return }
        _ = (0..<numPages).map { page -> UILabel in
            let label = UILabel()
            label.text = "Page \(page), row \(day)"
            stackView.addArrangedSubview(label)
            return label
        }
    }
    
}
