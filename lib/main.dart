import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io' show File;

import 'package:ar_demo/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';

void main() {
  runApp(MaterialApp(home: UnityDemoScreen()));
}

extension filterTreeName on String {
  bool isTreeName(List<String> treeDict) {
    final data = treeDict;
    var i = 0;
    for (; i < data.length && !(data[i] == this || this.contains("나무")); ++i);
    if (i < data.length) {
      return true;
    } else {
      return false;
    }
  }
}

class UnityDemoScreen extends StatefulWidget {
  UnityDemoScreen({Key key}) : super(key: key);

  @override
  _UnityDemoScreenState createState() => _UnityDemoScreenState();
}

class _UnityDemoScreenState extends State<UnityDemoScreen> {
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();
  final _boundaryKey = GlobalKey();
  UnityWidgetController _unityWidgetController;
  bool isTreeNameLoading = false;
  List<String> treeNames = [];
  List<String> treeDict = [];

  @override
  void initState() {
    loadDic();
  }

  void loadDic() async {
    treeDict = (await rootBundle.loadString('assets/treename.txt')).split('\n');
  }

  Future<Uint8List> captureImage() async {
    final boundary =
        _boundaryKey.currentContext.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage();
    return (await image.toByteData(format: ui.ImageByteFormat.png))
        .buffer
        .asUint8List();
    // return CaptureResult(data.buffer.asUint8List(), image.width, image.height);
  }

  Future identify() async {
    treeNames.clear();
    isTreeNameLoading = true;
    String img64 = base64Encode(await captureImage());
    // final response = await http.post(
    //   Uri.https('api.plant.id', '/v2/identify'),
    //   headers: {"Content-Type": "application/json", "Api-Key": apiKey},
    //   body: jsonEncode(
    //     {
    //       "images": [img64],
    //       "modifiers": ["similar_images"],
    //       "plant_details": [
    //         "common_names",
    //         "url",
    //         "wiki_description",
    //         "taxonomy"
    //       ]
    //     },
    //   ),
    // );
    print(img64);
    // final suggestions = json.decode(response.body)['suggestions'];
    // for (var i = 0; i < suggestions.length; ++i) {
    //   final xml2json = Xml2Json();
    //   final _res = await http.get(
    //     Uri.http(
    //       'openapi.nature.go.kr',
    //       '/openapi/service/rest/PlantService/plntIlstrSearch',
    //       {
    //         'serviceKey': treeSearchApiKey,
    //         'st': '2',
    //         'sw': suggestions[i]['plant_name'],
    //         'dateGbn': '',
    //         'dateFrom': '',
    //         'numOfRows': '10',
    //         'pageNo': '1',
    //       },
    //     ),
    //   );
    //   xml2json.parse(utf8.decode(_res.bodyBytes));
    //   final data =
    //       json.decode(xml2json.toBadgerfish())['response']['body']['items'];
    //   if (data.length > 0) {
    //     Map.castFrom(data).values.forEach((item) {
    //       // ['item']
    //       try {
    //         List.from(item).forEach((_item) {
    //           treeNames.add(Map.from(_item['plantGnrlNm']).values.elementAt(0));
    //         });
    //       } catch (e) {
    //         treeNames.add(
    //             Map.from(Map.from(item)['plantGnrlNm']).values.elementAt(0));
    //       }
    //     });
    //   }
    //   try {
    //     final _suggestions = suggestions[i]['plant_details']['common_names'];
    //     if (_suggestions != null && _suggestions.length > 0) {
    //       List.from(_suggestions).forEach(
    //         (name) async {
    //           final response = await http.get(
    //             Uri.https(
    //               'ko.wikipedia.org',
    //               '/w/api.php',
    //               {
    //                 'action': 'query',
    //                 'prop': 'extracts',
    //                 'origin': '*',
    //                 'format': 'json',
    //                 'generator': 'search',
    //                 'gsrnamespace': '0',
    //                 'gsrlimit': '1',
    //                 'gsrsearch': name,
    //               },
    //             ),
    //           );
    //           final explanation =
    //               Map.castFrom(json.decode(response.body)).values;
    //           if (explanation.length > 1) {
    //             List.from(explanation).forEach(
    //               (el) {
    //                 if (el.runtimeType != String) {
    //                   final boom = Map.castFrom(el);
    //                   if (boom.containsKey('pages')) {
    //                     final String tree = Map.castFrom(
    //                         Map.castFrom(boom['pages']).values.first)['title'];
    //                     print(tree);
    //                     if (tree.isTreeName(treeDict)) {
    //                       treeNames.add(tree);
    //                     }
    //                   }
    //                 }
    //               },
    //             );
    //           }
    //         },
    //       );
    //     } else {
    //       print('null array cannot be iterated!');
    //     }
    //   } on Exception catch (e) {
    //     print("Fetch failed!");
    //     isTreeNameLoading = false;
    //   }
    // }
    // treeNames = treeNames.toSet().toList();
    // print(treeNames);
  }

  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: RepaintBoundary(
        key: _boundaryKey,
        child: Scaffold(
            key: _scaffoldKey,
            body: Builder(
              builder: (context) => SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    UnityWidget(
                      onUnityCreated: onUnityCreated,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: FloatingActionButton(
                        onPressed: () {
                          Scaffold.of(context).showBottomSheet<void>(
                            (BuildContext context) {
                              return Container(
                                height: 200,
                                color: Colors.white,
                                child: Center(
                                  child: CustomScrollView(
                                    slivers: [
                                      Container(
                                        child: SliverGrid(
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 5,
                                            childAspectRatio: 1.0,
                                            mainAxisSpacing: 10.0,
                                            crossAxisSpacing: 10.0,
                                          ),
                                          delegate: SliverChildBuilderDelegate(
                                            (context, index) {
                                              return InkWell(
                                                child: Image.asset(
                                                  'assets/tree${index + 1}.png',
                                                ),
                                                onTap: () {
                                                  _unityWidgetController
                                                      .postMessage(
                                                    "CubeRespawner",
                                                    "ChangeRespawnTarget",
                                                    "$index",
                                                  );
                                                },
                                              );
                                            },
                                            childCount: 9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        backgroundColor: Colors.blue,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: FloatingActionButton(
                        onPressed: () async {
                          await identify();
                        },
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ),
    );
  }

  // Callback that connects the created controller to the unity controller
  void onUnityCreated(controller) {
    this._unityWidgetController = controller;
  }
}
