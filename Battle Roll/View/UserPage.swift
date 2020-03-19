//
//  UserPage.swift
//  Battle Roll
//
//  Created by Henrik Anthony Odden Sandberg on 19/03/2020.
//  Copyright © 2020 Henrik Anthony Odden Sandberg. All rights reserved.
//

import SwiftUI

struct UserPage: View {
    @EnvironmentObject var session: FirebaseSession
    @State var selection = 0
    
    var body: some View {
        NavigationView {
            VStack{
                Text(session.session?.email ?? "No email")
                Form {
                    Section {
                        Picker(selection: $selection, label:
                            Text("Choose Charcter")
                            , content:{
                                ForEach(0 ..< characters.count) { index in
                                    Text(self.characters[index].name)
                                    .tag(index)
                            }
                        })
                    }
                }
            }.navigationBarTitle("Profile")
        }
    }
}

struct UserPage_Previews: PreviewProvider {
    static var previews: some View {
        UserPage()
    }
}
