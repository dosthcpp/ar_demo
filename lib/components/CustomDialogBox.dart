import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class CustomDialogBox extends StatefulWidget {
  final List<String> treeNames, treeExpl;

  CustomDialogBox({
    this.treeNames,
    this.treeExpl,
  });

  @override
  _CustomDialogBoxState createState() => _CustomDialogBoxState();
}

class _CustomDialogBoxState extends State<CustomDialogBox> {
  List<Offstage> stackList = [];
  int curIdx = 0;

  contentBox(context, idx) {
    return Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    if (curIdx < stackList.length - 1) {
                      setState(() {
                        curIdx++;
                      });
                    }
                  },
                  child: Icon(
                    Icons.arrow_back,
                  ),
                ),
                Text(
                  widget.treeNames[idx],
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                InkWell(
                  onTap: () {
                    if (curIdx > 0) {
                      setState(() {
                        curIdx--;
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
                data: widget.treeExpl[idx],
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
    );
  }

  @override
  void initState() {
    Future.delayed(
      Duration.zero,
      () {
        for (var i = 0; i < widget.treeNames.length; ++i) {
          stackList.add(
            Offstage(
              offstage: curIdx != i,
              child: TickerMode(
                enabled: curIdx == i,
                child: contentBox(context, i),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20.0,
        ),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Stack(
        children: stackList,
      ),
    );
  }
}
