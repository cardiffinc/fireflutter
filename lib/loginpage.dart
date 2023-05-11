import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  late String _verificationId;
  bool _codeSent = false;

  Future<void> verifyPhone() async {
    try {
      verificationCompleted(AuthCredential phoneAuthCredential) {
        signInWithPhoneAuthCredential(phoneAuthCredential);
      }

      verificationFailed(FirebaseAuthException authException) {
        print('Phone verification failed: ${authException.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phone verification failed: ${authException.message}')),
        );
      }

      codeSent(String verificationId, [int? forceResendingToken]) async {
        _verificationId = verificationId;
        setState(() {
          _codeSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code Sent')),
        );
      }

      codeAutoRetrievalTimeout(String verificationId) {
        _verificationId = verificationId;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text,
        timeout: const Duration(seconds: 60),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    } on FirebaseAuthException catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } 
  }

  Future<void> signInWithPhoneAuthCredential(
      AuthCredential phoneAuthCredential) async {
    try {
      final authCredentialResult =
          await FirebaseAuth.instance.signInWithCredential(phoneAuthCredential);
      final user = authCredentialResult.user;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user?.phoneNumber} logged in')),
      );
    } on FirebaseAuthException catch (e) {
      print('Sign in failed: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone number'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _codeSent
                  ? TextFormField(
                      controller: _codeController,
                      decoration:
                          InputDecoration(labelText: 'Verification code'),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter verification code';
                        }
                        return null;
                      },
                    )
                  : SizedBox(),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _codeSent
                        ? FirebaseAuth.instance
                            .signInWithCredential(PhoneAuthProvider.credential(
                                verificationId: _verificationId,
                                smsCode: _codeController.text))
                            .then((value) {
                            final user = value.user;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('${user?.phoneNumber} logged in')),
                            );
                          }).catchError((e) {
                            print('Sign in failed: ${e.message}');
                          })
                        : verifyPhone();
                  }
                },
                child: Text(_codeSent ? 'Login' : 'Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
