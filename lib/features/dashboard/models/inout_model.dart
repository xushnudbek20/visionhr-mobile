class InOutModel {
  final int? id;
  final String type; // 'in' or 'out'
  final String createdAt;
  final String? photo;
  final String? comment;

  InOutModel({
    this.id,
    required this.type,
    required this.createdAt,
    this.photo,
    this.comment,
  });

  factory InOutModel.fromJson(Map<String, dynamic> json) {
    return InOutModel(
      id: json['id'],
      type: json['type'],
      createdAt: json['created_at'],
      photo: json['photo'],
      comment: json['comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'created_at': createdAt,
      'photo': photo,
      'comment': comment,
    };
  }
}
