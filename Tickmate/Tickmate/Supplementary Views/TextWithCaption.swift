//
//  TextWithCaption.swift
//  Tickmate
//
//  Created by Elaine Lyons on 2/23/21.
//

import SwiftUI

struct TextWithCaption: View {
    
    var text: String
    var caption: String?
    
    init(text: String, caption: String? = nil) {
        self.text = text
        self.caption = caption
    }
    
    init(_ text: String, caption: String? = nil) {
        self.text = text
        self.caption = caption
    }
    
    @ViewBuilder
    private var captionView: some View {
        if let caption = caption,
           !caption.isEmpty {
            if #available(iOS 17, visionOS 1, *) {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(caption)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(text)
            captionView
        }
    }
}

struct TextWithCaption_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                TextWithCaption(text: "Text", caption: "Caption")
                TextWithCaption(text: "Text with no caption", caption: nil)
            }
        }
    }
}
