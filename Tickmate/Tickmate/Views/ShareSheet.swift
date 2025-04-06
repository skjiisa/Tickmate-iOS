//
//  ShareSheet.swift
//  Tickmate
//
//  Created by Trae AI on 3/14/24.
//

import SwiftUI

/// This type was written by Trae using Claude-3.5-Sonnet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
