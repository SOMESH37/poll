import 'data.dart';
import '/src.dart';

const _correctAnsText = 'Correct answer';

class Question extends StatefulWidget {
  final pollId;

  const Question(this.pollId);
  static Route<PageRoute> route(pollId) =>
      CupertinoPageRoute(builder: (_) => Question(pollId));

  @override
  _QuestionState createState() => _QuestionState();
}

class _QuestionState extends State<Question> {
  final control = TextEditingController();
  bool loading = false;
  var allQues = <Ques>[];
  List<Ques>? searchList;

  void request() async {
    setState(() => loading = true);
    allQues = (await makeRequest(widget.pollId)).ques;
    search();
  }

  void castVote(quesId, int option) async {
    setState(() => loading = true);
    await vote(quesId, option).then((v) {
      if (v != null)
        allQues = v.ques;
      else
        'Error! Try again'.toast(context);
    });
    search();
  }

  void search([_]) {
    final text = control.text.toLowerCase();
    var _temp = <Ques>[];
    int _quesLen = 0, _optionLen = 0, _correctLen = 0, _rawLen = 0;
    for (var i in allQues) {
      if (i.question?.toLowerCase().contains(text) ?? false) {
        _temp.insert(_quesLen, i);
        _quesLen++;
        continue;
      }
      var _foundInOptions = false;
      for (var j in i.options) {
        if (j.text.toLowerCase().contains(text)) {
          _temp.insert(_quesLen + _optionLen, i);
          _optionLen++;
          _foundInOptions = true;
          break;
        }
      }
      if (_foundInOptions) continue;
      if (i.correctOption != null &&
          _correctAnsText.toLowerCase().contains(text)) {
        _temp.insert(_quesLen + _optionLen + _correctLen, i);
        _correctLen++;
        continue;
      }
      if (i.raw?.toLowerCase().contains(text) ?? false) {
        _temp.insert(_quesLen + _optionLen + _correctLen + _rawLen, i);
        _rawLen++;
        continue;
      }
    }
    if (_temp != searchList)
      setState(() {
        loading = false;
        searchList = _temp;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          child: LinearProgressIndicator(
            value: loading ? null : 1,
            minHeight: 3,
            color: Colors.grey.shade300,
            backgroundColor: Colors.blue,
          ),
          preferredSize: Size(double.infinity, 3),
        ),
        automaticallyImplyLeading: false,
        leading: BackButton(
          color: Colors.grey,
          onPressed: () {
            if (control.text.isNotEmpty) {
              control.clear();
              search();
            } else if (MediaQuery.of(context).viewInsets.bottom > 0)
              FocusScope.of(context).unfocus();
            else
              Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              request();
            },
            color: Colors.grey,
            icon: Icon(Icons.refresh),
          ),
        ],
        title: TextField(
          onChanged: search,
          autofocus: false,
          controller: control,
          decoration: InputDecoration.collapsed(
            hintText: 'Search for questions or options',
          ),
          keyboardType: TextInputType.text,
        ),
      ),
      body: Center(
        child: Consumer(
          builder: (ctx, watch, _) {
            final future = watch(fetch(widget.pollId));
            return future.when(
                data: (data) {
                  allQues = data.ques;
                  if (searchList == null) searchList = allQues;
                  return data.ques.isEmpty
                      ? 'No question available'.body
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  'Total match found : '.subtitle,
                                  '${searchList!.length}'.subtitle,
                                ],
                              ),
                            ),
                            const Divider(
                              endIndent: 120,
                              indent: 120,
                              height: 0,
                            ),
                            Expanded(
                              child: searchList!.isEmpty
                                  ? Center(child: 'Nothing found'.body)
                                  : Scrollbar(
                                      child: ListView.builder(
                                        itemCount: searchList!.length,
                                        itemBuilder: (_, i) {
                                          searchList![i].totalVotes = 0;
                                          searchList![i].options.forEach((e) {
                                            searchList![i].totalVotes +=
                                                e.votes;
                                          });
                                          return QuesTile(
                                            ques: searchList![i],
                                            searchText: control.text,
                                            onVote: castVote,
                                          );
                                        },
                                      ),
                                    ),
                            ),
                          ],
                        );
                },
                loading: () => CircularProgressIndicator(),
                error: (_, __) =>
                    Retry(() => context.read(reFetch).state = '_'));
          },
        ),
      ),
    );
  }
}

class QuesTile extends StatelessWidget {
  const QuesTile({
    required this.ques,
    required this.searchText,
    required this.onVote,
  });
  final Ques ques;
  final String searchText;
  final void Function(dynamic, int) onVote;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                ques.question!.copy
                    .then((v) => v ? 'Question copied!'.toast(context) : null);
              },
              child: Row(
                children: [
                  Expanded(
                    child:
                        Highlight('Q) ${ques.question}'.boldBody, searchText),
                  ),
                  Column(
                    children: [
                      if (ques.question?.isNotEmpty ?? false)
                        IconButton(
                          onPressed: () {
                            ques.question!.openUrl(true).then((v) => v
                                ? null
                                : 'Error! Ques copied instead😅️'
                                    .toast(context));
                          },
                          icon: Icon(Icons.public_rounded),
                          color: Colors.blue.shade300,
                        ),
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(CupertinoIcons.chat_bubble_2),
                            color: Colors.blue,
                            onPressed: () => Navigator.of(context)
                                .push(Discuss.route(ques.quesId)),
                          ),
                          if (ques.totalDiscussion > 0)
                            Positioned(
                              top: 10,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  ques.totalDiscussion.toString(),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.blueAccent),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (ques.correctOption != null &&
                ques.correctOption! <= ques.options.length)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(
                    endIndent: 40,
                    indent: 40,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Highlight('$_correctAnsText '.boldBody, searchText),
                            VerifiedIcon(),
                          ],
                        ),
                        '${ques.options[ques.correctOption!]}'.body,
                      ],
                    ),
                  ),
                ],
              ),
            if (ques.image != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(
                    endIndent: 40,
                    indent: 40,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            backgroundColor: Colors.black54,
                            body: Stack(
                              children: [
                                Center(
                                  child: InteractiveViewer(
                                    maxScale: 6,
                                    clipBehavior: Clip.none,
                                    child: Image.network(ques.image!),
                                  ),
                                ),
                                SafeArea(
                                  child: BackButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Center(
                      child: Image.network(
                        ques.image!,
                        height: 200,
                      ),
                    ),
                  ),
                ],
              ),
            const Divider(
              endIndent: 40,
              indent: 40,
            ),
            ...List.generate(
              ques.options.length,
              (idx) {
                final _percentage = (ques.options[idx].votes == 0 ||
                        ques.totalVotes == 0)
                    ? 0
                    : (ques.options[idx].votes / ques.totalVotes * 100).floor();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                ques.options[idx].text.copy.then((v) =>
                                    v ? 'Option copied!'.toast(context) : null);
                              },
                              child: Highlight(
                                  '${ques.options[idx].text}'.body, searchText),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 2, 0, 0),
                                  child:
                                      '$_percentage% | ${ques.options[idx].votes} votes'
                                          .subtitle,
                                ),
                                if (Storage.getIsPercentage ?? false)
                                  FractionallySizedBox(
                                    widthFactor: _percentage / 100,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: LinearProgressIndicator(
                                        minHeight: 4,
                                        value: 1,
                                        backgroundColor: Colors.transparent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          primary: ques.options[idx].voted
                              ? Colors.redAccent
                              : Colors.greenAccent.shade400,
                          backgroundColor: ques.options[idx].voted
                              ? Colors.redAccent.withOpacity(0.04)
                              : Colors.greenAccent.withOpacity(0.1),
                        ),
                        child: Text(
                            '${ques.options[idx].voted ? 'Retract' : 'Vote'}'),
                        onPressed: () => onVote(ques.quesId, idx),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
