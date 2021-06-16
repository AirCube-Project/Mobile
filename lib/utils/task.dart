import 'dart:convert';

import 'package:aircube/model/state.dart';
import 'package:aircube/page/details.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';

setDate(BuildContext context, TaskDetails task, DateTime newDate, Function next) {
  print("Changing date to $newDate");
  print("Task id is ${task.id}");
  task.plannedDay = newDate.toIso8601String().substring(0, 10);
  Future.delayed(Duration(milliseconds: 10), () async {
    var state = Provider.of<ApplicationState>(context, listen: false);
    var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
    await dio.put(securePrefix + "/task/${task.id}/place", data: json.encode({"date": task.plannedDay}));
    next();
  });
  //send to api
}

setTime(BuildContext context, TaskDetails task, DateTime tm, Function next) {
  print("Planned date is set to ${tm.toIso8601String()}");
  task.plannedDateTime = tm.toIso8601String();
  var td = {"date_time": task.plannedDateTime, "duration": (task.plannedDuration * 60).toInt()};
  print(td);
  Future.delayed(Duration(milliseconds: 10), () async {
    var state = Provider.of<ApplicationState>(context, listen: false);
    var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
    await dio.put(securePrefix + "/task/${task.id}/plan", data: json.encode(td));
    next();
  });
}

setAutoTime(BuildContext context, TaskDetails task, Function next) {
  print("Setting autotime");
  task.plannedDateTime = null;
  var td = {"date_time": null, "duration": (task.plannedDuration * 60).toInt()};
  Future.delayed(Duration(microseconds: 10), () async {
    var state = Provider.of<ApplicationState>(context, listen: false);
    var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
    await dio.put(securePrefix + "/task/${task.id}/plan", data: json.encode(td));
    print("Time is set");
    next();
  });
}
