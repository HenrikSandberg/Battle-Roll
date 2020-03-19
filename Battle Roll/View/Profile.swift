import SwiftUI

struct Profile: View {
    var character: CharacterModell
    var body: some View {
            ZStack {
                Image(character.imageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .shadow(radius: 10)
                    .grayscale(0.5)
                VStack(alignment: .trailing, spacing: 2) {
                    CharacterInfoView()
                    CharacterInfoView()
                }.offset(x: 100, y: -150)
            }
    }
}

struct CharacterInfoView: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            Text("Here comes the stats")
                .padding()
        }
        .background(Color(.white))
        .cornerRadius(6)
        .shadow(radius: 4)
        .padding(5)
    }
}

struct Profile_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            Profile(character: CharacterModell(imageURL: "Möfar", name: "Möfar", hasInitiative: false, initiative: 10))
            Profile(character: CharacterModell(imageURL: "Mikau", name: "Mikau", hasInitiative: false, initiative: 20))
        }
        
    }
}
