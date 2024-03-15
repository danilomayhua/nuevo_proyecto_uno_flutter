import 'package:flutter/material.dart';
import 'package:tenfo/screens/signup/views/signup_university_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key, this.codigoInvitacion}) : super(key: key);

  final String? codigoInvitacion;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const SignupUniversityPage();
  }
}