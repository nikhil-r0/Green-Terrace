import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_terrace/models/person.dart';

class AuthService{
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Person? _personFromUser(User? user){
    return user != null? Person(userID: user.uid): null;
  }

  Stream<Person?> get user{
    return _auth.authStateChanges()
      //.map((User? user)=>_personFromUser(user));
      .map(_personFromUser);
  }


  Future signInAnom() async{
    try{
      UserCredential result = await _auth.signInAnonymously();
      return _personFromUser(result.user);
    }
    catch(e){
      print(e.toString());
      return null;
    }
  }
  // sign in email & password
  Future signInEmail(String emailID, String password) async{
    try{
      final credential = await _auth.signInWithEmailAndPassword(
        email: emailID, 
        password: password
        );
      return credential.user;
    }on FirebaseAuthException catch(e){
      if(e.code == 'user-not-found'){
        print('No user found for this email.');
        return null;
      }else if(e.code == 'wrong-password'){
        print('Wrong Password');
        return null;
      }
    }
  }

  // register email & password

  // sign out
}