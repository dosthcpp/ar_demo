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
      body: SafeArea(
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
                    _unityWidgetController.postMessage(
                        "AR Session Origin", "DoSomething", "hide");
                  },
                  backgroundColor: Colors.blue,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: FloatingActionButton(
                  onPressed: () {
                    _unityWidgetController.postMessage(
                        "AR Session Origin", "DoSomething", "show");
                  },
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Callback that connects the created controller to the unity controller
  void onUnityCreated(controller) {
    this._unityWidgetController = controller;
  }
}
