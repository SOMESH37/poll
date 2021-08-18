import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
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
  var bannerAds = <AdWithView?>[];

  void loadAds() async {
    bannerAds.clear();
    for (var i = 0; i < allQues.length; i++) {
      final _temp = i % 3 == 0
          ? BannerAd(
              size: AdSize(height: 50, width: dimensions.width.toInt()),
              adUnitId: AdState.bannerAdUnitId!,
              listener: BannerAdListener(),
              request: AdRequest(),
            )
          : null;
      await _temp?.load();
      bannerAds.add(_temp);
    }
    if (mounted) setState(() {});
  }

  void request() async {
    setState(() => loading = true);
    allQues = (await makeRequest(widget.pollId)).ques;
    loadAds();
    search();
  }

  void castVote(quesId, int option) async {
    'Thank you 😄️'.toast(context);
    setState(() => loading = true);
    await vote(quesId, option).then((v) {
      if (v != null) {
        allQues = v.ques;
        loadAds();
      } else {
        'Error! Try again'.toast(context);
      }
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
              hintText: 'Search for questions or options'),
          keyboardType: TextInputType.text,
        ),
      ),
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Consumer(
          builder: (ctx, watch, _) {
            final future = watch(fetch(widget.pollId));
            return future.when(
                data: (data) {
                  if (searchList == null) {
                    allQues = data.ques;
                    searchList = allQues;
                    loadAds();
                  }
                  return allQues.isEmpty
                      ? 'No question available'.body
                      : searchList!.isEmpty
                          ? Center(child: 'Nothing found'.body)
                          : SafeArea(
                              top: false,
                              child: Scrollbar(
                                child: ListView.builder(
                                  itemCount: searchList!.length + 1,
                                  itemBuilder: (_, i) => i == 0
                                      ? Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 16),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              'Total match found : '.subtitle,
                                              '${searchList!.length}'.subtitle,
                                            ],
                                          ),
                                        )
                                      : QuesTile(
                                          ques: searchList![i - 1],
                                          searchText: control.text,
                                          onVote: castVote,
                                          ad: i > bannerAds.length ||
                                                  bannerAds[i - 1] == null
                                              ? const SizedBox.shrink()
                                              : SizedBox(
                                                  height: 50,
                                                  child: AdWidget(
                                                      ad: bannerAds[i - 1]!),
                                                ),
                                        ),
                                ),
                              ),
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

class SingleQuesPage extends StatefulWidget {
  const SingleQuesPage(this.quesId);
  final quesId;
  static Route<PageRoute> route(quesId) =>
      CupertinoPageRoute(builder: (_) => SingleQuesPage(quesId));

  @override
  _SingleQuesPageState createState() => _SingleQuesPageState();
}

class _SingleQuesPageState extends State<SingleQuesPage> {
  var _loading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.grey),
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          child: LinearProgressIndicator(
            value: _loading ? null : 1,
            minHeight: 3,
            color: Colors.grey.shade300,
            backgroundColor: Colors.blue,
          ),
          preferredSize: Size(double.infinity, 3),
        ),
      ),
      body: Consumer(
        builder: (_, watch, __) {
          final fut = watch(getQues(widget.quesId));
          return fut.when(
            loading: () => const FullScreenLoading(),
            error: (_, __) =>
                Center(child: Retry(() => context.read(reGetQues).state = '_')),
            data: (quesData) => SingleChildScrollView(
              child: QuesTile(
                  ad: MyBannerAd(),
                  ques: quesData,
                  searchText: '',
                  onVote: (quesId, int option) async {
                    'Thank you 😄️'.toast(context);
                    setState(() => _loading = true);
                    await vote(quesId, option).then((v) {
                      if (v != null)
                        context.read(reGetQues).state = '_';
                      else
                        'Error! Try again'.toast(context);
                      setState(() => _loading = false);
                    });
                  }),
            ),
          );
        },
      ),
    );
  }
}

class QuesTile extends StatelessWidget {
  QuesTile({
    required this.ques,
    required this.searchText,
    required this.onVote,
    required this.ad,
  }) : _imageHeroTag = (ques.image?.isNotEmpty ?? false) ? UniqueKey() : null;
  final Ques ques;
  final String searchText;
  final void Function(dynamic, int) onVote;
  final Widget ad;
  final UniqueKey? _imageHeroTag;
  final _repaintKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: Colors.white,
        elevation: 0,
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            RepaintBoundary(
              key: _repaintKey,
              child: Material(
                color: Colors.white,
                child: Column(
                  children: [
                    if (ques.question?.isNotEmpty ?? false)
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                ques.question!.copy.then((v) => v
                                    ? 'Question copied!'.toast(context)
                                    : null);
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  'Q) '.boldBody,
                                  Expanded(
                                    child: Highlight(
                                        ques.question!.boldBody, searchText),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(
                            endIndent: 40,
                            indent: 40,
                          ),
                        ],
                      ),
                    if (_imageHeroTag != null)
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => Material(
                                    child: Stack(
                                      children: [
                                        PhotoView.customChild(
                                          heroAttributes:
                                              PhotoViewHeroAttributes(
                                                  tag: _imageHeroTag!),
                                          maxScale: 7.0,
                                          minScale:
                                              PhotoViewComputedScale.contained,
                                          child: CachedImage(ques.image!),
                                        ),
                                        SafeArea(
                                          child: BackButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
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
                              child: Hero(
                                tag: _imageHeroTag!,
                                child: SizedBox(
                                  height: 200,
                                  child: CachedImage(ques.image!),
                                ),
                              ),
                            ),
                          ),
                          const Divider(
                            endIndent: 40,
                            indent: 40,
                          ),
                        ],
                      ),
                    if (ques.correctOption != null &&
                        ques.correctOption! <= ques.options.length)
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Highlight('$_correctAnsText '.boldBody,
                                        searchText),
                                    const VerifiedIcon(),
                                  ],
                                ),
                                '${ques.options[ques.correctOption!].text}'
                                    .body,
                              ],
                            ),
                          ),
                          const Divider(
                            endIndent: 40,
                            indent: 40,
                          ),
                        ],
                      ),
                    ...List.generate(
                      ques.options.length,
                      (idx) {
                        final _percentage = (ques.options[idx].votes == 0 ||
                                ques.totalVotes == 0)
                            ? 0
                            : (ques.options[idx].votes / ques.totalVotes * 100)
                                .floor();
                        return Padding(
                          padding: EdgeInsets.fromLTRB(16, 6, 0, 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    ques.options[idx].text.copy.then((v) => v
                                        ? 'Option ${idx + 1} copied!'
                                            .toast(context)
                                        : null);
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Highlight(
                                          '${ques.options[idx].text}'.body,
                                          searchText),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 2, 0, 2),
                                        child:
                                            '$_percentage% | ${ques.options[idx].votes} votes'
                                                .subtitle,
                                      ),
                                      if (Storage.getIsPercentage)
                                        FractionallySizedBox(
                                          widthFactor: _percentage / 100,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: LinearProgressIndicator(
                                              minHeight: 4,
                                              value: 1,
                                              backgroundColor:
                                                  Colors.transparent,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Checkbox(
                                value: ques.options[idx].voted,
                                onChanged: (_) => onVote(ques.quesId, idx),
                                shape: CircleBorder(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            ad,
            Column(
              children: [
                const Divider(
                  endIndent: 40,
                  indent: 40,
                  height: 4,
                ),
                Row(
                  children: List.generate(
                    4,
                    (i) => (i == 2 && (ques.question?.isEmpty ?? true))
                        ? const SizedBox.shrink()
                        : Expanded(
                            child: IconButton(
                              onPressed: () {
                                var _temp = [];
                                ques.options.forEach((e) => _temp.add(e.text));
                                final _fullQues =
                                    '${ques.question} ${_temp.join(' ')}';
                                switch (i) {
                                  case 0:
                                    'Please wait'.toast(context);
                                    final _link =
                                        'https://pollapp.dev/${Meta.version}/question/${ques.quesId}';
                                    if (Storage.getShareImg) {
                                      convertWidgetToImage(_repaintKey)
                                          .then((v) async {
                                        if (v == null)
                                          throw ErrorHint(
                                              'path cannot be null');
                                        Share.shareFiles(
                                          [v],
                                          text: _link,
                                          subject: 'Poll app',
                                        );
                                      }).catchError((_) {
                                        _link.copy.then((v) => v
                                            ? 'Link copied!'.toast(context)
                                            : null);
                                      });
                                    } else {
                                      Share.share(_link).catchError((_) {
                                        _link.copy.then((v) => v
                                            ? 'Link copied!'.toast(context)
                                            : null);
                                      });
                                    }
                                    break;
                                  case 1:
                                    _fullQues.copy.then((v) => v
                                        ? 'Question and options copied!'
                                            .toast(context)
                                        : null);
                                    break;
                                  case 2:
                                    final _query = Storage.getWebSearchQues
                                        ? ques.question!
                                        : _fullQues;
                                    _query.openUrl(true).then((v) => v
                                        ? null
                                        : 'Error! Question copied instead😅️'
                                            .toast(context));
                                    break;
                                  case 3:
                                    Navigator.of(context)
                                        .push(Discuss.route(ques.quesId));
                                    break;
                                }
                              },
                              color: Colors.blue.shade300,
                              tooltip: i == 0
                                  ? 'Share question'
                                  : i == 1
                                      ? 'Copy all'
                                      : i == 2
                                          ? 'Web search'
                                          : 'Discuss',
                              icon: Stack(
                                children: [
                                  Icon(i == 0
                                      ? CupertinoIcons.share
                                      : i == 1
                                          ? Icons.copy_rounded
                                          : i == 2
                                              ? Icons.public_rounded
                                              : CupertinoIcons.chat_bubble_2),
                                  if (i == 3 && ques.totalDiscussion > 0)
                                    Positioned(
                                      top: -1,
                                      right: 0,
                                      child: Container(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 2),
                                        decoration:
                                            BoxDecoration(color: Colors.white),
                                        child: Text(
                                          '${ques.totalDiscussion}',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MyBannerAd extends StatelessWidget {
  const MyBannerAd([this.height = 60]);
  final double height;
  @override
  Widget build(BuildContext context) {
    try {
      return SizedBox(
        height: height,
        child: AdWidget(
          ad: BannerAd(
            size:
                AdSize(height: height.toInt(), width: dimensions.width.toInt()),
            adUnitId: AdState.bannerAdUnitId!,
            listener: BannerAdListener(),
            request: AdRequest(),
          )..load(),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
