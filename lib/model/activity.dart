import 'dart:convert';
import 'dart:ui';

import 'package:aircube/page/details.dart';

class Activity {
  int id;

  String image;

  String name;

  String time;

  Color color;

  Activity(this.id, this.image, this.name, this.time, this.color);

  Activity.fromJson(dynamic data) {
    this.id = data["id"];
    this.time = data["time"];
    this.name = data["name"];
    this.image = data["image"];
    this.color = rgbToColor(data["color"]);
  }
}