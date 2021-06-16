import 'dart:convert';

import 'package:aircube/model/state.dart';
import 'package:aircube/page/details.dart';
import 'package:aircube/utils/task.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:select_dialog/select_dialog.dart';

import '../constants.dart';
import 'main.dart';
import 'today.dart';

class DayContent {
  String date;

  List<TaskDetails> tasks;

  DayContent(this.date, this.tasks);
}

const delta = 7;

class InboxContent {
  List<TaskDetails> unplanned;

  List<DayContent> future;

  InboxContent(this.unplanned, this.future);
}

class InboxPage extends StatefulWidget {
  const InboxPage({Key key}) : super(key: key);

  @override
  _InboxPageState createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  bool hideCompleted = false;

  DateTime lastUpdated;

  getSection(BuildContext context, String date, String title, List<TaskDetails> tasks, bool checkCompleted) {
    print("Title is " + title);
    print("Tasks len is " + tasks.length.toString());
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 16.0, 0.0, 16.0),
        child: Text(title, style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12)),
      ),
      for (var task in tasks)
        if (task.closed != true)
          // Text(task.name)
          TaskWidget(task, date, false, (DateTime newDate) async {
            //изменение даты
              setDate(context, task, newDate, () {
                setState(() {});
              });
          }, (TimeOfDay newTime) async {
            var now = DateTime.now();
            var tm = DateTime(now.year, now.month, now.day, newTime.hour, newTime.minute);
            //generate datetime from today and time
            setState(() {
              setTime(context, task, tm, () {
                lastUpdated = DateTime.now();
              });
            });
          }, () async {
            setState(() {
              setAutoTime(context, task, () {
                lastUpdated = DateTime.now();
              });
            });
          }, () async {
            //start
            gotoPage(context, routeDetails, arguments: IDArguments(task.id));
          }, () async {
            //score
            gotoPage(context, routeScoring, arguments: IDArguments(task.id));
          }, () async {
            //set labels
            var state = Provider.of<ApplicationState>(context, listen: false);
            var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
            var data = await dio.get(securePrefix + "/labels/${task.source}");
            if (data.statusCode == 200) {
              print("Data is ${data.data}");
              SelectDialog.showModal(context,
                  label: "Выберите метки",
                  searchHint: "Поиск",
                  multipleSelectedValues: task.labels,
                  items: data.data, onMultipleItemsChange: (List selected) {
                setState(() {
                  if (selected.isNotEmpty) {
                    task.labels = selected;
                  } else {
                    task.labels = [];
                  }
                  Future.delayed(Duration(milliseconds: 10), () async {
                    await dio.put(securePrefix + "/task/${task.id}", data: json.encode({"labels": task.labels}));
                  });
                });
              });
            }
          }, () {
            //complete task
            setState(() {
              if (task.closed == true) {
                task.closed = false;
              } else {
                task.closed = true;
              }
              Future.delayed(Duration(milliseconds: 10), () async {
                var state = Provider.of<ApplicationState>(context, listen: false);
                var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
                print("Update task state");
                var data = json.encode({"state": task.closed ? "closed" : "open"});
                print(data);
                await dio.put(securePrefix + "/task/${task.id}", data: data);
              });
            });
          }, false),
      if (!hideCompleted)
        for (var task in tasks)
          if (task.closed == true)
            // Text(task.name)
            TaskWidget(task, date, false, (DateTime newDate) async {
              //изменение даты
              setDate(context, task, newDate, () {
                setState(() {});
              });
            }, (TimeOfDay newTime) async {
              var now = DateTime.now();
              var tm = DateTime(now.year, now.month, now.day, newTime.hour, newTime.minute);
              //generate datetime from today and time
              setState(() {
                setTime(context, task, tm, () {
                  lastUpdated = DateTime.now();
                });
              });
            }, () async {
              setAutoTime(context, task, () {
                setState(() {
                  lastUpdated = DateTime.now();
                });
              });
            }, () async {
              //start
              Navigator.of(context).pushNamed(routeDetails, arguments: IDArguments(task.id));
            }, () async {
              //score
              Navigator.of(context).pushNamed(routeScoring, arguments: IDArguments(task.id));
            }, () async {
              //set labels
              var state = Provider.of<ApplicationState>(context, listen: false);
              var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
              var data = await dio.get(securePrefix + "/labels/${task.source}");
              if (data.statusCode == 200) {
                print("Data is ${data.data}");
                SelectDialog.showModal(context,
                    searchHint: "Поиск",
                    label: "Выберите метки",
                    multipleSelectedValues: task.labels,
                    items: data.data, onMultipleItemsChange: (List selected) {
                  setState(() {
                    if (selected.isNotEmpty) {
                      task.labels = selected;
                    } else {
                      task.labels = [];
                    }
                    Future.delayed(Duration(microseconds: 1), () async {
                      await dio.put(securePrefix + "/task/${task.id}", data: json.encode({"labels": task.labels}));
                    });
                  });
                });
              }
            }, () async {
              //complete task
              print("Task complete");
              var newClosed = task.closed;
              if (task.closed == true) {
                print("Reopen");
                newClosed = false;
              } else {
                print("Closed");
                newClosed = true;
              }
              var state = Provider.of<ApplicationState>(context, listen: false);
              var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
              print("Update task state");
              var data = json.encode({"state": newClosed ? "closed" : "open"});
              print(data);
              await dio.put(securePrefix + "/task/${task.id}", data: data);
              setState(() {
                task.closed = newClosed;
              });
            }, false)
    ];
  }

  Future<InboxContent> getInboxData(BuildContext context) async {
    var state = Provider.of<ApplicationState>(context, listen: false);
    var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}))
      ..interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
    var response = await dio.get(securePrefix + "/dayplan/notplanned");
    var notPlanned = [];
    if (response.statusCode == 200) {
      var data = await response.data;
      print(data.runtimeType);
      var result = <TaskDetails>[];
      for (var d in data) {
        // print("PARSING $d");
        var td = TaskDetails.fromJson(d);
        print(td);
        await td.fillPrimaryColor(context, td);
        result.add(td);
      }
      // print("NOT PLANNED");
      notPlanned = result;
    } else {
      return InboxContent([], []);
    }

    var future = <DayContent>[];
    var date = DateTime.now();
    for (int day = 0; day < delta; day++) {
      var dayContent = [];
      var dt = date.toIso8601String().substring(0, 10);
      var url = securePrefix + "/dayplan/" + dt;
      date = date.add(Duration(days: 1));
      var response = await dio.get(url);
      print(response.statusCode);
      if (response.statusCode == 200) {
        var data = await response.data;
        var result = <TaskDetails>[];
        for (var d in data) {
          var td = TaskDetails.fromJson(d);
          result.add(td);
        }
        future.add(DayContent(dt, result));
      }
    }
    // print("DayContent!!!");
    // print(future.length);
    // print(future.runtimeType);
    return InboxContent(notPlanned, future);
  }

  String dateToHuman(String date) {
    var humanMonths = [
      "января",
      "февраля",
      "марта",
      "апреля",
      "мая",
      "июня",
      "июля",
      "августа",
      "сентября",
      "октября",
      "ноября",
      "декабря"
    ];
    var spt = date.split("-");
    var dt = DateTime(int.parse(spt[0]), int.parse(spt[1]), int.parse(spt[2]), 0, 0, 0);
    return dt.day.toString() + " " + humanMonths[dt.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context);
    return FutureBuilder<InboxContent>(
        future: getInboxData(context),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return WillPopScope(
              onWillPop: () async {
                Navigator.of(context).pushReplacementNamed(routeToday);
                return false;
              },
              child: Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(
                  elevation: 0,
                  titleSpacing: 2,
                  backgroundColor: Colors.white,
                  leading: BackButton(
                    color: Colors.black54,
                  ),
                  title: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      "Планирование",
                      style: TextStyle(color: Colors.black54, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                body: Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ListTile(
                        leading: Checkbox(
                          checkColor: Colors.white,
                          value: hideCompleted,
                          onChanged: (v) {
                            setState(() {
                              hideCompleted = v;
                            });
                          },
                        ),
                        title: Text(
                          "Скрыть завершенные",
                        ),
                      ),
                      ...getSection(context, null, "Без даты", snapshot.data.unplanned, hideCompleted),
                      for (var i = 0; i < 7; i++)
                        if (snapshot.data.future[i].tasks.isNotEmpty)
                          ...getSection(context, snapshot.data.future[i].date, dateToHuman(snapshot.data.future[i].date),
                              snapshot.data.future[i].tasks, hideCompleted)
                    ]),
                  ),
                ),
              ),
            );
          } else {
            return Center(
                child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(),
            ));
          }
        });
  }
}
