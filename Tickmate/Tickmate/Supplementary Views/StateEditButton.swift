//
//  StateEditButton.swift
//  Tickmate
//
//  Created by Elaine Lyons on 3/8/21.
//

import SwiftUI

// An edit button that references a binding to a @State EditMode rather than the environment's.
// The default EditButton and environment EditMode are buggy and this behaves more predictably.

struct StateEditButton: View {
    
    @Binding var editMode: EditMode
    var doneText = "Done"
    var onTap: () -> Void = {}
    
    var body: some View {
        Button(editMode.isEditing ? doneText : "Edit") {
            withAnimation {
                editMode = editMode == .active ? .inactive : .active
            }
            onTap()
        }
        .animation(.none, value: editMode)
    }
}

struct BindingEditButton_Previews: PreviewProvider {
    static var previews: some View {
        StateEditButton(editMode: .constant(.inactive))
    }
}
