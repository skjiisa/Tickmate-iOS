//
//  TickmateViewController.swift
//  Tickmate
//
//  Created by Elaine Lyons on 12/14/21.
//

import SwiftUI

struct TickmateView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> TickmateViewController {
        UIStoryboard(name: "Tickmate", bundle: .main).instantiateViewController(withIdentifier: "TickmateTableVC") as! TickmateViewController
    }
    
    func updateUIViewController(_ uiViewController: TickmateViewController, context: Context) {
        print("Update")
    }
}

//MARK: - TickmateViewController

class TickmateViewController: UIViewController {
    
    var numPages: Int = 5
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableWidth: NSLayoutConstraint!
    @IBOutlet weak var pageView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.changeMultiplier(of: &tableWidth, to: CGFloat(numPages))
    }
}

//MARK: Table View Data Source

extension TickmateViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TestCell", for: indexPath)
        
        if let dayCell = cell as? DayTableViewCell {
            dayCell.load(day: indexPath.row, numPages: numPages)
        }
        
        return cell
    }
}

//MARK: Table View Delegate

extension TickmateViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }
}

//MARK: - Constraints

extension NSLayoutConstraint {
    func constraintWithMultiplier(_ multiplier: CGFloat) -> NSLayoutConstraint {
        NSLayoutConstraint(item: firstItem!, attribute: firstAttribute, relatedBy: relation, toItem: secondItem, attribute: secondAttribute, multiplier: multiplier, constant: constant)
    }
}

//MARK: - View Constraints

extension UIView {
    func changeMultiplier(of constraint: inout NSLayoutConstraint, to multiplier: CGFloat) {
        let newConstraint = constraint.constraintWithMultiplier(multiplier)
        constraint.isActive = false
        removeConstraint(constraint)
        addConstraint(newConstraint)
        layoutIfNeeded()
        constraint = newConstraint
    }
}
