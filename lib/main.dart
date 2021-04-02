import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

void main() {
  runApp(MaterialApp(home: UnityDemoScreen()));
}

class UnityDemoScreen extends StatefulWidget {
  UnityDemoScreen({Key key}) : super(key: key);

  @override
  _UnityDemoScreenState createState() => _UnityDemoScreenState();
}

class _UnityDemoScreenState extends State<UnityDemoScreen> {
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();
  UnityWidgetController _unityWidgetController;

  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Builder(
        builder: (context) => SafeArea(
          bottom: false,
          child: WillPopScope(
            onWillPop: () async => false,
            child: Stack(
              children: [
                Container(
                  child: UnityWidget(
                    onUnityCreated: onUnityCreated,
                  ),
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
              ],
            ),
          ),
        ),
      )
    );
  }

  // Callback that connects the created controller to the unity controller
  void onUnityCreated(controller) {
    this._unityWidgetController = controller;
  }
}
