class MyModel {
  static MyModel fromJson(Map<String, dynamic> json) => MyModel();
}
void main() {
  dynamic data = [ {"a": 1} ];
  List res = data.map((json) => MyModel.fromJson(json)).toList();
  print(res is List<MyModel>);
}
