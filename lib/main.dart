import 'package:device_info_plus/device_info_plus.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'src.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  bool _isInit = false;
  Future<void> init() async {
    if (_isInit) return;
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    await AdState.init();
    String? _id;
    await Storage.init();
    _id = Storage.getDeviceId;
    if (_id == null) {
      if (Platform.isAndroid) {
        final build = await DeviceInfoPlugin().androidInfo;
        _id = build.androidId;
      } else if (Platform.isIOS) {
        final build = await DeviceInfoPlugin().iosInfo;
        _id = build.identifierForVendor;
      } else if (Platform.isLinux) {
        final build = await DeviceInfoPlugin().linuxInfo;
        _id = build.machineId;
      } else if (Platform.isWindows) {
        _id = await PlatformDeviceId.getDeviceId;
      } else {
        _id = await PlatformDeviceId.getDeviceId;
      }
      if (_id?.isEmpty ?? true) _id = 'no_device_id';
      // replacing all / as it will interfere deep linking
      Storage.setDeviceId = _id!.replaceAll('/', '');
    }
    _isInit = true;
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
          navigatorKey: navKey,
          // debugShowMaterialGrid: true,
          title: 'Poll',
          home: FutureBuilder(
            future: init(),
            builder: (cxt, snap) {
              dimensions = MediaQuery.of(cxt).size;
              switch (snap.connectionState) {
                case ConnectionState.done:
                  return Home();
                default:
                  return const FullScreenLoading();
              }
            },
          ),
        ),
      ),
    );
  }
}
