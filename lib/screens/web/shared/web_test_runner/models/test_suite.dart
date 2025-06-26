import 'package:flutter/material.dart';

class TestSuite {
  final String name;
  final String path;
  final IconData icon;
  final String description;

  TestSuite({
    required this.name,
    required this.path,
    required this.icon,
    this.description = '',
  });
}