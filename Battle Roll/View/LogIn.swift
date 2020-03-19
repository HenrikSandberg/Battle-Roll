import SwiftUI
import UIKit

struct Login: View {
    
    //MARK: Properties
    @State var email: String = ""
    @State var password: String = ""
    @State var passwordTwo: String = ""
    @State var shouldSignUp = false
    
    @EnvironmentObject var session: FirebaseSession
    
    var body: some View {
        ZStack {
            Color(.orange)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .center, spacing: 14) {
                Group {
                    if !shouldSignUp {
                        Text("Sign In")
                            .font(.title)
                            .fontWeight(.heavy)
                            .padding()

                        VStack {
                            TextField("Email", text: $email)
                                .padding()
                            SecureField("Password", text: $password)
                                .padding()
                        }.padding()


                        ActionButtons (
                            textOne: "Sign In",
                            actionOne: logIn,
                            textTwo: "Sign Up",
                            actionTwo: {
                                self.shouldSignUp = true
                        })
                    } else {
                        Text("Sign Up")
                            .font(.title)
                            .fontWeight(.heavy)
                            .padding()
                        
                        VStack {
                            TextField("Email", text: $email)
                                .padding()
                            SecureField("Password", text: $password)
                                .padding()
                            SecureField("Password", text: $passwordTwo)
                                .padding()
                        }.padding()
                        
                        ActionButtons (
                            textOne: "Sign Up",
                            actionOne: signUp,
                            textTwo: "Sign In",
                            actionTwo: {
                                self.shouldSignUp = false
                        })
                    }
                }
            }
            .background(Color(UIColor(named: "MyBackground")!))
            .cornerRadius(6)
            .shadow(radius: 5)
            .animation(.default)
            .padding()
        }
    }
    
    //MARK: Functions
    func logIn() {
        if !email.isEmpty && !password.isEmpty {
            session.logIn(email: email, password: password) { (result, error) in
                if error != nil {
                    print("Error: \n\(String(describing: error))")
                } else {
                    self.email = ""
                    self.password = ""
                }
            }
        }  else {
           print("Not correct")
       }
    }
    
    func signUp() {
        if !email.isEmpty && !password.isEmpty && password.elementsEqual(passwordTwo)  {
            session.signUp(email: email, password: password) { (result, error) in
                if error != nil {
                    print("Error: \n\(String(describing: error))")
                } else {
                    self.email = ""
                    self.password = ""
                }
            }
        } else {
            print("Not correct")
        }
    }
}

//MARK: ActionButtons
struct ActionButtons: View {
    var textOne: String
    var actionOne: () -> Void
    var textTwo: String
    var actionTwo: () -> Void
    var body: some View {
        VStack {
            Button(action: actionOne) {
                Text(textOne)
                    .font(.system(size: 24))
                    .padding()
            }
            .foregroundColor(Color.white)
            .background(Color.orange)
            .cornerRadius(6)

            Button(action: actionTwo, label: {
                Text(textTwo)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }).padding()
            
        }
    }
}

//MARK: Previews
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Login()
    }
}
