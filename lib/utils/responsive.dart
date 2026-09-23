import 'package:flutter/material.dart';

/// App-wide width breakpoints.
class Breakpoints {
  Breakpoints._();

  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

bool isMobileWidth(BuildContext context) =>
    MediaQuery.of(context).size.width < Breakpoints.mobile;

bool isTabletWidth(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= Breakpoints.mobile && width < Breakpoints.tablet;
}

bool isDesktopWidth(BuildContext context) =>
    MediaQuery.of(context).size.width >= Breakpoints.tablet;

/// Standard horizontal page padding.
double pagePadding(BuildContext context) =>
    isMobileWidth(context) ? 16 : 24;

/// Chooses a column count based on the current width.
int responsiveColumns(
  BuildContext context, {
  int xs = 2,
  int sm = 3,
  int md = 4,
  int lg = 6,
}) {
  final width = MediaQuery.of(context).size.width;
  if (width >= Breakpoints.desktop) return lg;
  if (width >= Breakpoints.tablet) return md;
  if (width >= Breakpoints.mobile) return sm;
  return xs;
}
