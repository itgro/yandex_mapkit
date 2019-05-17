import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

void main() async {
  await YandexMapkit.setup(apiKey: '2c701245-ce40-4d13-ae8d-f4b9b51caa9d');
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  YandexMapController _yandexMapController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      body: Column(children: [
        Expanded(child: YandexMap(
          onCreated: (YandexMapController controller) async {
            _yandexMapController = controller;

            Point defaultPoint = new Point(56.837626, 60.597405);

            List<Point> points = [
              new Point(
                defaultPoint.latitude + 0.0015,
                defaultPoint.longitude - 0.0015,
              ),
              new Point(
                defaultPoint.latitude - 0.0015,
                defaultPoint.longitude - 0.0015,
              ),
              new Point(
                defaultPoint.latitude,
                defaultPoint.longitude + 0.0015,
              ),
            ];

            controller.addPolygon(
              points: points,
              fillColor: Color(0xFF70C3BE).withOpacity(0.51),
              strokeColor: Color(0xFFF9F4F4),
              strokeWidth: 1,
              zIndex: 1000,
            );

            controller.onCameraPositionChanged
                .listen((CameraPositionEvent event) {
              print(event);
            });

            await controller.move(
              position: Position(
                target: defaultPoint,
              ),
              animation: MapAnimation(
                smooth: true,
              ),
            );
          },
        ))
      ]),
    ));
  }
}
