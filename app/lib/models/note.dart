class Note {
  final int id;
  final String title;
  final String course;
  final String date;
  final String content;

  const Note({
    required this.id,
    required this.title,
    required this.course,
    required this.date,
    required this.content,
  });

  Note copyWith({
    int? id,
    String? title,
    String? course,
    String? date,
    String? content,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      course: course ?? this.course,
      date: date ?? this.date,
      content: content ?? this.content,
    );
  }
}


