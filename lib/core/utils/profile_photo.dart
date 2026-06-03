import 'dart:convert';

import 'package:flutter/material.dart';

ImageProvider<Object>? profilePhotoProvider(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.startsWith('data:image/')) {
    final commaIndex = trimmed.indexOf(',');
    if (commaIndex == -1) return null;
    final base64Part = trimmed.substring(commaIndex + 1);
    try {
      return MemoryImage(base64Decode(base64Part));
    } catch (_) {
      return null;
    }
  }

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return NetworkImage(trimmed);
  }

  return null;
}
