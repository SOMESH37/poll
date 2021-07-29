export 'dart:convert';
export 'dart:math';

export 'package:flutter/cupertino.dart' hide RefreshCallback;
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';

export 'package:flutter_riverpod/flutter_riverpod.dart';
export 'package:flutter_linkify/flutter_linkify.dart';

export 'screens/discuss/discuss.dart';
export 'screens/home/home.dart';
export 'screens/question/question.dart';
export 'screens/home/information.dart';

import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:substring_highlight/substring_highlight.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart' as dioBase;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:alice/alice.dart';

// final alice = Alice();
final dio = dioBase.Dio()
// ..interceptors.add(alice.getDioInterceptor())
    ;
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

extension Format on DateTime {
  static final _formatter = DateFormat('h:mma | dd/MM/yy');
  String get read => _formatter.format(this.toLocal());
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
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified,
      color: Colors.blue,
      size: 20,
    );
  }
}

class FullscreenLoading extends StatelessWidget {
  const FullscreenLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

abstract class Storage {
  static Future<void> init() async =>
      _pref = await SharedPreferences.getInstance();
  static late SharedPreferences _pref;
  static bool? get getIsPercentage => _pref.getBool('isPercentage');
  static set setIsPercentage(bool isPercentage) =>
      _pref.setBool('isPercentage', isPercentage);
  static String? get getDeviceId => _pref.getString('deviceId');
  static set setDeviceId(String id) => _pref.setString('deviceId', id);
}

abstract class Meta {
  // IMPORTANT: sasta version control 😏️
  static const version = '1.0.0';
  static String? baseUrl;
  static late String? tgLink;
  static late String? msg;
  static init(Map<String, dynamic> map) {
    baseUrl = map['baseUrl'];
    tgLink = map['channelLink'];
    msg = map['msg'];
  }
}
