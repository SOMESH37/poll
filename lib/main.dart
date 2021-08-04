import 'package:device_info_plus/device_info_plus.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'src.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp();
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
      } else if (Platform.isWindows) {
        _id = await PlatformDeviceId.getDeviceId;
      } else {
        _id = await PlatformDeviceId.getDeviceId;
      }
      if (_id?.isEmpty ?? true) _id = 'no_device_id';
      // replacing all / as it will interfere deep linking
      Storage.setDeviceId = _id!.replaceAll('/', '');
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
          // debugShowMaterialGrid: true,
          title: 'Polls',
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
