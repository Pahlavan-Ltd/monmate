import 'dart:convert';

import 'package:mongo_mate/utilities/jsonhelpers/datetimejsonhelper.dart';
import 'package:mongo_mate/utilities/jsonhelpers/decimaljsonhelper.dart';
import 'package:mongo_mate/utilities/jsonhelpers/doublejsonhelper.dart';
import 'package:mongo_mate/utilities/jsonhelpers/longjsonhelper.dart';
import 'package:mongo_mate/utilities/jsonhelpers/objectidjsonhelper.dart';
import 'package:mongo_mate/utilities/jsonhelpers/rationaljsonhelper.dart';
import 'package:mongo_mate/utilities/jsonhelpers/uuidjsonhelper.dart';

import 'jsonhelpers/abstractjsonhelper.dart';
import 'jsonhelpers/bsonbinaryjsonhelper.dart';
import 'jsonhelpers/sortqueryjsonhelper.dart';

encodeHelper(dynamic value) {
  for (var helper in JsonConverter.helpers) {
    if (helper.isEncodable(value)) {
      return helper.encode(value);
    }
  }
  return value;
}

decodeHelper(dynamic key, dynamic value) {
  value = value is String ? value.trim() : value;
  for (var helper in JsonConverter.helpers) {
    if (helper.isDecodable(value)) {
      return helper.decode(value);
    }
  }
  return value;
}

class JsonConverter {
  static List<AbstractJsonHelper> helpers = List.unmodifiable([
    ObjectIdJsonHelper(),
    DateTimeJsonHelper(),
    UUIDJsonHelper(),
    DecimalJsonHelper(),
    RationalJsonHelper(),
    DoubleJsonHelper(),
    LongJsonHelper(),
    BsonBinaryJsonHelper(),
    SortQueryHelper(),
  ]);

  static String encode(dynamic object) {
    return const JsonEncoder.withIndent('   ', encodeHelper)
        .convert(object)
        .toString();
  }

  static dynamic decode(String json) {
    return const JsonDecoder(decodeHelper).convert(json);
  }
}
