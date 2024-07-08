import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mongo_mate/helpers/mongo.dart';
import 'package:mongo_mate/schemas/collection.dart';
import 'package:mongo_mate/schemas/selectable.dart';
import 'package:mongo_mate/screens/document.dart';
import 'package:mongo_mate/widgets/adBanner.dart';
import 'package:mongo_mate/widgets/adNative.dart';
import 'package:mongo_mate/widgets/confirmDialog.dart';
import 'package:mongo_mate/widgets/singleCollection.dart';

class CollectionScreen extends StatefulWidget {
  final String name;
  const CollectionScreen({Key? key, required this.name}) : super(key: key);

  @override
  _CollectionState createState() => _CollectionState();
}

class _CollectionState extends State<CollectionScreen> {
  bool isLoading = false;
  final TextEditingController _name = TextEditingController();
  List<Selectable<Collection>> collections = <Selectable<Collection>>[];

  Future<void> getRecordCounts() async {
    Iterable<Future<int>> futures =
        collections.map((q) => MongoHelper().getRecordCount(q.item.name));
    List<int> counts = await Future.wait(futures);
    setState(() {
      for (int i = 0; i < counts.length; i++) {
        collections[i].item.count = counts[i];
      }
    });
  }

  Future<void> getCollections() async {
    setState(() {
      isLoading = true;
    });
    var names = await MongoHelper().getCollectionNames();
    setState(() {
      collections = names.map((e) => Selectable(Collection(e))).toList();
      isLoading = false;
    });
    getRecordCounts();
  }

  void selectHandler(int index, SelectType type) {
    if (type == SelectType.tap) {
      if (collections.any((element) => element.isSelected)) {
        setState(() {
          collections[index].select();
        });
      } else {
        HapticFeedback.lightImpact();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    DocumentScreen(name: collections[index].item.name)));
      }
    } else {
      setState(() {
        HapticFeedback.mediumImpact();
        collections[index].select();
      });
    }
  }

  Future<void> create(String collectionName) async {
    setState(() {
      isLoading = true;
    });
    await MongoHelper().createCollection(collectionName);
    setState(() {
      isLoading = false;
    });
    getCollections();
  }

  Future<void> createHandler() async {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Create Collection',
                        style: Theme.of(context).textTheme.headlineMedium),
                    SizedBox(height: 10.0),
                    TextField(
                      controller: _name,
                      decoration: InputDecoration(labelText: "Name"),
                      textInputAction: TextInputAction.done,
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
                          onPressed: () {
                            create(_name.value.text);
                            Navigator.pop(context);
                            _name.clear();
                          },
                          child: Text('Create'),
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
  }

  Future<void> deleteHandler() async {
    HapticFeedback.mediumImpact();
    bool? delete = await showDialog(
        context: context,
        builder: (ctx) {
          return ConfirmDialog().build(context, 'Delete Collection(s)',
              'Are you sure you want to delete?', 'Cancel', 'Delete');
        });
    if (delete == true) {
      setState(() {
        isLoading = true;
      });
      Iterable<Future<bool>> futures = collections
          .where((element) => element.isSelected)
          .map((q) => MongoHelper().deleteCollection(q.item.name));
      await Future.wait(futures);
      setState(() {
        isLoading = false;
      });
      getCollections();
    } else {
      setState(() {
        for (var element in collections) {
          element.isSelected = false;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getCollections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          collections.any((element) => element.isSelected)
              ? IconButton(
                  onPressed: deleteHandler,
                  icon: const Icon(CupertinoIcons.delete))
              : IconButton(
                  onPressed: createHandler,
                  icon: const Icon(CupertinoIcons.add))
        ],
      ),
      body: RefreshIndicator(
        onRefresh: getCollections,
        child: collections.isEmpty
            ? const SizedBox(
                // height: netHeight,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.folder,
                        size: 100,
                        color: CupertinoColors.inactiveGray,
                      ),
                      SizedBox(height: 20),
                      Text("No collection found")
                    ],
                  ),
                ),
              )
            : CupertinoScrollbar(
                child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 15),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemCount: collections.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Insert your ad widget here
                        // return NativeAdWidget(); // Replace AdWidget with your actual ad widget
                        return AdBanner(
                          key: UniqueKey(),
                        );
                      } else {
                        var adjustedIndex = index > 0 ? index - 1 : index;
                        return SingleCollection(
                            index: adjustedIndex,
                            selectable: collections[adjustedIndex],
                            isAnySelected: collections
                                .any((element) => element.isSelected),
                            onClick: selectHandler);
                      }
                    })),
      ),
    );
  }
}
