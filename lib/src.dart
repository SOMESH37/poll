export 'dart:convert';
export 'dart:math';
export 'dart:io';
export 'dart:async' show StreamSubscription;

export 'package:flutter/cupertino.dart' hide RefreshCallback;
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';

export 'package:flutter_riverpod/flutter_riverpod.dart';
export 'package:flutter_linkify/flutter_linkify.dart';
export 'package:google_mobile_ads/google_mobile_ads.dart';

export 'screens/discuss/discuss.dart';
export 'screens/home/home.dart';
export 'screens/question/question.dart';
export 'screens/home/information.dart';

import 'dart:ui' as ui;
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:substring_highlight/substring_highlight.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart' as dioBase;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:alice/alice.dart';

final _alice = Meta.isDeveloping && Platform.isAndroid ? Alice() : null;
final navKey = _alice?.getNavigatorKey();
final dio = dioBase.Dio()
  ..interceptors.add(_alice?.getDioInterceptor() ?? dioBase.Interceptor());
late Size dimensions;

extension Helpers on String {
  Text txt({
    double? size,
    bool? isBold,
    Color? color,
    TextAlign? align,
  }) =>
      Text(
        this.toString(),
        style: TextStyle(
          fontWeight: isBold == true ? FontWeight.bold : null,
          fontSize: size,
          color: color,
        ),
        textAlign: align,
      );

  Text get title => this.txt(isBold: true, size: 16);
  Text get boldBody => this.txt(isBold: true, color: Colors.black);
  Text get body => this.txt(color: Colors.black);
  Text get subtitle => this.txt(color: Colors.grey, size: 14);
  void toast(BuildContext context) => showToast(
        this,
        animation: StyledToastAnimation.slideFromBottomFade,
        reverseAnimation: StyledToastAnimation.fade,
        animDuration: Duration(milliseconds: 200),
        backgroundColor: Colors.black,
        position: StyledToastPosition.center,
        duration: Duration(milliseconds: 1200),
        context: context,
      );
  Future<bool> get copy async {
    Clipboard.setData(ClipboardData(text: this));
    final _temp = await Clipboard.getData(Clipboard.kTextPlain);
    return _temp?.text == this;
  }

  Future<bool> openUrl([bool isSearch = false]) async {
    final _url =
        isSearch ? 'https://google.com/search?q=$this' : this.toString();
    if (await canLaunch(_url)) {
      await launch(_url);
      return true;
    } else {
      this.copy;
      return false;
    }
  }
}

extension Format on DateTime {
  static final _formatter = DateFormat('h:mma | dd/MM/yy');
  String get read => _formatter.format(this.toLocal());
}

class Highlight extends StatelessWidget {
  const Highlight(this.text, this.searchText);
  final Text text;
  final String searchText;
  @override
  Widget build(BuildContext context) {
    return SubstringHighlight(
      text: '${text.data}',
      term: searchText,
      textStyle: text.style!,
      textStyleHighlight: TextStyle(backgroundColor: Colors.yellowAccent),
    );
  }
}

class CachedImage extends StatelessWidget {
  const CachedImage(this.url) : _fit = BoxFit.contain;
  const CachedImage.cover(this.url) : _fit = BoxFit.cover;
  final String url;
  final BoxFit _fit;
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      fit: _fit,
      imageUrl: url,
      placeholder: (_, p) => const Icon(
        Icons.photo_outlined,
        color: Colors.grey,
      ),
      errorWidget: (_, e, __) => const Icon(
        Icons.hide_image_outlined,
        color: Colors.grey,
      ),
    );
  }
}

class Retry extends StatelessWidget {
  final VoidCallback onPressed;
  const Retry(this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Unable to reach the server',
          style: Theme.of(context).textTheme.subtitle1,
        ),
        TextButton(
          onPressed: onPressed,
          child: Text('Retry'),
        ),
      ],
    );
  }
}

class VerifiedIcon extends StatelessWidget {
  const VerifiedIcon({this.size = 20});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified,
      color: Colors.blue,
      size: 20,
    );
  }
}

class FullScreenLoading extends StatelessWidget {
  const FullScreenLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class Storage {
  static Future<void> init() async =>
      _pref = await SharedPreferences.getInstance();
  static late SharedPreferences _pref;
  static bool get getIsPercentage => _pref.getBool('isPercentage') ?? true;
  static set setIsPercentage(bool v) => _pref.setBool('isPercentage', v);
  static bool get getWebSearchQues => _pref.getBool('webSearchQues') ?? true;
  static set setWebSearchQues(bool v) => _pref.setBool('webSearchQues', v);
  static bool get getShareImg => _pref.getBool('shareImg') ?? true;
  static set setShareImg(bool v) => _pref.setBool('shareImg', v);
  static String? get getDeviceId => _pref.getString('deviceId');
  static set setDeviceId(String id) => _pref.setString('deviceId', id);
}

class Meta {
  // IMPORTANT: sasta version control 😏️
  static const version = '1.3.0';
  static const isDeveloping = false;
  static String? baseUrl;
  static String? tgLink;
  static String? msg;
  static late bool showAds;
  static init(Map<String, dynamic> map) {
    baseUrl = map['baseUrl'];
    tgLink = map['channelLink'];
    msg = map['msg'];
    showAds = map['showAds'] ?? false;
  }
}

class AdState {
  static Future<void> init() async {
    if (Platform.isAndroid) await MobileAds.instance.initialize();
  }

  static String? get bannerAdUnitId {
    if (!Platform.isAndroid || !Meta.showAds) return null;
    if (Meta.isDeveloping)
      return BannerAd.testAdUnitId;
    else
      return 'ca-app-pub-8812082806102665/4730023553';
  }

  static String? get interstitialAdUnitId {
    if (!Platform.isAndroid || !Meta.showAds) return null;
    if (Meta.isDeveloping)
      return InterstitialAd.testAdUnitId;
    else
      return 'ca-app-pub-8812082806102665/3274305806';
  }
}

Future<String?> convertWidgetToImage(GlobalKey key) async {
  try {
    final repaintBoundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final boxImage = await repaintBoundary.toImage(pixelRatio: 1.5);
    final byteData = await boxImage.toByteData(format: ui.ImageByteFormat.png);
    final directory = await getTemporaryDirectory();
    if (byteData == null) return null;
    final file = await File('${directory.path}/ques.png').writeAsBytes(
      byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
    );
    return file.path;
  } catch (_) {
    return null;
  }
}
