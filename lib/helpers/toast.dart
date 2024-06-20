import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastHelper {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void show(String message) {
    message = message.trimRight();
    double maxHeight =
        MediaQuery.of(scaffoldMessengerKey.currentContext!).size.height * 0.2;
    final SnackBar snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.down,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15))),
      padding: EdgeInsets.all(2),
      backgroundColor: Colors.grey[500],
      content:
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
          ),
          child: SingleChildScrollView(
              controller: ScrollController(),
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 15, right: 15, top: 15, bottom: 5),
                child:
                    Text(message, style: const TextStyle(color: Colors.white)),
              )),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Clipboard.setData(ClipboardData(text: message));
                },
                tooltip: "Copy",
                icon: Icon(
                  CupertinoIcons.doc_on_clipboard,
                  color: Colors.white,
                )),
          ],
        ),
      ]),
      duration: const Duration(minutes: 5),
      closeIconColor: Colors.white,
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      scaffoldMessengerKey.currentState?.clearSnackBars();
      scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
    });
  }
}
