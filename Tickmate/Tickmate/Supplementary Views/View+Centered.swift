//
//  View+Centered.swift
//  Tickmate
//
//  Created by Elaine Lyons on 5/14/21.
//

import SwiftUI

private struct CenteredModifier: ViewModifier {
    func body(content: Content) -> some View {
        HStack {
            Spacer()
            content
            Spacer()
        }
    }
}

extension View {
    func centered() -> some View {
        self.modifier(CenteredModifier())
    }
}
