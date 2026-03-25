import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/forum_models.dart';

class ForumSupabaseService {
  final SupabaseClient supabase;
  final String bucketName;

  ForumSupabaseService({
    SupabaseClient? supabaseClient,
    this.bucketName = 'forum_file',
  }) : supabase = supabaseClient ?? Supabase.instance.client;

  String _uuidV4() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));

    // Version 4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Variant 10
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String two(int b) => b.toRadixString(16).padLeft(2, '0');
    return '${two(bytes[0])}${two(bytes[1])}${two(bytes[2])}${two(bytes[3])}-'
        '${two(bytes[4])}${two(bytes[5])}-'
        '${two(bytes[6])}${two(bytes[7])}-'
        '${two(bytes[8])}${two(bytes[9])}-'
        '${two(bytes[10])}${two(bytes[11])}${two(bytes[12])}${two(bytes[13])}${two(bytes[14])}${two(bytes[15])}';
  }

  Future<List<ForumCourse>> fetchCourses() async {
    final rows = await supabase
        .from('course')
        .select('course_id,course_code,course_name,description');
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ForumCourse.fromJson)
        .toList();
  }

  Future<Map<String, String>> _fetchUsernamesByIds(List<String> userIds) async {
    if (userIds.isEmpty) return const <String, String>{};
    final rows = await supabase
        .from('profiles')
        .select('user_id,username')
        .inFilter('user_id', userIds);
    return {
      for (final row in rows.whereType<Map<String, dynamic>>())
        row['user_id'].toString(): row['username'].toString(),
    };
  }

  Future<Map<int, String>> _fetchCourseCodesByIds(List<int> courseIds) async {
    if (courseIds.isEmpty) return const <int, String>{};
    final rows = await supabase
        .from('course')
        .select('course_id,course_code')
        .inFilter('course_id', courseIds);
    return {
      for (final row in rows.whereType<Map<String, dynamic>>())
        (row['course_id'] as num).toInt(): row['course_code'].toString(),
    };
  }

  Future<List<ForumThread>> fetchThreads({
    int? courseId,
    String? searchQuery,
    int limit = 50,
  }) async {
    dynamic query = supabase
        .from('thread')
        .select('thread_id,user_id,course_id,title,content,created_at');

    if (courseId != null) {
      query = query.eq('course_id', courseId);
    }
    final q = searchQuery?.trim();
    if (q != null && q.isNotEmpty) {
      query = query.ilike('title', '%$q%');
    }

    final rows = await query.order('created_at', ascending: false).limit(limit);
    final threads = (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ForumThread.fromJson)
        .toList();

    final userIds = threads.map((t) => t.userId).toSet().toList();
    final courseIds = threads.map((t) => t.courseId).toSet().toList();
    final usernames = await _fetchUsernamesByIds(userIds);
    final courseCodes = await _fetchCourseCodesByIds(courseIds);

    return threads
        .map((t) => t.copyWith(
              authorUsername: usernames[t.userId],
              courseCode: courseCodes[t.courseId],
            ))
        .toList();
  }

  Future<ForumThread> fetchThreadDetail(String threadId) async {
    final row = await supabase
        .from('thread')
        .select(
          'thread_id,user_id,course_id,title,content,created_at',
        )
        .eq('thread_id', threadId)
        .maybeSingle();
    if (row == null) {
      throw Exception('Thread not found: $threadId');
    }

    final thread = ForumThread.fromJson(row);

    final usernames = await _fetchUsernamesByIds(<String>[thread.userId]);
    final courseCodes = await _fetchCourseCodesByIds(<int>[thread.courseId]);

    return thread.copyWith(
      authorUsername: usernames[thread.userId],
      courseCode: courseCodes[thread.courseId],
    );
  }

  Future<List<ForumComment>> fetchComments(String threadId) async {
    final rows = await supabase
        .from('comment')
        .select(
          'comment_id,thread_id,user_id,parent_comment_id,content,created_at',
        )
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);
    final comments = (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ForumComment.fromJson)
        .toList();

    final userIds = comments.map((c) => c.userId).toSet().toList();
    final usernames = await _fetchUsernamesByIds(userIds);

    return comments.map((c) => c.copyWith(authorUsername: usernames[c.userId])).toList();
  }

  Future<String> createThread({
    required int courseId,
    required String title,
    required String content,
    required String userId,
  }) async {
    final threadId = _uuidV4();
    await supabase.from('thread').insert({
      'thread_id': threadId,
      'user_id': userId,
      'course_id': courseId,
      'title': title,
      'content': content,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    return threadId;
  }

  Future<void> deleteThread(String threadId) async {
    await supabase.from('thread').delete().eq('thread_id', threadId);
  }

  Future<void> createComment({
    required String threadId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    await supabase.from('comment').insert({
      'comment_id': _uuidV4(),
      'thread_id': threadId,
      'user_id': userId,
      'parent_comment_id': parentCommentId,
      'content': content,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

}

