//
//  AcknowledgementsView.swift
//  Tickmate
//
//  Created by Isaac Lyons on 3/10/21.
//

import SwiftUI

struct AcknowledgementsView: View {
    
    private var tickmateAcknowledgement = Acknowledgement(
        name: "BSD 2-Clause License",
        copyright: "2021, Isaac Lyons",
        license: .bsd2)
    
    private var acknowledgements = [
        Acknowledgement(name: "SwiftDate", copyright: "2018 Daniele Margutti", link: "https://github.com/malcommac/SwiftDate", license: .mit),
        Acknowledgement(name: "Introspect for SwiftUI", copyright: "2019 Timber Software", license: .mit)
    ]
    
    @State private var selection: Acknowledgement?
    @State private var listID = UUID()
    
    var body: some View {
        List {
            Section(header: Text("License")) {
                Text("This app is open-source software.")
                AcknowledgementLink(tickmateAcknowledgement, selection: $selection)
            }
            
            Section(header: Text("Libraries")) {
                ForEach(acknowledgements, id: \.self) { acknowledgement in
                    AcknowledgementLink(acknowledgement, selection: $selection)
                }
            }
        }
        .buttonStyle(BorderlessButtonStyle())
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Acknowledgements")
        // Workaround for buggy NavigationLink behavior in iOS 14
        .id(listID)
        .onAppear {
            if selection != nil {
                selection = nil
                listID = UUID()
            }
        }
    }
}

struct AcknowledgementsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AcknowledgementsView()
        }
    }
}
