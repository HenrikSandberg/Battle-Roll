import SwiftUI

struct InitativeList: View {
    @State var characters: [CharacterModell]
        
//        .sorted { (a: CharacterModell, b: CharacterModell) -> Bool in return a.initiative ?? 0 > b.initiative ?? 0 }
    var body: some View {
            NavigationView {
                List(Range(0...characters.count-1)) { number in
                    NavigationLink(destination: Profile(character: self.characters[number])){
                        HStack(alignment: .bottom, spacing: 5){
                            CharacterListItem(
                                number: number,
                                character: self.characters[number])
                        }

                    }
                }
                .navigationBarItems(trailing:
                    Button(action: {
                        // Add action
                        print("Should do somthing")
                    }, label: {
                        Text("New")
                    })
                )
                .navigationBarTitle(Text("Initiative"))
                .padding(.trailing, -30)
                .padding(.leading, -15)
                .font(.title)
        }
    }
}

struct InitativeList_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            InitativeList(characters: characters).environment(\.colorScheme, .light)
            InitativeList(characters: characters).environment(\.colorScheme, .dark)
        }
    }
}
