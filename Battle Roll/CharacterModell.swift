import Foundation

struct CharacterModell {
    var imageURL: String
    var name: String
    var hasInitiative: Bool = false
    var initiative: Int?
}


let characters = [
    CharacterModell(imageURL: "Ezra", name: "Ezra", hasInitiative: false, initiative: 15),
    CharacterModell(imageURL: "Aira", name: "Aira", hasInitiative: false, initiative: 17),
    CharacterModell(imageURL: "Mikau", name: "Mikau", hasInitiative: true, initiative: 24),
    CharacterModell(imageURL: "Möfar", name: "Möfar", hasInitiative: false, initiative: 10),
    CharacterModell(imageURL: "Sanka", name: "Sanka", hasInitiative: false, initiative: 20),
    CharacterModell(imageURL: "Kalex", name: "Kalex", hasInitiative: false, initiative: 16)
]
