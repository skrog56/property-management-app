import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Australian English, as the app writes its own dates dd/mm/yyyy. Without
/// it, Flutter's date picker reads and writes dates in the US order.
const appLocale = Locale('en', 'AU');

const appLocalizations = GlobalMaterialLocalizations.delegates;
