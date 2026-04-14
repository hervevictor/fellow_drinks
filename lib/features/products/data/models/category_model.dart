import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String? color;
  final String? icon;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    required this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id:        map['id'] as String,
        name:      map['name'] as String,
        color:     map['color'] as String?,
        icon:      map['icon'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id':         id,
        'name':       name,
        'color':      color,
        'icon':       icon,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, name, color, icon];
}

