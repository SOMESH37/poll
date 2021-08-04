import 'package:uni_links/uni_links.dart';
import '/src.dart';
import 'data.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, watch, __) {
        final fut = watch(requestMeta);
        return fut.when(
          loading: () => const FullScreenLoading(),
          error: (_, __) => Material(
              child: Center(
                  child: Retry(() => context.read(reReqMeta).state = '_'))),
          data: (_) => Meta.baseUrl == null ? const UpdatePage() : AllPolls(),
        );
      },
    );
  }
}

class AllPolls extends StatefulWidget {
  AllPolls();

  @override
  _AllPollsState createState() => _AllPollsState();
}

class _AllPollsState extends State<AllPolls> {
  StreamSubscription? _sub;
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _handleIncomingLinks();
      _handleInitialUri();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _pushLink(String link) {
    final _temp = link.split('/');
    if (_temp.length != 6) return;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      Navigator.of(context).push(SingleQuesPage.route(_temp.last));
    });
  }

  void _handleIncomingLinks() {
    _sub = linkStream.listen(
      (link) {
        if (link?.isNotEmpty ?? false) _pushLink(link!);
      },
      onError: (e) => debugPrint('Uni link error'),
    );
  }

  Future<void> _handleInitialUri() async {
    try {
      final link = await getInitialLink();
      if (link?.isNotEmpty ?? false) _pushLink(link!);
    } on FormatException catch (_) {
      debugPrint('Format exception');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (_, watch, __) {
      final future = watch(fetch);
      return Scaffold(
        appBar: AppBar(
          title: Text('Polls'),
          actions: future.maybeWhen(
            orElse: () => const [SizedBox.shrink()],
            data: (data) => !data.isInfo
                ? const [SizedBox.shrink()]
                : [
                    IconButton(
                      onPressed: () {
                        context.read(reFetch).state = '_';
                      },
                      icon: Icon(Icons.refresh),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(InfoPage.route(data.info));
                      },
                      icon: Icon(Icons.info_outline_rounded),
                    ),
                  ],
          ),
        ),
        body: Center(
          child: future.when(
              data: (data) => data.polls.isEmpty
                  ? 'No poll available'.body
                  : ListView.separated(
                      padding: const EdgeInsets.only(top: 8),
                      separatorBuilder: (_, i) => const Divider(
                        endIndent: 40,
                        indent: 40,
                      ),
                      itemBuilder: (_, i) => ListTile(
                        trailing: Icon(Icons.chevron_right),
                        title: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: data.polls[i].title.txt(),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            'Poll code : ${data.polls[i].pollCode}'.txt(),
                            'Total Questions : ${data.polls[i].totalQuestions}'
                                .txt(),
                            if (data.polls[i].pollDetails != null)
                              data.polls[i].pollDetails!.txt(),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context)
                              .push(Question.route(data.polls[i].id));
                        },
                      ),
                      itemCount: data.polls.length,
                    ),
              loading: () => CircularProgressIndicator(),
              error: (_, __) => Retry(() => context.read(reFetch).state = '_')),
        ),
        floatingActionButton: future.maybeWhen(
          orElse: () => const SizedBox.shrink(),
          data: (data) => !data.isAdd
              ? null
              : FloatingActionButton(
                  child: Icon(Icons.add),
                  onPressed: () {
                    bool isL = false;
                    String? code, error;
                    showDialog(
                      context: context,
                      builder: (_) => StatefulBuilder(
                        builder: (context, reset) {
                          return AbsorbPointer(
                            absorbing: isL,
                            child: AlertDialog(
                              contentPadding:
                                  EdgeInsets.fromLTRB(30, 25, 30, 25),
                              clipBehavior: Clip.hardEdge,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              buttonPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                              title: Text('Join a poll'),
                              content: TextField(
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp('[a-zA-Z0-9]'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  hintText: 'Enter unique poll code',
                                  errorText: error,
                                  helperText: '',
                                ),
                                onChanged: (value) {
                                  code = value;
                                  if (error != null)
                                    reset(() {
                                      error = null;
                                    });
                                },
                              ),
                              actions: [
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: double.maxFinite,
                                  ),
                                  child: isL
                                      ? Column(
                                          children: [
                                            const SizedBox(
                                              height: 32,
                                            ),
                                            LinearProgressIndicator(
                                              minHeight: 6,
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              child: Text(
                                                'Cancel',
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                            ),
                                            TextButton(
                                              child: Text(
                                                'Join',
                                              ),
                                              onPressed: () async {
                                                if (code == null) {
                                                  reset(() {
                                                    error = 'Enter a code';
                                                  });
                                                  return;
                                                }

                                                if (error != null) {
                                                  HapticFeedback.mediumImpact();
                                                  return;
                                                }
                                                reset(() => isL = true);
                                                FocusScope.of(context)
                                                    .unfocus();
                                                joinPoll('$code').then(
                                                  (v) {
                                                    if (v) {
                                                      Navigator.pop(context);
                                                      'Joined'.toast(context);
                                                      context
                                                          .read(reFetch)
                                                          .state = '_';
                                                    } else {
                                                      'Try again please'
                                                          .toast(context);
                                                      reset(() => isL = false);
                                                    }
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      );
    });
  }
}

class UpdatePage extends StatelessWidget {
  const UpdatePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (Meta.msg != null) Meta.msg!.txt(align: TextAlign.center),
              TextButton(
                onPressed: () {
                  Meta.tgLink!.openUrl().then((v) => v
                      ? null
                      : 'Error! Link copied instead😅️'.toast(context));
                },
                child: Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
