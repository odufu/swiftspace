import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  final g = GoogleSignIn.instance;
  await g.initialize(serverClientId: 'test');
  print(g.authenticate);
}
