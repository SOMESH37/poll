import '/src.dart';

Future<QuesData> makeRequest(pollId) async {
  final res = await dio
      .get('${Meta.baseUrl}/api/user/${Storage.getDeviceId}/poll/$pollId/');
  return QuesData.fromMap(res.data);
}

final fetch =
    FutureProvider.autoDispose.family<QuesData, dynamic>((ref, pollId) async {
  ref.watch(reFetch);
  return await makeRequest(pollId);
});
final reFetch = StateProvider<void>((r) {});

final getQues =
    FutureProvider.autoDispose.family<Ques, dynamic>((ref, quesId) async {
  ref.watch(reGetQues);
  final res = await dio
      .get('${Meta.baseUrl}/api/user/${Storage.getDeviceId}/quiz/$quesId/');
  return Ques.fromMap(res.data);
});
final reGetQues = StateProvider<void>((r) {});

Future<QuesData?> vote(quesId, optionIndex) async {
  try {
    final res = await dio.post(
      '${Meta.baseUrl}/api/user/${Storage.getDeviceId}/quiz/$quesId/vote/$optionIndex/',
      data: jsonEncode({"version": "${Meta.version}"}),
    );
    if (res.statusCode == 200)
      return QuesData.fromMap(res.data['data']);
    else
      return null;
  } catch (e) {
    return null;
  }
}

class QuesData {
  QuesData({
    required this.pollId,
    required this.pollCode,
    required this.ques,
  });

  int pollId;
  String pollCode;
  List<Ques> ques;

  factory QuesData.fromMap(Map<String, dynamic> json) => QuesData(
        pollId: json["id"],
        pollCode: json["poll_code"],
        ques: List<Ques>.from(json["questions"].map((x) => Ques.fromMap(x))),
      );
}

class Ques {
  Ques({
    required this.quesId,
    this.question,
    required this.options,
    this.raw,
    this.image,
    required this.totalVotes,
    required this.totalDiscussion,
    this.correctOption,
  });

  int quesId;
  String? question;
  List<Option> options;
  String? raw;
  String? image;
  int totalVotes;
  int totalDiscussion;
  int? correctOption;

  factory Ques.fromMap(Map<String, dynamic> map) {
    final _optionList =
        List<Option>.from(map['options'].map((x) => Option.fromMap(x)));
    int _totalVotes = 0;
    _optionList.forEach((e) => _totalVotes += e.votes);
    return Ques(
      quesId: map['id'],
      question: map['question'].toString().trim(),
      options: _optionList,
      raw: map['raw_question'],
      image: map['image'],
      totalVotes: _totalVotes,
      totalDiscussion: map['discussion'],
      correctOption: map['correct_answer'],
    );
  }
}

class Option {
  Option({
    required this.votes,
    required this.text,
    required this.voted,
  });
  int votes;
  String text;
  bool voted;

  factory Option.fromMap(Map<String, dynamic> map) {
    return Option(
      votes: map['votes'],
      text: map['text'].toString().trim(),
      voted: map['voted'],
    );
  }
}
