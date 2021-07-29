import '/src.dart';

final fetch = FutureProvider.autoDispose
    .family<List<Comment>, dynamic>((ref, quesId) async {
  ref.watch(reFetch);
  final res = await dio.get(
      '${Meta.baseUrl}/api/user/${Storage.getDeviceId}/quiz/$quesId/discussion/');
  final data = List<Comment>.from(res.data.map((x) => Comment.fromMap(x)));
  return data;
});

final reFetch = StateProvider<void>((r) {});

Future<List<Comment>?> comment(quesId, String text) async {
  try {
    var res = await dio.post(
      '${Meta.baseUrl}/api/user/${Storage.getDeviceId}/quiz/$quesId/discussion/',
      data: jsonEncode({"chat": "$text"}),
    );
    if (res.statusCode == 200)
      return List<Comment>.from(res.data.map((x) => Comment.fromMap(x)));
    else
      return null;
  } catch (_) {
    return null;
  }
}

class Comment {
  String user;
  String chat;
  DateTime time;
  bool isTrusted;
  Comment({
    required this.user,
    required this.chat,
    required this.time,
    required this.isTrusted,
  });
  factory Comment.fromMap(Map<String, dynamic> map) => Comment(
        user: map['user'],
        chat: '${map['chat']}',
        time: DateTime.parse(map['created_at']),
        isTrusted: map['trusted'],
      );
}
