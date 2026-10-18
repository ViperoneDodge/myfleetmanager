import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

bool get isAndroid => !kIsWeb && Platform.isAndroid;

bool get isIOS => !kIsWeb && Platform.isIOS;

bool get isMobile => isAndroid || isIOS;

String get platformName => kIsWeb ? 'web' : (isIOS ? 'ios' : (isAndroid ? 'android' : Platform.operatingSystem));
