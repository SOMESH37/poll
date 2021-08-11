import '/src.dart';
import 'data.dart';

class InfoPage extends StatefulWidget {
  final Info data;
  const InfoPage(this.data);
  static Route<PageRoute> route(Info data) =>
      CupertinoPageRoute(builder: (_) => InfoPage(data));

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          SwitchListTile(
            title: 'Show percentage indicator below each option'.body,
            value: Storage.getIsPercentage,
            onChanged: (v) => setState(() {
              Storage.setIsPercentage = !Storage.getIsPercentage;
            }),
          ),
          SwitchListTile(
            title: 'Web search question only'.body,
            subtitle: Storage.getWebSearchQues
                ? 'Only question will be parsed as query in web search'.subtitle
                : 'Question with all its options will be parsed as query in web search'
                    .subtitle,
            value: Storage.getWebSearchQues,
            onChanged: (v) => setState(() {
              Storage.setWebSearchQues = !Storage.getWebSearchQues;
            }),
          ),
          SwitchListTile(
            title: 'Share a image of question with the link'.body,
            value: Storage.getShareImg,
            onChanged: (v) => setState(() {
              Storage.setShareImg = !Storage.getShareImg;
            }),
          ),
          if (widget.data.telegram?.isNotEmpty ?? false)
            ListTile(
              title: 'Feature request, or bug report?'.body,
              subtitle: 'Join us on telegram'.subtitle,
              trailing: TextButton(
                onPressed: () {
                  widget.data.telegram!.openUrl().then((v) => v
                      ? null
                      : 'Error! Link copied instead😅️'.toast(context));
                },
                child: Text('Join'),
              ),
            ),
          Spacer(),
          if (widget.data.tips?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.data.tips!.txt(
                    color: Colors.grey,
                    align: TextAlign.center,
                  ),
                ],
              ),
            ),
          if (widget.data.donation?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: GestureDetector(
                onTap: () {
                  widget.data.donation!.openUrl().then((v) => v
                      ? null
                      : 'Error! Link copied instead😅️'.toast(context));
                },
                child: Image.asset(
                  'asset/bmc.png',
                  height: 48,
                ),
              ),
            ),
          Spacer(),
        ],
      ),
    );
  }
}
