import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

void main() async {
  await YandexMapkit.setup('2c701245-ce40-4d13-ae8d-f4b9b51caa9d');
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  YandexMapController _yandexMapController;
  YandexSearchSession _session;

  String currentName;
  Point currentPoint;

  dispose() {
    _session.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: YandexMap(
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
                      .listen((CameraPositionEvent event) async {
                    setState(() => currentPoint = event.position.target);

                    if (event.finished) {
                      _session?.cancel();

                      _session = await YandexSearchManager.sharedInstance
                          .submitWithPoint(
                        point: event.position.target,
                        zoom: event.position.zoom,
                        searchOptions: SearchOptions(searchTypes: [
                          SearchType.Geo,
                        ]),
                        onSuccess: (SearchResult result) {
                          if (result.items.isNotEmpty) {
                            if (result.items.first.address.components.last.kinds.contains('house')) {
                              print("all right! its address");
                            } else {
                              print("fuck! it's other");
                            }

                            setState(
                                () => currentName = result.items.first.name);
                          }
                        },
                        onError: (String error) {
                          print("ERROR!! $error}");
                        },
                      );
                    }
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
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.center,
                child: DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 18,
                      color: const Color(0xFF000000),
                      shadows: [
                        Shadow(
                          color: const Color(0xFF000000),
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(currentName ?? ""),
                        Text(currentPoint != null
                            ? "${currentPoint.latitude} \n ${currentPoint.longitude}"
                            : ''),
                      ],
                    )),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Builder(
                  builder: (BuildContext context) {
                    return Container(
                      height: 3,
                      width: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: const Color(0xFFFF0000),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
