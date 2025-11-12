import 'dart:typed_data';
import 'package:objectbox/objectbox.dart';

@Entity()
class CapturedNote {
  @Id()
  int id;
  DateTime createdAt;
  @Property(type: PropertyType.byteVector)
  Uint8List? imageBytes;
  String title;
  String course;
  String? textContent;

  CapturedNote({
    this.id = 0,
    required this.createdAt,
    required this.title,
    required this.course,
    this.imageBytes,
    this.textContent,
  });

  CapturedNote copyWith({
    int? id,
    DateTime? createdAt,
    Uint8List? imageBytes,
    String? title,
    String? course,
    String? textContent,
  }) {
    return CapturedNote(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      imageBytes: imageBytes ?? this.imageBytes,
      title: title ?? this.title,
      course: course ?? this.course,
      textContent: textContent ?? this.textContent,
    );
  }
}
