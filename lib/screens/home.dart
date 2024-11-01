import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mongo_mate/helpers/mongo.dart';
import 'package:mongo_mate/helpers/storage.dart';
import 'package:mongo_mate/helpers/toast.dart';
import 'package:mongo_mate/schemas/connection.dart';
import 'package:mongo_mate/schemas/selectable.dart';
import 'package:mongo_mate/screens/collection.dart';
import 'package:mongo_mate/widgets/adBanner.dart';
import 'package:mongo_mate/widgets/adNative.dart';
import 'package:mongo_mate/widgets/confirmDialog.dart';
import 'package:mongo_mate/widgets/singleConnection.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = false;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _uri = TextEditingController();
  List<Selectable<Connection>> connections = <Selectable<Connection>>[];

  Future<void> saveConnections() async {
    String json =
        jsonEncode(connections.map((connection) => connection.item).toList());
    StorageHelper().write('connections', json);
  }

  void reorderHandler(int oldIndex, int newIndex) {
    // If either oldIndex or newIndex is 1, do not allow reordering involving the ad
    if (oldIndex == 0 || newIndex == 0) {
      return;
    }

    setState(() {
      // Adjust indices for the ad's presence
      if (oldIndex > 0) oldIndex -= 1;
      if (newIndex > 0) newIndex -= 1;

      newIndex -= oldIndex < newIndex ? 1 : 0;

      final Selectable<Connection> item = connections.removeAt(oldIndex);
      connections.insert(newIndex, item);
    });

    saveConnections();
  }

  Future<void> connectAndGo(int index) async {
    final navigator = Navigator.of(context);
    setState(() {
      isLoading = true;
    });
    bool connected = await MongoHelper()
        .connect(connections[index].item.getConnectionString());
    setState(() {
      isLoading = false;
    });
    if (connected) {
      HapticFeedback.lightImpact();
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                CollectionScreen(name: connections[index].item.name)),
      );
    }
  }

  void add(String name, String uri) {
    if (name.isNotEmpty && uri.isNotEmpty) {
      setState(() {
        connections.add(Selectable(Connection(name, uri)));
      });
      saveConnections();
    }
  }

  void update(int index, String name, String uri) {
    if (index >= 0 &&
        connections.length > index &&
        name.isNotEmpty &&
        uri.isNotEmpty) {
      setState(() {
        connections[index] = Selectable(Connection(name, uri));
      });
      saveConnections();
    }
  }

  void select(int index, SelectType type) {
    // if (isLoading) {
    //   return;
    // }
    if (type == SelectType.tap) {
      if (connections.any((element) => element.isSelected)) {
        setState(() {
          connections[index].select();
        });
      } else {
        connectAndGo(index);
      }
    } else {
      setState(() {
        HapticFeedback.mediumImpact();
        connections[index].select();
      });
    }
  }

  Future<void> openUrl(url) async {
    if (!await launchUrl(url)) {
      ToastHelper.show('Could not launch $url');
    }
  }

  Future<void> deleteHandler() async {
    HapticFeedback.mediumImpact();
    bool? delete = await showDialog(
        context: context,
        builder: (ctx) {
          return ConfirmDialog().build(context, 'Delete Connection(s)',
              'Are you sure you want to delete?', 'Cancel', 'Delete');
        });
    if (delete == true) {
      setState(() {
        connections.removeWhere((element) => element.isSelected);
      });
      saveConnections();
    } else {
      setState(() {
        for (var element in connections) {
          element.isSelected = false;
        }
      });
    }
  }

  Future<void> manageHandler(BuildContext context, String mode) async {
    int index = -1;
    _name.clear();
    _uri.clear();

    if (mode == "edit") {
      for (int i = 0; i < connections.length; i++) {
        if (connections[i].isSelected) {
          index = i;
          _name.text = connections[i].item.name;
          _uri.text = connections[i].item.uri;
          break;
        }
      }
    }

    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Track whether fields are empty
            bool isNameEmpty = _name.text.isEmpty;
            bool isUriEmpty = _uri.text.isEmpty;

            return SafeArea(
              child: Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mode == "add" ? 'Add Connection' : 'Edit Connection',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: 10.0),
                    TextField(
                      controller: _name,
                      decoration: InputDecoration(
                          labelText: "Label",
                          hintText: "e.g MonMate Instance 1"),
                      textInputAction: TextInputAction.next,
                      onChanged: (value) {
                        // Update the state when text changes
                        setState(() {});
                      },
                    ),
                    SizedBox(height: 10.0),
                    TextField(
                      controller: _uri,
                      decoration: InputDecoration(
                          labelText: "URI",
                          helperText: "e.g mongodb+srv://user:pass@url/dbname"),
                      textInputAction: TextInputAction.done,
                      onChanged: (value) {
                        // Update the state when text changes
                        setState(() {});
                      },
                    ),
                    SizedBox(height: 10.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                        SizedBox(width: 10.0),
                        ElevatedButton(
                          // Disable button if either field is empty
                          onPressed: isNameEmpty || isUriEmpty
                              ? null
                              : () {
                                  if (mode == "add") {
                                    add(_name.text, _uri.text);
                                  } else {
                                    update(index, _name.text, _uri.text);
                                  }
                                  Navigator.pop(context);
                                  _uri.clear();
                                  _name.clear();
                                },
                          child: Text(mode == "add" ? 'Add' : 'Edit'),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (index >= 0) {
      setState(() {
        connections[index].isSelected = false;
      });
    }
  }

  Future<void> manageAbout(BuildContext context) async {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Container(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('MonMate'),
                        const Text('Version 1.0.2'),
                        const Text('© 2024'),
                        const SizedBox(height: 10.0),
                        Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  openUrl(Uri.parse(
                                      'https://pahlavan.co.uk/monmate'));
                                },
                                icon: const Icon(CupertinoIcons.globe)),
                            IconButton(
                                onPressed: () {
                                  ConsentForm.showPrivacyOptionsForm(
                                      (formError) {
                                    if (formError != null) {
                                      debugPrint(
                                          "${formError.errorCode}: ${formError.message}");
                                    }
                                  });
                                },
                                icon: const Icon(CupertinoIcons.lock_circle)),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> getConnections() async {
    String? data = await StorageHelper().read('connections');
    if (data == null) {
      return;
    }
    List<dynamic> savedConnections = jsonDecode(data);
    setState(() {
      connections = savedConnections
          .map((e) => Selectable(Connection.fromJson(e)))
          .toList(growable: true);
    });
  }

  @override
  void initState() {
    super.initState();
    getConnections();
  }

  @override
  Widget build(BuildContext context) {
    int selectedCount =
        connections.where((element) => element.isSelected).length;

    return Scaffold(
      appBar: AppBar(
          title: Row(
            children: [
              IconButton(
                onPressed: () => manageAbout(context),
                icon: const Icon(CupertinoIcons.cube_box_fill),
              ),
              Visibility(
                visible: isLoading,
                child: Center(
                    child: SizedBox(
                        child: CircularProgressIndicator(),
                        width: 25,
                        height: 25)),
              ),
            ],
          ),
          actions: [
            (selectedCount == 0)
                ? IconButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      manageHandler(context, "add");
                    },
                    icon: const Icon(CupertinoIcons.add))
                : (selectedCount == 1)
                    ? IconButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          manageHandler(context, "edit");
                        },
                        icon: const Icon(CupertinoIcons.pencil))
                    : Container(),
            (selectedCount > 0)
                ? IconButton(
                    onPressed: deleteHandler,
                    icon: const Icon(CupertinoIcons.delete))
                : Container()
          ]),
      //  CupertinoNavigationBar(
      //     middle: const Text('MongoMate'),
      //     trailing: (selectedCount == 0)
      //         ? IconButton(
      //             onPressed: () => manageHandler(context, "add"),
      //             icon: const Icon(CupertinoIcons.add))
      //         : (selectedCount == 1)
      //             ? IconButton(
      //                 onPressed: () => manageHandler(context, "edit"),
      //                 icon: const Icon(CupertinoIcons.pencil))
      //             : IconButton(
      //                 onPressed: () {},
      //                 icon: const Icon(CupertinoIcons.delete))),
      body: connections.isEmpty
          ? const Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.cube_box,
                  color: CupertinoColors.systemGrey,
                  size: 100,
                ),
                SizedBox(height: 20),
                Text('Add your first MongoDB deployment'),
              ],
            ))
          :
          // isLoading
          //     ? const Center(child: CircularProgressIndicator())
          //     :
          Padding(
              padding: const EdgeInsets.all(12.0),
              child: ReorderableListView(
                onReorder: reorderHandler,
                children: List<Widget>.generate(
                  connections.length + 1, // Add 1 for the ad
                  (index) {
                    if (index == 0) {
                      // Insert your ad widget here
                      // return NativeAdWidget(
                      //     key:
                      //         UniqueKey()); // Replace AdWidget with your actual ad widget
                      return AdBanner(
                        key: UniqueKey(),
                      );
                    } else {
                      // Subtract 1 from index if ad is inserted before index 1
                      var adjustedIndex = index > 0 ? index - 1 : index;
                      return SingleConnection(
                        adjustedIndex,
                        connections[adjustedIndex],
                        connections.any((q) => q.isSelected),
                        (i, t) => select(i, t),
                        key: UniqueKey(),
                      );
                    }
                  },
                ),
              ),
            ),
    );
  }
}
