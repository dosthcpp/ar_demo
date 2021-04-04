import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io' show File, Directory;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:ar_demo/api.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';
import 'package:path_provider/path_provider.dart' as pp;

const kMainColor = 0xff62b27c;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
  List<String> treeExplanation = [];
  String imageData = '';
  int curIdx = 0;
  int flag = 0;
  int recognizeTree = 0, readQR = 1;

  @override
  void initState() {
    loadDic();
  }

  void loadDic() async {
    treeDict = (await rootBundle.loadString('assets/treename.txt')).split('\n');
  }

  Future<void> setFlag(_flag) async {
    flag = _flag;
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
                    onUnityMessage: onUnityMessage,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: FloatingActionButton(
                      onPressed: () async {
                        setFlag(recognizeTree).then((_) {
                          _unityWidgetController.postMessage(
                            "AR Session Origin",
                            "sendImage",
                            "",
                          );
                        });
                        // await identify();
                      },
                      backgroundColor: Color(kMainColor),
                      child: Image.asset(
                        'assets/treeicon.png',
                        width: 30.0,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 60.0,
                    child: FloatingActionButton(
                      child: Image.asset(
                        'assets/select.png',
                        width: 30.0,
                      ),
                      onPressed: () {
                        Scaffold.of(context).showBottomSheet<void>(
                          (BuildContext context) {
                            return Container(
                              height: 200,
                              color: Colors.white,
                              child: Center(
                                child: CustomScrollView(
                                  slivers: [
                                    SliverToBoxAdapter(
                                      child: Align(
                                        child: InkWell(
                                          child: Container(
                                            child: Icon(
                                              Icons.close,
                                            ),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                        alignment: Alignment.centerRight,
                                      ),
                                    ),
                                    SliverToBoxAdapter(
                                      child: SizedBox(
                                        height: 10.0,
                                      )
                                    ),
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
                                                  "Respawner",
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
                      backgroundColor: Color(kMainColor),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 120.0,
                    child: FloatingActionButton(
                      onPressed: () async {
                        setFlag(readQR).then((_) {
                          _unityWidgetController.postMessage(
                            "AR Session Origin",
                            "sendImage",
                            "",
                          );
                        });
                      },
                      backgroundColor: Color(kMainColor),
                      child: Image.asset(
                        'assets/qr-code.png',
                        width: 30.0,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Visibility(
                        visible: isTreeNameLoading,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Callback that connects the created controller to the unity controller
  void onUnityCreated(controller) {
    this._unityWidgetController = controller;
  }

  Future<List<String>> search(message) async {
    treeNames.clear();
    final response = await http.post(
      Uri.https('api.plant.id', '/v2/identify'),
      headers: {"Content-Type": "application/json", "Api-Key": apiKey},
      body: jsonEncode(
        {
          "images": [message.toString()],
          "modifiers": ["similar_images"],
          "plant_details": [
            "common_names",
            "url",
            "wiki_description",
            "taxonomy"
          ]
        },
      ),
    );
    final suggestions = json.decode(response.body)['suggestions'];
    for (var i = 0; i < suggestions.length; ++i) {
      final xml2json = Xml2Json();
      final _res = await http.get(
        Uri.http(
          'openapi.nature.go.kr',
          '/openapi/service/rest/PlantService/plntIlstrSearch',
          {
            'serviceKey': treeSearchApiKey,
            'st': '2',
            'sw': suggestions[i]['plant_name'],
            'dateGbn': '',
            'dateFrom': '',
            'numOfRows': '10',
            'pageNo': '1',
          },
        ),
      );
      xml2json.parse(utf8.decode(_res.bodyBytes));
      final data =
          json.decode(xml2json.toBadgerfish())['response']['body']['items'];
      if (data.length > 0) {
        for (var item in Map.castFrom(data).values) {
          try {
            for (var _item in item) {
              treeNames.add(Map.from(_item['plantGnrlNm']).values.elementAt(0));
            }
          } catch (e) {
            treeNames.add(
                Map.from(Map.from(item)['plantGnrlNm']).values.elementAt(0));
          }
        }
      }
      try {
        final _suggestions = suggestions[i]['plant_details']['common_names'];
        if (_suggestions != null && _suggestions.length > 0) {
          for (var name in _suggestions) {
            final response = await http.get(
              Uri.https(
                'ko.wikipedia.org',
                '/w/api.php',
                {
                  'action': 'query',
                  'prop': 'extracts',
                  'origin': '*',
                  'format': 'json',
                  'generator': 'search',
                  'gsrnamespace': '0',
                  'gsrlimit': '1',
                  'gsrsearch': name,
                },
              ),
            );
            final explanation = Map.castFrom(json.decode(response.body)).values;
            if (explanation.length > 1) {
              for (var el in explanation) {
                if (el.runtimeType != String) {
                  final boom = Map.castFrom(el);
                  if (boom.containsKey('pages')) {
                    final Map gatheredInfo =
                        Map.castFrom(Map.castFrom(boom['pages']).values.first);
                    if ((gatheredInfo['title'] as String)
                        .isTreeName(treeDict)) {
                      treeNames.add(gatheredInfo['title']);
                    }
                  }
                }
              }
            }
          }
        } else {
          print('null array cannot be iterated!');
        }
      } on Exception catch (e) {
        print("Fetch failed!");
        isTreeNameLoading = false;
      }
    }
    return treeNames.toSet().toList();
  }

  Future<List<String>> postSearch(names) async {
    treeExplanation.clear();
    for (var name in names) {
      final response = await http.get(
        Uri.https(
          'ko.wikipedia.org',
          '/w/api.php',
          {
            'action': 'query',
            'prop': 'extracts',
            'origin': '*',
            'format': 'json',
            'generator': 'search',
            'gsrnamespace': '0',
            'gsrlimit': '1',
            'gsrsearch': name,
          },
        ),
      );
      final explanation = Map.castFrom(json.decode(response.body)).values;
      if (explanation.length > 1) {
        final searchList = List.from(explanation);
        String found;
        var i = 0;
        for (; i < searchList.length; ++i) {
          found = '';
          if (searchList[i].runtimeType != String) {
            final boom = Map.castFrom(searchList[i]);
            if (boom.containsKey('pages')) {
              final gatheredInfo =
                  Map.castFrom(Map.castFrom(boom['pages']).values.first);
              if (gatheredInfo['title'] == name) {
                found = gatheredInfo['extract'];
                break;
              }
            }
          }
        }
        if (i < searchList.length) {
          treeExplanation.add(found);
        } else {
          treeExplanation.add('검색결과 없음');
        }
      } else {
        treeExplanation.add('검색결과 없음');
      }
    }
    return treeExplanation;
  }

  void onUnityMessage(message) async {
    if(flag == recognizeTree) {
      setState(() {
        isTreeNameLoading = true;
      });
      final names = await search(message);
      final explanations = await postSearch(names);
      if (names.length > 0 && explanations.length > 0) {
        showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      20.0,
                    ),
                  ),
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemBuilder: (context, idx) {
                      return Offstage(
                        offstage: curIdx != idx,
                        child: TickerMode(
                          enabled: curIdx == idx,
                          child: Container(
                            height: MediaQuery.of(context).size.height / 10 * 6.5,
                            padding: EdgeInsets.all(
                              20.0,
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                20.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  offset: Offset(0, 5),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          if (curIdx > 0) {
                                            setState(() {
                                              curIdx--;
                                            });
                                          }
                                        },
                                        child: Icon(
                                          Icons.arrow_back,
                                        ),
                                      ),
                                      Text(
                                        names[idx],
                                        style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          if (curIdx < names.length - 1) {
                                            setState(() {
                                              curIdx++;
                                            });
                                          }
                                        },
                                        child: Icon(
                                          Icons.arrow_forward,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 10,
                                  child: SingleChildScrollView(
                                    child: Html(
                                      data: explanations[idx],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                        "확인",
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    itemCount: names.length,
                  ),
                );
              },
            );
          },
        );
      }
      setState(() {
        isTreeNameLoading = false;
      });
    } else if(flag == readQR) {
      try {
        final Directory directory = await pp.getApplicationDocumentsDirectory();
        final file = File('${directory.path}/temp.jpg');
        final decodedBytes = base64Decode(message.toString());
        file.writeAsBytesSync(decodedBytes);
        final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(file);
        final _vision = FirebaseVision.instance;
        final BarcodeDetector barcodeDetector = _vision.barcodeDetector();
        final List<Barcode> barcodes = await barcodeDetector.detectInImage(visionImage);
        for (Barcode barcode in barcodes) {

          final String rawValue = barcode.rawValue;

          final BarcodeValueType valueType = barcode.valueType;

          // See API reference for complete list of supported types
          switch (valueType) {
            case BarcodeValueType.wifi:
              final String ssid = barcode.wifi.ssid;
              final String password = barcode.wifi.password;
              final BarcodeWiFiEncryptionType type = barcode.wifi.encryptionType;
              print("$ssid, $password, $type");
              break;
            case BarcodeValueType.url:
              final String title = barcode.url.title;
              final String url = barcode.url.url;
              print("$title $url");
              break;
            default:
              break;
          }
        }
      } catch(e) {
        print(e);
      }
    }
  }
}
