import '/src.dart';
import 'data.dart';

class Discuss extends StatefulWidget {
  final quesId;
  const Discuss(this.quesId);
  static Route<PageRoute> route(quesId) =>
      CupertinoPageRoute(builder: (_) => Discuss(quesId));
  @override
  _DiscussState createState() => _DiscussState();
}

class _DiscussState extends State<Discuss> {
  String text = '';
  bool loading = false;
  List<Comment>? allDiscuss;
  var con = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.grey,
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          child: LinearProgressIndicator(
            value: loading ? null : 1,
            backgroundColor: Colors.blue,
            color: Colors.grey.shade300,
            minHeight: 3,
          ),
          preferredSize: Size(double.infinity, 3),
        ),
        automaticallyImplyLeading: false,
        title: Text(
          'Discussion',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Center(
        child: Consumer(
          builder: (ctx, watch, _) {
            final future = watch(fetch(widget.quesId));
            return future.when(
                data: (data) {
                  if (allDiscuss != null) data = allDiscuss!;
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          itemCount: data.length,
                          reverse: true,
                          separatorBuilder: (_, i) => const Divider(
                            endIndent: 40,
                            indent: 40,
                            height: 24,
                          ),
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                          itemBuilder: (context, i) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  data[i].user.title,
                                  if (data[i].isTrusted) const VerifiedIcon(),
                                  '  (${data[i].time.read})'.subtitle,
                                ],
                              ),
                              if (!data[i].isTrusted) const SizedBox(height: 2),
                              Linkify(
                                text: data[i].chat,
                                onOpen: (link) => link.url.openUrl().then((v) =>
                                    v
                                        ? null
                                        : 'Error! Link copied instead😅️'
                                            .toast(context)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      LinearProgressIndicator(
                        value: 1,
                        valueColor:
                            AlwaysStoppedAnimation(Colors.grey.shade300),
                        minHeight: 1,
                      ),
                      TextField(
                        maxLines: 8,
                        minLines: 1,
                        controller: con,
                        style: Theme.of(context).textTheme.bodyText2,
                        onChanged: (value) {
                          value = value.trim();
                          if (text.isEmpty ^ value.isEmpty) setState(() {});
                          text = value;
                        },
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          suffixIcon: TextButton(
                            child: Icon(
                              Icons.send_rounded,
                              size: 26,
                            ),
                            onPressed: text.isEmpty || loading
                                ? null
                                : () {
                                    if (data.length > 100) {
                                      'Discussion is disabled'.toast(context);
                                      return;
                                    }
                                    FocusScope.of(context).unfocus();
                                    setState(() => loading = true);
                                    comment(widget.quesId, text).then((v) {
                                      if (v != null) {
                                        text = '';
                                        con.clear();
                                        allDiscuss = v;
                                        setState(() => loading = false);
                                      } else {
                                        'Try again'.toast(context);
                                      }
                                    });
                                  },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          hintText: 'Add a comment',
                          border: InputBorder.none,
                        ),
                        textAlignVertical: TextAlignVertical.center,
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
