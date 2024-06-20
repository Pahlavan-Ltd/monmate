import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mongo_mate/helpers/mongo.dart';
import 'package:mongo_mate/helpers/toast.dart';
import 'package:mongo_mate/utilities/jsonconverter.dart';
import 'package:mongo_mate/widgets/confirmDialog.dart';

class EditorScreen extends StatefulWidget {
  final String collectionName;
  final dynamic itemId;
  final dynamic item;
  EditorScreen({Key? key, required this.collectionName, this.itemId, this.item})
      : super(key: key);

  @override
  _EditState createState() => _EditState();
}

String jsonEncode(dynamic item) {
  return JsonConverter.encode(item);
}

dynamic jsonDecode(String json) {
  return JsonConverter.decode(json);
}

class _EditState extends State<EditorScreen> {
  bool isLoading = false;
  final TextEditingController _jsonController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> encoder() async {
    try {
      String encoded = widget.itemId == null
          ? '{\n\n}'
          : await compute(jsonEncode, widget.item);
      setState(() {
        _jsonController.text = encoded;
      });
    } catch (e) {
      setState(() {
        _jsonController.text = '{\n\n}';
        ToastHelper.show("Encode Error. $e");
      });
    }
  }

  Future<void> savehandler() async {
    bool? ok = await showDialog(
        context: context,
        builder: (ctx) {
          return ConfirmDialog().build(context, 'Save document',
              'Are you sure you want to save it?', 'Cancel', 'Save');
        });
    if (ok == true) {
      await save();
    }
  }

  Future<void> save() async {
    final navigator = Navigator.of(context);
    setState(() {
      isLoading = true;
    });
    FocusManager.instance.primaryFocus?.unfocus();
    if (_jsonController.value.text.isNotEmpty) {
      try {
        dynamic obj = await compute(jsonDecode, _jsonController.value.text);
        bool result = false;
        if (widget.itemId != null) {
          //update
          obj.removeWhere((key, value) => key == '_id');
          result = await MongoHelper()
              .updateRecord(widget.collectionName, widget.itemId, obj);
        } else {
          //insert
          result = await MongoHelper().insertRecord(widget.collectionName, obj);
        }
        if (result) {
          navigator.pop(true);
        }
      } catch (e) {
        ToastHelper.show("Invalid JSON. $e");
      }
    } else {
      ToastHelper.show("Document is empty.");
    }
    setState(() {
      isLoading = false;
    });
  }

  void copy() {
    var jsonText = _jsonController.value.text;
    if (jsonText.isNotEmpty) {
      HapticFeedback.mediumImpact();
      Clipboard.setData(ClipboardData(text: jsonText));
    }
  }

  @override
  void initState() {
    super.initState();
    encoder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'New Document' : 'Edit Document'),
        actions: [
          // Visibility(
          //   visible: _jsonController.value.text.isNotEmpty,
          //   child: IconButton(
          //     onPressed: copy,
          //     icon: const Icon(Icons.copy),
          //     tooltip: 'Copy',
          //   ),
          // ),
          IconButton(
              onPressed: savehandler,
              icon: const Icon(CupertinoIcons.check_mark)),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: SizedBox(
          // height: netHeight,
          child: CupertinoScrollbar(
            controller: _scrollController,
            child: TextField(
              expands: true,
              minLines: null,
              maxLines: null,
              scrollController: _scrollController,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              scrollPhysics: const AlwaysScrollableScrollPhysics(),
              decoration: InputDecoration(
                  fillColor: Theme.of(context).colorScheme.surface,
                  filled: true,
                  border: null,
                  enabledBorder: const UnderlineInputBorder(),
                  focusedBorder: const UnderlineInputBorder(),
                  contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8)),
              controller: _jsonController,
            ),
          ),
        ),
      ),
    );
  }
}
