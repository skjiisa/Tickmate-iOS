//
//  ViewControllerContainer.swift
//  Tickmate
//
//  Created by Isaac Lyons on 3/12/21.
//

import SwiftUI

class ViewControllerContainer: NSObject, ObservableObject, UIAdaptivePresentationControllerDelegate {
    
    @Published var editMode = EditMode.inactive
    
    weak var vc: UIViewController? = nil
    
    func deactivateEditMode() {
        // Because editMode is @Published, if a View edits it in an Introspect function, that will
        // cause the view to redraw, causing the function to be called again, creating and infinite
        // cycle. Perform this check so it only publishes changes if it actually needs to change.
        if editMode.isEditing {
            editMode = .inactive
        }
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        !editMode.isEditing
    }
}
