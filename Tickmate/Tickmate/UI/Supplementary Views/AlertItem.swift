//
//  AlertItem.swift
//  Tickmate
//
//  Created by Isaac Lyons on 6/1/21.
//

import SwiftUI

class AlertItem: Identifiable {
    var title: String
    var message: String?
    
    init(title: String, message: String? = nil) {
        self.title = title
        self.message = message
    }
    
    var alert: Alert {
        if let message = message {
            return Alert(title: Text(title), message: Text(message))
        }
        
        return Alert(title: Text(title))
    }
    
    static func alert(for alertItem: AlertItem) -> Alert {
        alertItem.alert
    }
}

extension View {
    func alert(alertItem: Binding<AlertItem?>) -> some View {
        self.alert(item: alertItem) { $0.alert }
    }
}
