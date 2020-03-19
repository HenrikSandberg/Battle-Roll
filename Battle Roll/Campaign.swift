import Foundation

class Campaign {
    var id: String
    var gameMaster: User
    var characters: [CharacterModell]?
    
    
    init(id: String, gameMaster: User, characters: [CharacterModell]? = nil) {
        self.id = id
        self.gameMaster = gameMaster
        
        if characters != nil {
            self.characters = characters
        } else {
            self.characters = [
                CharacterModell(imageURL: "Ezra", name: "Ezra", hasInitiative: false, initiative: nil),
                CharacterModell(imageURL: "Aira", name: "Aira", hasInitiative: false, initiative: nil),
                CharacterModell(imageURL: "Mikau", name: "Mikau", hasInitiative: true, initiative: nil),
                CharacterModell(imageURL: "Möfar", name: "Möfar", hasInitiative: false, initiative: nil),
                CharacterModell(imageURL: "Sanka", name: "Sanka", hasInitiative: false, initiative: nil),
                CharacterModell(imageURL: "Kalex", name: "Kalex", hasInitiative: false, initiative: nil)
            ]
        }
    }
}
