import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mongo_mate/schemas/selectable.dart';
import 'package:mongo_mate/utilities/documentStringifier.dart';

enum ExpandableType { array, obj }

class ExpandableColumn extends StatefulWidget {
  final List<Widget> values;
  final ExpandableType expandableType;
  final Widget field;
  final EdgeInsets padding;

  const ExpandableColumn(
      this.field, this.expandableType, this.padding, this.values,
      {super.key});

  @override
  State<StatefulWidget> createState() => ExpandableColumnState();
}

class ExpandableColumnState extends State<ExpandableColumn> {
  bool isExpanded = false;

  void onPressed() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  List<Widget> childrens() {
    List<Widget> result = <Widget>[];
    result.add(GestureDetector(
      onTap: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          widget.field,
          Text(widget.expandableType == ExpandableType.array
              ? 'Array'
              : 'Object'),
          Icon(isExpanded ? Icons.expand_more : Icons.keyboard_arrow_right,
              size: 18)
        ],
      ),
    ));
    if (isExpanded) {
      result.addAll(widget.values);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: childrens(),
    );
  }
}

class SingleDocument extends StatefulWidget {
  final Function(int, SelectType) onClick;
  final int index;
  final bool hasAnySelected;
  final Selectable<Map<String, dynamic>> selectable;
  final dynamic showDetails;
  final dynamic showDetailsHandler;

  const SingleDocument(this.index, this.selectable, this.hasAnySelected,
      this.onClick, this.showDetails, this.showDetailsHandler,
      {super.key});

  @override
  State<SingleDocument> createState() => _SingleDocumentState();
}

class _SingleDocumentState extends State<SingleDocument> {
  Widget generate(int level, String key, dynamic value) {
    var pad = EdgeInsets.only(left: level * 10);
    if (value is Iterable<dynamic>) {
      List<Widget> fields = <Widget>[];
      for (int i = 0; i < value.length; i++) {
        fields.add(generate(level + 1, '$i', value.elementAt(i)));
      }
      return ExpandableColumn(
          Padding(
              padding: pad,
              child: Text('$key: ',
                  style: const TextStyle(fontWeight: FontWeight.w800))),
          ExpandableType.array,
          pad,
          fields);
    } else if (value is Map<String, dynamic>) {
      List<Widget> fields = <Widget>[];
      for (var subKey in value.keys) {
        fields.add(generate(level + 1, subKey, value[subKey]));
      }
      return ExpandableColumn(
          Padding(
            padding: pad,
            child: Text('$key: ',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          ExpandableType.obj,
          pad,
          fields);
    } else {
      return Padding(
          padding: pad,
          child: Text.rich(
            TextSpan(
              children: <TextSpan>[
                TextSpan(
                    text: '$key: ',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                TextSpan(text: DocumentStringifier.stringify(value)),
              ],
            ),
          ));
    }
  }

  Widget visualize() {
    List<Widget> fields = <Widget>[];
    for (var key in widget.selectable.item.keys) {
      if (key != '_id') {
        fields.add(generate(0, key, widget.selectable.item[key]));
      }
    }
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: fields);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: widget.selectable.isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onInverseSurface,
          borderRadius: const BorderRadius.all(Radius.circular(15))),
      child: ListTile(
        selected: widget.selectable.isSelected,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15))),
        selectedColor: Theme.of(context).colorScheme.onPrimary,
        dense: true,
        onTap: () => widget.onClick(widget.index, SelectType.navigate),
        onLongPress: () => widget.onClick(widget.index, SelectType.longPress),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.doc_text_fill,
                  color: widget.selectable.isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.inverseSurface),
              const SizedBox(width: 3, height: 1),
              Text(widget.selectable.item['_id'].toString()),
              const Spacer(),
              widget.selectable.isSelected
                  ? Icon(CupertinoIcons.check_mark_circled_solid,
                      color: Theme.of(context).colorScheme.onPrimary)
                  : (widget.hasAnySelected
                      ? Icon(CupertinoIcons.circle,
                          color: Theme.of(context).colorScheme.inverseSurface)
                      : Container())
            ],
          ),
        ),
        subtitle: Visibility(visible: widget.showDetails, child: visualize()),
      ),
    );
  }
}
