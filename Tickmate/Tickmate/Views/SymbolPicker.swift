//
//  SymbolPicker.swift
//  Tickmate
//
//  Created by Isaac Lyons on 2/24/21.
//

import SwiftUI

struct SymbolPicker: View {
    
    @Binding var selection: String?
    
    var colunms = [GridItem(), GridItem(), GridItem(), GridItem(), GridItem()]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVGrid(columns: colunms) {
                    ForEach(SymbolsList, id: \.self) { symbol in
                        Button {
                            selection = symbol
                        } label: {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(selection == symbol ? .accentColor : Color(.systemGroupedBackground))
                                    .clipped()
                                    .cornerRadius(8.0)
                                    .aspectRatio(1, contentMode: .fill)
                                Image(systemName: symbol)
                                    .imageScale(.large)
                                    .foregroundColor(.primary)
                                    .padding()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Symbols")
    }
}

struct SymbolPicker_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SymbolPicker(selection: .constant("pencil"))
        }
    }
}
