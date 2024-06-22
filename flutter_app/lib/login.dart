import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:detection_app/Map.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  State<Login> createState() => LoginState();
}

class LoginState extends State<Login> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  Future<void> login() async {
    final String account = _idController.text;
    final String password = _pwController.text;

    final response = await http.post(
      Uri.parse('http://api.cse-detection.kro.kr/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'account': account,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print(responseData);
      final int userId = responseData['id'];
      print('로그인 성공, userId: $userId');
      // 로그인 성공 후의 로직을 여기에 추가합니다.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Map(userId: userId)),
      );
    } else {
      final error = jsonDecode(response.body);
      print(error);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('로그인에 실패했습니다.'),
          content: Text('${error['message']}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 30, right: 30, top: 15),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: '계정',
                  border: OutlineInputBorder(),
                ),
                controller: _idController,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 30, right: 30, top: 15),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
                obscureText : true,
                controller: _pwController,
              ),
            ),
            ElevatedButton(
              onPressed: login,
              child: const Text('로그인'),
            ),
          ],
        ),
      ),
    );
  }
}