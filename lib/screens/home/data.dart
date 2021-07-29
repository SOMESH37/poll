import '/src.dart';

final requestMeta = FutureProvider.autoDispose<void>((ref) async {
  ref.watch(reReqMeta);
  final res = await dio.get(
      'https://quiz.wiztex.in/api/user/${Storage.getDeviceId}/version/${Meta.version}/');
  Meta.init(res.data);
  // Meta.baseUrl = 'https://quiz.wiztex.in';
  // Meta.baseUrl = 'https://moces.in';
});
final reReqMeta = StateProvider<void>((r) {});

final fetch = FutureProvider.autoDispose<HomeData>((ref) async {
  ref.watch(reFetch);
  final res =
      await dio.get('${Meta.baseUrl}/api/user/${Storage.getDeviceId}/poll/');
  final data = HomeData.fromJson(res.data);
  return data;
});

final reFetch = StateProvider<void>((r) {});

Future<bool> joinPoll(String pollCode) async {
  try {
    final res = await dio.post(
      '${Meta.baseUrl}/api/user/${Storage.getDeviceId}/poll/',
      data: jsonEncode({"poll_code": "$pollCode"}),
    );
    return res.statusCode == 200;
  } catch (e) {
    return false;
  }
}

class HomeData {
  HomeData({
    required this.isAdd,
    required this.isInfo,
    required this.info,
    required this.polls,
  });

  bool isAdd;
  bool isInfo;
  Info info;
  List<Poll> polls;

  factory HomeData.fromJson(Map<String, dynamic> json) => HomeData(
        isAdd: json["isAdd"],
        isInfo: json["isInfo"],
        info: Info.fromJson(json["info"]),
        polls: List<Poll>.from(json["poll"].map((x) => Poll.fromJson(x))),
      );
}

class Info {
  Info({
    required this.tips,
    this.telegram,
  });

  String? tips;
  String? telegram;

  factory Info.fromJson(Map<String, dynamic> json) => Info(
        tips: json["tips"],
        telegram: json["telegram"],
      );
}

class Poll {
  Poll({
    required this.id,
    required this.title,
    required this.pollCode,
    this.pollDetails,
    required this.totalQuestions,
  });

  int id;
  String pollCode;
  String title;
  String? pollDetails;
  int totalQuestions;

  factory Poll.fromJson(Map<String, dynamic> json) => Poll(
        id: json["id"],
        pollCode: json["poll_code"],
        title: json["poll_title"],
        pollDetails: json["poll_details"],
        totalQuestions: json["total_questions"],
      );
}
