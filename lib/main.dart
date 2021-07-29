import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'src.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    String? _id;
    await Storage.init();
    _id = Storage.getDeviceId;
    if (_id == null) {
      if (Platform.isAndroid) {
        final build = await DeviceInfoPlugin().androidInfo;
        _id = build.androidId;
      } else if (Platform.isLinux) {
        final build = await DeviceInfoPlugin().linuxInfo;
        _id = build.machineId;
      } else {
        _id = await PlatformDeviceId.getDeviceId;
      }
      if (_id?.isEmpty ?? true) _id = 'no_device_id';
      Storage.setDeviceId = _id!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (over) {
          over.disallowGlow();
          return false;
        },
        child: MaterialApp(
          // navigatorKey: alice.getNavigatorKey(),
          title: 'Polls',
          home: FutureBuilder(
            future: init(),
            builder: (cxt, snap) {
              dimensions = MediaQuery.of(cxt).size;
              switch (snap.connectionState) {
                case ConnectionState.done:
                  return Home();
                default:
                  return const FullscreenLoading();
              }
            },
          ),
        ),
      ),
    );
  }
}
