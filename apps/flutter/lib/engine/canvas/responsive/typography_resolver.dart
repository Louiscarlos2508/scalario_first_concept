import 'package:flutter/material.dart';

final typographyTokens = {
  'h1': const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
  'h2': const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
  'h3': const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
  'body': const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
  'body_bold': const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
  'caption': const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.grey),
  'overline': const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: Colors.grey),
  'label': const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
  'kpi_value': const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
  'kpi_label': const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
};

TextStyle? resolveTypography(dynamic token) {
  if (token is String) return typographyTokens[token];
  return null;
}
