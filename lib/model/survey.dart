import 'dart:convert';

import 'package:flutter/material.dart';


String toTime(TimeOfDay timeOfDay) {
  //HH:mm:ss+03:00
  var result = '';
  result += timeOfDay.hour.toString().padLeft(2, '0');
  result += ':';
  result += timeOfDay.minute.toString().padLeft(2, '0');
  result += ':00';
  DateTime dateTime = DateTime.now();
  print(dateTime.timeZoneName);
  print(dateTime.timeZoneOffset);
  if (!dateTime.timeZoneOffset.isNegative) {
    result += "+";
  } else {
    result += "-";
  }
  result += dateTime.timeZoneOffset.inHours.toString().padLeft(2, '0');
  result += ':';
  result += (dateTime.timeZoneOffset.inMinutes % 60).toString().padLeft(2, '0');
  return "2001-01-01T" + result;
}

class Survey {
  int registration_age;
  int gender;
  String education;
  String marital_status;
  TimeOfDay wake_time;
  TimeOfDay sleep_time;
  int completed;

  Survey(this.registration_age, this.gender, this.education,
      this.marital_status, this.wake_time, this.sleep_time, this.completed);

  //registration_age : -1, gender: -1, education: , marital_status: , wake_time: 2000-01-01T16:48:32.15764Z, sleep_time: 2000-01-01T16:48:32.15764Z, completed: 0
  String toJSON() {
    return json.encode({
      'registration_age': registration_age,
      'gender': gender,
      'education': education,
      'marital_status': marital_status,
      'wake_time': toTime(wake_time),
      'sleep_time': toTime(sleep_time),
      'completed': completed,
    });
  }

  Survey.fromJSON(data) {
    registration_age = data["registration_age"];
    gender = data["gender"];
    education = data["education"];
    marital_status = data["marital_status"];
    completed = data["completed"];
    var dt = DateTime.parse(data["wake_time"]);
    dt = dt.toLocal();
    wake_time = TimeOfDay(hour: dt.hour, minute: dt.minute);
    dt = DateTime.parse(data["sleep_time"]);
    dt = dt.toLocal();
    sleep_time = TimeOfDay(hour: dt.hour, minute: dt.minute);
    print(this);
  }
}