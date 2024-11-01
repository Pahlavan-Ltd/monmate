import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:mongo_mate/helpers/mongo.dart';
import 'package:mongo_mate/helpers/toast.dart';
import 'package:mongo_mate/schemas/selectable.dart';
import 'package:mongo_mate/screens/editor.dart';
import 'package:mongo_mate/utilities/jsonconverter.dart';
import 'package:mongo_mate/widgets/confirmDialog.dart';
import 'package:mongo_mate/widgets/singleDocument.dart';

class DocumentScreen extends StatefulWidget {
  final dynamic name;
  const DocumentScreen({super.key, required this.name});

  @override
  _DocumentState createState() => _DocumentState();
}

class _DocumentState extends State<DocumentScreen> {
  final TextEditingController _filterQueryController = TextEditingController();
  final TextEditingController _sortQueryController = TextEditingController();
  bool isLoading = true;
  bool showDetails = false;
  static const _pageSize = 20;
  final PagingController<int, Selectable<Map<String, dynamic>>>
      _pagingController = PagingController(firstPageKey: 0);
  final ScrollController _scrollController = ScrollController();
  double offset = 0.0;
  bool refreshRequired = false;

  showDetailsHandler() {
    HapticFeedback.mediumImpact();
    setState(() {
      showDetails = !showDetails;
    });
  }

  Future<void> navigate(int index) async {
    HapticFeedback.mediumImpact();
    dynamic shouldRefresh = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditorScreen(
                collectionName: widget.name,
                item: (index == -1
                    ? null
                    : _pagingController.itemList!.elementAt(index).item),
                itemId: (index == -1
                    ? null
                    : _pagingController.itemList!
                        .elementAt(index)
                        .item['_id']))));
    refreshRequired = shouldRefresh is bool && shouldRefresh;
    if (refreshRequired) {
      offset = _scrollController.offset;
      _pagingController.refresh();
    }
  }

  void select(int index, SelectType type) {
    if (_pagingController.itemList == null ||
        _pagingController.itemList!.isEmpty) {
      return;
    }
    if (type == SelectType.tap) {
      if (_pagingController.itemList!.any((element) => element.isSelected)) {
        setState(() {
          _pagingController.itemList!.elementAt(index).select();
        });
      }
    } else if (type == SelectType.navigate) {
      if (_pagingController.itemList!.any((element) => element.isSelected)) {
        setState(() {
          _pagingController.itemList!.elementAt(index).select();
        });
      } else {
        HapticFeedback.lightImpact();
        navigate(index);
      }
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _pagingController.itemList!.elementAt(index).select();
      });
    }
  }

  bool isAnySelected() {
    if (_pagingController.itemList != null) {
      return _pagingController.itemList!.any((element) => element.isSelected);
    }
    return false;
  }

  Future<void> getDocuments(int page) async {
    try {
      final newItems = (await MongoHelper()
              .find(widget.name, page, _pageSize, filter(), sort()))
          .map((e) => Selectable(e))
          .toList();
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = page + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  Future<void> deleteHandler() async {
    HapticFeedback.mediumImpact();
    bool? delete = await showDialog(
        context: context,
        builder: (ctx) {
          return ConfirmDialog().build(context, 'Delete Document(s)',
              'Are you sure you want to delete?', 'Cancel', 'Delete');
        });
    if (delete == true) {
      setState(() {
        isLoading = true;
      });
      Iterable<Future<bool>> futures = _pagingController.itemList!
          .where((element) => element.isSelected)
          .map((q) => MongoHelper().deleteRecord(widget.name, q.item['_id']));
      await Future.wait(futures);
      setState(() {
        isLoading = false;
      });
      _pagingController.refresh();
    } else {
      setState(() {
        for (var element in _pagingController.itemList!) {
          element.isSelected = false;
        }
      });
    }
  }

  Map<String, dynamic>? filter() {
    try {
      if (_filterQueryController.value.text.isEmpty) {
        return null;
      }
      return JsonConverter.decode(_filterQueryController.value.text);
    } catch (e) {
      ToastHelper.show("Invalid Filter Query: $e");
      return {};
    }
  }

  Map<String, Object>? sort() {
    try {
      if (_sortQueryController.value.text.isEmpty) {
        return null;
      }
      return Map<String, Object>.from(
          JsonConverter.decode(_sortQueryController.value.text) as Map);
    } catch (e) {
      ToastHelper.show("Invalid Sort Query: $e");
      return {};
    }
  }

  Future<void> sortHelper() async {
    HapticFeedback.mediumImpact();
    await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Sort'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 0,
                  child: TextField(
                      controller: _sortQueryController,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        hintText: 'e.g {"age": "\$asc" or "\$desc"}',
                      )),
                )
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    _pagingController.refresh();
                    Navigator.pop(context);
                  },
                  child: const Text('Apply')),
            ],
          );
        });
  }

  Future<void> searchHelper() async {
    HapticFeedback.mediumImpact();
    await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Query'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 0,
                  child: TextField(
                      controller: _filterQueryController,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        hintText: 'e.g {"name": "john"} {"\$operator"}',
                      )),
                )
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    _pagingController.refresh();
                    Navigator.pop(context);
                  },
                  child: const Text('Apply')),
            ],
          );
        });
  }

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      getDocuments(pageKey);
    });
    _pagingController.addStatusListener((status) {
      setState(() {
        isLoading = status == PagingStatus.loadingFirstPage;
        if (refreshRequired && status == PagingStatus.completed) {
          _scrollController.jumpTo(offset);
          refreshRequired = false;
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
              onPressed: showDetailsHandler,
              icon: showDetails
                  ? const Icon(CupertinoIcons.eye_slash)
                  : const Icon(CupertinoIcons.eye)),
          IconButton(
              onPressed: sortHelper,
              icon:
                  const Icon(CupertinoIcons.line_horizontal_3_decrease_circle)),
          IconButton(
              onPressed: searchHelper, icon: const Icon(CupertinoIcons.search)),
          isAnySelected()
              ? IconButton(
                  onPressed: deleteHandler,
                  icon: const Icon(CupertinoIcons.delete))
              : IconButton(
                  onPressed: () => navigate(-1),
                  icon: const Icon(CupertinoIcons.add)),
        ],
      ),
      body: Center(
        child: RefreshIndicator(
            onRefresh: () async => {_pagingController.refresh()},
            child: CupertinoScrollbar(
                controller: _scrollController,
                child: PagedListView<int,
                    Selectable<Map<String, dynamic>>>.separated(
                  pagingController: _pagingController,
                  scrollController: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  builderDelegate: PagedChildBuilderDelegate<
                          Selectable<Map<String, dynamic>>>(
                      firstPageProgressIndicatorBuilder: (context) =>
                          const Center(
                            child: Text('Loading.'),
                          ),
                      noItemsFoundIndicatorBuilder: (context) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.doc,
                                  size: 100,
                                  color: CupertinoColors.inactiveGray,
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Text('No document found'),
                              ],
                            ),
                          ),
                      itemBuilder: (context, data, index) {
                        return SingleDocument(index, data, isAnySelected(),
                            select, showDetails, showDetailsHandler);
                      }),
                ))),
      ),
    );
  }
}
