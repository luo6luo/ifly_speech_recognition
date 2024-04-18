import 'dart:typed_data';

/// 移除Map中值为null的字段
Map<String, dynamic> removeNullFromMap(Map<String, dynamic> originMap,
    {bool recursive = true}) {
  Map<String, dynamic> result = {};

  originMap.forEach((key, value) {
    if (value == null) return;
    if (value is Map && recursive) {
      result[key] = removeNullFromMap(value as Map<String, dynamic>);
      return;
    }

    if (value is List && recursive) {
      result[key] = removeNullFromListItem(value, recursive: recursive);
      return;
    }

    result[key] = value;
  });
  return result;
}

/// 移除列表中各个Map项的null字段
List removeNullFromListItem(List originList, {bool recursive = true}) {
  final result = [];
  originList.forEach((item) {
    if (item == null) return;
    if (item is Map) {
      final _value =
          removeNullFromMap(item as Map<String, dynamic>, recursive: recursive);
      result.add(_value);
      return;
    }
    if (item is List && recursive) {
      final _value = removeNullFromListItem(item, recursive: recursive);
      result.add(_value);
      return;
    }

    result.add(item);
  });
  return result;
}

/// 数据流格式转换
List<int> streamFormatConversion(List<Uint8List> data) {
  List<int> bytes = data.fold<List<int>>([], (previousValue, element) {
    List<int> list = element.map((e) => e).toList();
    previousValue.addAll(list);
    return previousValue;
  });

  return bytes;
}
