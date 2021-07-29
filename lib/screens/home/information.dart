import 'package:share_plus/share_plus.dart';
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
  bool _switch = Storage.getIsPercentage ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          SwitchListTile(
            title: 'Show percentage indicator below each option'.body,
            value: _switch,
            onChanged: (v) {
              setState(() {
                _switch = !_switch;
                Storage.setIsPercentage = _switch;
              });
            },
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
                  'Tips\n'.body,
                  widget.data.tips!.txt(
                    color: Colors.grey,
                    align: TextAlign.center,
                  ),
                ],
              ),
            ),
          Spacer(),
        ],
      ),
    );
  }
}
