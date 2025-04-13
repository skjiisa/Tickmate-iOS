//
//  ViewController.swift
//  PageView
//
//  Created by Elaine Lyons on 2/10/22.
//

import SwiftUI
import Combine

struct NewUI: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateInitialViewController()!
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
}

class ViewController: UIViewController {
    
    //MARK: Properties

    @IBOutlet weak var tableViewContainer: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var shadowView: UIView!
    
    var scrollController: ScrollController = .shared
    private var subscribers = Set<AnyCancellable>()
    private var drop: DispatchWorkItem?
    private var impact: DispatchWorkItem?
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: nil, action: nil)
        
        // Set up shadow
        shadowView.layer.shadowRadius = 4
        //shadowView.layer.shadowOpacity = 0.5
        shadowView.clipsToBounds = false
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        // Could also not deal with tableViewContainer at all and have
        // a custom header view here that intentionally and distinctly
        // covers the Tracks table view controller header.
        
        // Hide the header when scrolling
        let maskLayer1 = CALayer()
        maskLayer1.backgroundColor = UIColor.black.cgColor
        maskLayer1.frame = CGRect(x: 0, y: 44, width: tableView.frame.width, height: tableView.frame.height * 2)
        
        tableViewContainer.layer.mask = maskLayer1
        
        // Keep shadow on the right
        let maskLayer = CALayer()
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.frame = CGRect(x: 0, y: 44, width: tableView.frame.width * 2, height: tableView.frame.height * 2)
        
        shadowView.layer.mask = maskLayer
        
        // Sync scroll position
        scrollController.$contentOffset.sink { [weak self] contentOffset in
            self?.tableView.contentOffset = contentOffset
        }
        .store(in: &subscribers)
        
        scrollController.$isPaging.sink { [weak self] isPaging in
            guard let self = self else { return }
            if isPaging {
                self.drop?.cancel()
                self.impact?.cancel()
                UIView.animate(withDuration: 0.25) {
                    self.shadowView.layer.shadowOpacity = 0.5
                }
            } else {
                self.endPaging()
            }
        }
        .store(in: &subscribers)
    }
    
    //MARK: Private
    
    private func endPaging() {
        let drop = DispatchWorkItem { [weak self] in
            UIView.animate(withDuration: 0.25) {
                self?.shadowView.layer.shadowOpacity = 0
            }
        }
        self.drop = drop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.125, execute: drop)
        
        let impact = DispatchWorkItem {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
        self.impact = impact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: impact)
    }

}

//MARK: Table View Data Source

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        365 // TickController.numDays
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        " "
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TestCell", for: indexPath)
        let day = /*TickController.numDays*/ 365 - indexPath.row - 1
        switch day {
        case 0:
            cell.textLabel?.text = "Today"
        case 1:
            cell.textLabel?.text = "Yesterday"
        default:
            cell.textLabel?.text = "Day \(day)"
        }
        return cell
    }
}

//MARK: Table View Delegate

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        44
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.backgroundColor = .red
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.green.cgColor
        //view.backgroundColor = .clear
        //view.layer.opacity = 0
    }
}
