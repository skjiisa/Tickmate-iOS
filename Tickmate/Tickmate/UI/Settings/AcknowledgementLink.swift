//
//  AcknowledgementLink.swift
//  Tickmate
//
//  Created by Isaac Lyons on 3/10/21.
//

import SwiftUI

//MARK: AcknowledgementLink

struct AcknowledgementLink: View {
    
    var acknowledgement: Acknowledgement
    
    @Binding var selection: Acknowledgement?
    
    init(_ acknowledgement: Acknowledgement, selection: Binding<Acknowledgement?>) {
        self.acknowledgement = acknowledgement
        _selection = selection
    }
    
    var body: some View {
        NavigationLink(acknowledgement.name,
                       destination: AcknowledgementDetail(acknowledgement),
                       tag: acknowledgement,
                       selection: $selection)
    }
}

//MARK: AcknowledgementDetail

struct AcknowledgementDetail: View {
    
    var acknowledgement: Acknowledgement
    
    init(_ acknowledgement: Acknowledgement) {
        self.acknowledgement = acknowledgement
    }
    
    var body: some View {
        List {
            if let url = acknowledgement.url {
                Section {
                    Link(destination: url) {
                        HStack {
                            Text(acknowledgement.name)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                    }
                }
            }
            
            Section(header: Text("License")) {
                Text(acknowledgement.licenseText)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(acknowledgement.name)
    }
}

// MARK: Acknowledgement

struct Acknowledgement: Hashable {
    
    var name: String
    var copyright: String
    var link: String?
    var license: License
    
    internal init(name: String, copyright: String, link: String?, license: Acknowledgement.License) {
        self.name = name
        self.copyright = copyright
        self.link = link
        self.license = license
    }
    
    enum License {
        case mit
        case bsd2
    }
    
    var url: URL? {
        guard let link = link else { return nil }
        return URL(string: link)
    }
    
    var licenseText: String {
        switch license {
        case .mit:
            return """
Copyright (c) \(copyright)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""
        case .bsd2:
            return """
Copyright (c) \(copyright)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"""
        }
    }
}

//MARK: Preview

struct AcknowledgementLink_Previews: PreviewProvider {
    
    static let acknowledgement = Acknowledgement(name: "Library",
                                                 copyright: "20XX, Holder",
                                                 link: "https://example.com/",
                                                 license: .mit)
    
    static var previews: some View {
        NavigationView {
            List {
                AcknowledgementLink(acknowledgement, selection: .constant(acknowledgement))
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Acknowledgements")
        }
        
        NavigationView {
            AcknowledgementDetail(acknowledgement)
        }
    }
}
