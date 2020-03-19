import SwiftUI

struct ContentView: View {
    @ObservedObject var session = FirebaseSession()
    var body: some View {
        Group {
            if session.session != nil {
                Text("Hello World")
            } else {
                Login().environmentObject(session)
            }
        }
        .onAppear(perform: getUser)
    }
    
    //MARK: Functions
    func getUser() {
        session.listen()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


//TabView {
//    InitativeList(characters: characters)
//        .tabItem({
//            Image(systemName: "circle")
//            Text("First")
//        })
//        .tag(0)
//    UserPage()
//        .environmentObject(session)
//        .font(.title)
//        .tabItem({
//            Image(systemName: "square")
//            Text("Second")
//        })
//        .tag(1)
//}
