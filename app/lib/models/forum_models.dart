import 'package:flutter/foundation.dart';

DateTime parseForumDateTime(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

class ForumCourse {
  final int courseId;
  final String courseCode;
  final String courseName;
  final String? description;

  const ForumCourse({
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.description,
  });

  factory ForumCourse.fromJson(Map<String, dynamic> json) {
    return ForumCourse(
      courseId: (json['course_id'] as num).toInt(),
      courseCode: (json['course_code'] ?? '').toString(),
      courseName: (json['course_name'] ?? '').toString(),
      description: json['description']?.toString(),
    );
  }
}

class ForumThread {
  final String threadId;
  final String userId;
  final int courseId;
  final String title;
  final String content;
  final DateTime createdAt;

  /// Filled by the service (by joining/fetching profiles + courses).
  final String? authorUsername;

  /// Filled by the service.
  final String? courseCode;

  const ForumThread({
    required this.threadId,
    required this.userId,
    required this.courseId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.authorUsername,
    this.courseCode,
  });

  factory ForumThread.fromJson(Map<String, dynamic> json) {
    return ForumThread(
      threadId: (json['thread_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      courseId: (json['course_id'] as num).toInt(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: parseForumDateTime(json['created_at']),
    );
  }

  ForumThread copyWith({
    String? authorUsername,
    String? courseCode,
  }) {
    return ForumThread(
      threadId: threadId,
      userId: userId,
      courseId: courseId,
      title: title,
      content: content,
      createdAt: createdAt,
      authorUsername: authorUsername ?? this.authorUsername,
      courseCode: courseCode ?? this.courseCode,
    );
  }
}

class ForumComment {
  final String commentId;
  final String threadId;
  final String userId;
  final String? parentCommentId;
  final String content;
  final DateTime createdAt;

  /// Filled by the service.
  final String? authorUsername;

  const ForumComment({
    required this.commentId,
    required this.threadId,
    required this.userId,
    required this.parentCommentId,
    required this.content,
    required this.createdAt,
    this.authorUsername,
  });

  factory ForumComment.fromJson(Map<String, dynamic> json) {
    final parent = json['parent_comment_id'];
    return ForumComment(
      commentId: (json['comment_id'] ?? '').toString(),
      threadId: (json['thread_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      parentCommentId: parent?.toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: parseForumDateTime(json['created_at']),
    );
  }

  ForumComment copyWith({String? authorUsername}) {
    return ForumComment(
      commentId: commentId,
      threadId: threadId,
      userId: userId,
      parentCommentId: parentCommentId,
      content: content,
      createdAt: createdAt,
      authorUsername: authorUsername ?? this.authorUsername,
    );
  }
}

@immutable
class CommentNode {
  final ForumComment comment;
  final List<CommentNode> children;

  const CommentNode({required this.comment, required this.children});
}

List<CommentNode> buildCommentTree(List<ForumComment> comments) {
  // Stable: sort first by creation time (ascending).
  final sorted = List<ForumComment>.from(comments)
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  final byId = <String, ForumComment>{};
  for (final c in sorted) {
    byId[c.commentId] = c;
  }

  final childrenByParent = <String?, List<ForumComment>>{};
  for (final c in sorted) {
    final parentKey = c.parentCommentId;
    childrenByParent.putIfAbsent(parentKey, () => <ForumComment>[]).add(c);
  }

  List<CommentNode> build(String? parentId) {
    final kids = childrenByParent[parentId] ?? const <ForumComment>[];
    return kids.map((k) {
      return CommentNode(
        comment: byId[k.commentId]!,
        children: build(k.commentId),
      );
    }).toList();
  }

  return build(null);
}

