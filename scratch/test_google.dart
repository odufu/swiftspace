import 'package:google_sign_in/google_sign_in.dart';

void main() {
  final GoogleSignIn g = GoogleSignIn(serverClientId: 'test');
  print(g.signIn);
}
