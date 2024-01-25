//
//  SymbolPicker.swift
//  Tickmate
//
//  Created by Elaine Lyons on 2/24/21.
//

import SwiftUI

struct SymbolPicker: View {
    
    @Binding var selection: String?
    
    var colunms = [GridItem(), GridItem(), GridItem(), GridItem(), GridItem()]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVGrid(columns: colunms, spacing: 16) {
                    ForEach(SymbolsList, id: \.self) { symbol in
                        Button {
                            selection = symbol
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundColor(selection == symbol ? .accentColor : Color(.systemFill))
                                    .aspectRatio(1, contentMode: .fill)
                                Image(systemName: symbol)
                                    .imageScale(.large)
                                    .foregroundColor(
                                        selection == symbol ? .white : .primary
                                    )
                            }
                        }
                        .id(symbol)
                        // If you have this many buttons at once, they HAVE to
                        // be plain or borderless or everything lags like hell.
                        .buttonStyle(.plain)
                        #if os(visionOS)
                        .buttonBorderShape(.roundedRectangle(radius: 8))
                        #endif
                    }
                }
                .padding()
            }
            .onAppear {
                proxy.scrollTo(selection, anchor: .center)
            }
        }
        .navigationBarTitle("Symbols", displayMode: .inline)
    }
}

struct SymbolPicker_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }
    
    struct Preview: View {
        @State private var selection: String? = "cube"
        var body: some View {
            NavigationView {
                SymbolPicker(selection: $selection)
            }
        }
    }
}
