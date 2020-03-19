//
//  CharacterListItem.swift
//  Battle Roll
//
//  Created by Henrik Anthony Odden Sandberg on 17/03/2020.
//  Copyright © 2020 Henrik Anthony Odden Sandberg. All rights reserved.
//

import SwiftUI

struct CharacterListItem: View {
    var number: Int
    var character: CharacterModell
    var body: some View {
        ZStack {
            Rectangle()
                .shadow(radius: 5)
                .foregroundColor(character.hasInitiative ? Color(.orange) : Color(UIColor(named: "MyBackground")!))
                
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(number+1)")
                        .font(.system(size: 60))
                        .fontWeight(.heavy)
                        .padding(.horizontal)
                }
                Image(character.imageURL)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .scaleEffect(2)
                    .offset(x: 20, y: 10)
                    .clipShape(
                        Rectangle()
                            .size(width: 250, height: 150)
                            .offset(x: -90, y: -50))
                    .shadow(radius: 5)
                    .padding(.top)
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Player")
                        .font(.subheadline)
                    Text(character.name)
                        .font(.title)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Initiative")
                        .font(.subheadline)
                    Text("\(character.initiative ?? 0)")
                        .font(.system(size: 32))
                }
                Spacer()
            }
            .foregroundColor(character.hasInitiative ? Color(.white) : Color(UIColor(named: "InvertedColors")!))
            .padding(.top)
        }

    }
}

struct CharacterListItem_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CharacterListItem(
                number: 1,
                character: CharacterModell(imageURL: "Ezra", name: "Ezra", hasInitiative: false, initiative: 15)
            ).environment(\.colorScheme, .light)
            CharacterListItem(
                number: 1,
                character: CharacterModell(imageURL: "Mikau", name: "Mikau", hasInitiative: false, initiative: 20)
            ).environment(\.colorScheme, .dark)
        }
    }
}
