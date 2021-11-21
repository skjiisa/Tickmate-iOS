//
//  PagingController.swift
//  Tickmate
//
//  Created by Elaine Lyons on 11/18/21.
//

import SwiftUI
import Introspect

//MARK: PagingController

class PagingController: NSObject, ObservableObject {
    
    @Published private(set) var page: Int = 0
    @Published var offset: CGFloat = 0
    @Published var moving = false
    
    weak private(set) var scrollView: UIScrollView?
    weak private(set) var titleScrollView: UIScrollView?
    weak private(set) var tracksScrollView: UIScrollView?
    
    private var drop: DispatchWorkItem?
    private var impact: DispatchWorkItem?
    
    func load(scrollView: UIScrollView) {
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        self.scrollView = scrollView
    }
    
    func load(titleScrollView: UIScrollView) {
        titleScrollView.isUserInteractionEnabled = false
        self.titleScrollView = titleScrollView
    }
    
    func load(tracksScrollView: UIScrollView) {
        tracksScrollView.isUserInteractionEnabled = false
        self.tracksScrollView = tracksScrollView
    }
    
}

//MARK: UIScrollViewDelegate

extension PagingController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
        titleScrollView?.contentOffset.x = x
        tracksScrollView?.contentOffset.x = x
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        drop?.cancel()
        impact?.cancel()
        withAnimation {
            moving = true
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // I one time had a weird case where isPagingEnabled somehow got disabled, so just put it everywhere
        scrollView.isPagingEnabled = true
        //print("scrollViewDidEndDragging", scrollView.contentOffset)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollView.isPagingEnabled = true
        //print("scrollViewDidEndDecelerating", scrollView.contentOffset)
        
        // Page
        if scrollView.frame.width > 0 {
            page = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
            print("Page:", page)
        }
        
        // Day overlay
        let drop = DispatchWorkItem { [weak self] in
            withAnimation(.easeInOut(duration: 0.125)) {
                self?.moving = false
            }
        }
        self.drop = drop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.125, execute: drop)
        
        // Haptic feedback
        let impact = DispatchWorkItem {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
        self.impact = impact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: impact)
    }
}
