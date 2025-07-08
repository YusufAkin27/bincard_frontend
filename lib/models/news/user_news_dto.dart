import 'news_priority.dart';
import 'news_type.dart';

class UserNewsDTO {
  final int id;
  final String title;
  final String content;
  final String? image;
  final bool likedByUser;
  final bool viewedByUser;
  final NewsPriority priority;
  final NewsType type;
  final DateTime? createdAt;
  final String? summary;

  UserNewsDTO({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    required this.likedByUser,
    required this.viewedByUser,
    required this.priority,
    required this.type,
    this.createdAt,
    this.summary,
  });

  factory UserNewsDTO.fromJson(Map<String, dynamic> json) {
    return UserNewsDTO(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      image: json['image'],
      likedByUser: json['likedByUser'] ?? false,
      viewedByUser: json['viewedByUser'] ?? false,
      priority: NewsPriorityExtension.fromString(json['priority'] ?? 'NORMAL'),
      type: NewsTypeExtension.fromString(json['type'] ?? 'DUYURU'),
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
      summary: json['summary'],
    );
  }

  // Tarih, özet gibi ek alanlar olmadığında ekran içinde kullanmak için
  DateTime get date => createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'image': image,
      'likedByUser': likedByUser,
      'viewedByUser': viewedByUser,
      'priority': priority.toString().split('.').last,
      'type': type.toString().split('.').last,
    };
  }
}
