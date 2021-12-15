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
    var page: Int = 0
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableWidth: NSLayoutConstraint!
    @IBOutlet weak var pageView: UIScrollView!
    
    private var dragging = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.changeMultiplier(of: &tableWidth, to: CGFloat(numPages))
        
        pageView.delegate = self
        
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.3) {
                    self.pageView.contentOffset.x = self.pageView.frame.width * CGFloat(self.page)
                }
            }
        }
    }
    
    private func setPage() {
        page = Int(round(self.pageView.contentOffset.x / self.pageView.frame.width))
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

//MARK: Scroll View Delegate

extension TickmateViewController {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView == pageView else { return }
        print("Dragging")
        dragging = true
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView == pageView else { return }
        print("Done dragging")
        dragging = false
        setPage()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == pageView else { return }
        print("Done decelerating")
        dragging = false
        setPage()
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
