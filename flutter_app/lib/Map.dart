import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

const localApiPath = 'http://10.0.0.2:8080';
const apiPath = 'http://api.cse-detection.kro.kr';

class Map extends StatefulWidget {
  final int userId;

  const Map({super.key, required this.userId});

  @override
  State<Map> createState() => _MapState();
}

class _MapState extends State<Map> {
  final MapController mapController = MapController();
  double x = 36.766453;
  double y = 127.281656; // 2공학관 좌표
  LatLng _currentPosition = const LatLng(36.766453, 127.281656);
  bool _isMounted = false;
  bool _isDialogShowing = false;
  late StreamSubscription<RemoteMessage> _messageSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();

  void getMyDeviceToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    print("내 디바이스 토큰: $token");
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스가 활성화되어 있는지 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 위치 서비스가 활성화되지 않은 경우, 위치 서비스를 활성화하도록 사용자에게 요청
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    // 현재 위치 가져오기
    Geolocator.getPositionStream().listen((Position position) {
      if (_isMounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          mapController.move(_currentPosition, 19);
        });
      }
    });
  }

  Future<void> postReports() async {
    final latitude = _currentPosition.latitude;
    final longitude = _currentPosition.longitude;
    final id = widget.userId;

    final response = await http.post(
      Uri.parse('http://api.cse-detection.kro.kr/report'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'user_id': id,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Report sent successfully');
      print(data);
    } else {
      final error = jsonDecode(response.body);
      print(error);
    }
  }

  void _playSound(String soundPath) async {
    try {
      print(soundPath);
      await _audioPlayer.setVolume(75);
      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void _showTemporaryAlertDialog(dynamic title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 1), () {
          if (_isDialogShowing) {
            Navigator.of(context).pop(true);
            _isDialogShowing = false;
          }
        });
        dynamic name = '';
        if (title == 'dog') {
          name = '강아지를';
        }
        if (title == 'cat') {
          name = '고양이를';
        }
        if (title == 'human') {
          name = '사람을';
        }
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Row(
            children: [
             const Icon(Icons.warning, color: Colors.red),
              Text('$name 주의하세요!'),
            ],
          )
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getMyDeviceToken();
    _isMounted = true;

    _messageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      final title = notification?.title;

      if (title != null && !_isDialogShowing) {
        _isDialogShowing = true;

        if (title == 'dog') {
          _playSound('dog.wav');
          _showTemporaryAlertDialog(title);
        } else if (title == 'cat') {
          _playSound('cat.wav');
          _showTemporaryAlertDialog(title);
        } else if (title == 'human') {
          _showTemporaryAlertDialog(title);
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              Future.delayed(const Duration(seconds: 5), () {
                if (_isDialogShowing) {
                  postReports();
                  Navigator.of(context).pop(true);
                }
              });
              return AlertDialog(
                title: Text(notification?.title ?? '포트홀을 발견햇습니다'),
                content: Text(notification?.body ?? '신고하시겠습니까?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      postReports();
                      Navigator.of(context).pop();
                      _isDialogShowing = false;
                    },
                    child: const Text('예'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _isDialogShowing = false;
                    },
                    child: const Text('아니요'),
                  ),
                ],
              );
            },
          ).then((_) {
            _isDialogShowing = false;
          });
        }
      }
    });

    _determinePosition();
  }

  @override
  void dispose() {
    _isMounted = false;
    _messageSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: LatLng(x, y),
                initialZoom: 19,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.detection.app',
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                    ),
                  ],
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: _currentPosition,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                    ),
                  )
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Map(userId: 1),
  ));
}
