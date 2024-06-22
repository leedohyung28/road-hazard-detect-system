import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';

const apiPath = 'http://api.cse-detection.kro.kr';

class AccountForm extends StatefulWidget {
  const AccountForm({super.key});

  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  Future<void> postData() async {
    final token = await FirebaseMessaging.instance.getToken();
    final response = await http.post(
      Uri.parse('$apiPath/create-account'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': _nameController.text,
        'account': _idController.text,
        'password': _pwController.text,
        'device_token': token!,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          Future.delayed(const Duration(seconds: 5), () {
            Navigator.of(context).pop(true);
          });
          return AlertDialog(
            title: const Text('Success'),
            content: Text('${data['data']['name']}님! 성공적으로 등록되었습니다.'),
            actions: <Widget>[
              TextButton(onPressed: () {
                Navigator.of(context).pop(true);
              }, child: const Text('닫기'))
            ],
          );
        },
      );
    } else {
      final error = jsonDecode(response.body);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          Future.delayed(const Duration(seconds: 5), () {
            Navigator.of(context).pop(true);
          });
          return AlertDialog(
            title: const Text('Error'),
            content: Text('${error['message']}'),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원정보 생성'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 30, right: 30, top: 15),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: '이름',
                  border: OutlineInputBorder(),
                ),
                controller: _nameController,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 30, right: 30, top: 15),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: '신문고 아이디',
                  border: OutlineInputBorder(),
                ),
                controller: _idController,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 30, right: 30, top: 15),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: '신문고 비밀번호',
                  border: OutlineInputBorder(),
                ),
                obscureText : true,
                controller: _pwController,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: postData,
              child: const Text('등록하기'),
            ),
          ],
        ),
      ),
    );
  }
}
