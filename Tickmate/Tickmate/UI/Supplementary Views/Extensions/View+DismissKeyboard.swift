//
//  View+DismissKeyboard.swift
//  Tickmate
//
//  Created by Isaac Lyons on 5/7/21.
//

import SwiftUI

#if canImport(UIKit)
extension View {
    func dismissKeyboard() {
        //TODO: Replace with solution using ViewControllerContainer or iOS 15's native SwiftUI keyboard dismissal
//        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
