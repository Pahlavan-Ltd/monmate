import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mongo_mate/schemas/collection.dart';
import 'package:mongo_mate/schemas/selectable.dart';

class SingleCollection extends StatelessWidget {
  final Function(int, SelectType) onClick;
  final int index;
  final bool isAnySelected;
  final Selectable<Collection> selectable;

  const SingleCollection(
      {super.key,
      required this.index,
      required this.selectable,
      required this.isAnySelected,
      required this.onClick});

  String getDocumentText() {
    switch (selectable.item.count) {
      case -2:
        {
          return '...';
        }
      case -1:
        {
          return '!';
        }
      case 0:
        {
          return '0';
        }
      case 1:
        {
          return '1';
        }
      default:
        {
          return '${selectable.item.count}';
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selectable.isSelected,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15))),
      tileColor: Theme.of(context).colorScheme.onInverseSurface,
      selectedTileColor: Theme.of(context).colorScheme.primary,
      selectedColor: Theme.of(context).colorScheme.onPrimary,
      onTap: () => onClick(index, SelectType.tap),
      onLongPress: () => onClick(index, SelectType.longPress),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(CupertinoIcons.folder,
              color: selectable.isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.inverseSurface),
          const SizedBox(width: 5, height: 1),
          Flexible(
              child: Text(selectable.item.name,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1))
        ],
      ),
      subtitle: Row(
        children: [
          Text(getDocumentText()),
          Icon(
            CupertinoIcons.doc_fill,
            size: 11,
          )
        ],
      ),
      trailing: selectable.isSelected
          ? const Icon(CupertinoIcons.check_mark_circled_solid)
          : (isAnySelected ? const Icon(CupertinoIcons.circle) : null),
    );
  }
}
