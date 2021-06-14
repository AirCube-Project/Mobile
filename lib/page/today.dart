import 'dart:convert';
import 'dart:ui';

import 'package:aircube/model/state.dart';
import 'package:aircube/page/details.dart';
import 'package:aircube/utils/task.dart';
import 'package:aircube/widget/timeline.dart';
import 'package:app_popup_menu/app_popup_menu.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:select_dialog/select_dialog.dart';
import 'package:blur/blur.dart';

import '../constants.dart';
import 'main.dart';

const SET_TIME = 1;
const SET_AUTOMATIC_TIME = 2;
const SET_SCORES = 3;
const MOVE = 4;
const LABELS = 5;
const COMPLETE = 6;

class PresetModel extends Comparable {
  final int id;
  final String name;

  PresetModel({this.id, this.name});

  @override
  String toString() => name;

  @override
  operator ==(o) => o is PresetModel && o.id == id;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  int compareTo(other) {
    return this.name.compareTo(other.name);
  }
}

Widget getIntegrationSourceIcon(int source) {
  switch (source) {
    case 1:
      return Image.asset(
        "assets/gitlab.png",
        width: 24,
        height: 24,
      );
    case 2:
      return Image.asset(
        "assets/github.png",
        width: 24,
        height: 24,
      );
    case 3:
      return Image.asset(
        "assets/trello.jpg",
        width: 24,
        height: 24,
      );
    case 4:
      return Image.asset(
        "assets/google-calendar.jpeg",
        width: 24,
        height: 24,
      );
    default:
      return null;
  }
}

class TaskWidget extends StatelessWidget {
  TaskDetails task;

  String date;

  bool tapable;

  Function setDate;

  Function setTime;

  Function setAutomaticTime;

  Function start;

  Function score;

  Function setLabels;

  Function complete;

  bool todayMode;

  TaskWidget(this.task, this.date, this.tapable, this.setDate, this.setTime, this.setAutomaticTime, this.start, this.score,
      this.setLabels, this.complete, this.todayMode,
      {Key key})
      : super(key: key);

  List<TaskDetails> tasks;

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context);

    var labels = task.labels;
    print(labels.length);
    if (labels.length > 0 && labels[0].isEmpty) {
      labels = [];
    }

    return task.plannedDay == date
        ? Padding(
            //Карточка со скруглениями
            padding: EdgeInsets.symmetric(horizontal: todayMode ? 16.0 : 0.0, vertical: todayMode ? 2.0 : 0.0),
            child: InkWell(
              onTap: tapable
                  ? () {
                      start();
                    }
                  : null,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    border: !todayMode ? Border.symmetric(horizontal: BorderSide(color: Colors.black45, width: 0.5)) : null),
                child: Card(
                    elevation: todayMode ? 4 : 0,
                    shape: todayMode
                        ? RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16.0)),
                            side: BorderSide(color: Colors.black45),
                          )
                        : null,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: labels.isNotEmpty ? 96 : 64,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(children: [
                          //Изображение активности (квадрат 64х64 от центра)
                          Container(
                              width: 64,
                              height: labels.isNotEmpty ? 80 : 64,
                              //кадрировать изображение в квадрат (от центра)
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircleAvatar(
                                  radius: 10,
                                  child: getIntegrationSourceIcon(task.source),
                                  backgroundColor: task.primaryColor ?? task.overrideColor ?? Color.fromRGBO(0, 0, 0, 0.5),
                                ),
                              )),
                          //Название активности
                          Blur(
                            blur: task.closed == true ? 1 : 0,
                            colorOpacity: task.closed == true ? 0.5 : 0,
                            child: SizedBox(
                              width: mq.size.width - 120 - (todayMode ? 32 : 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(task.name,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          decoration: task.closed == true ? TextDecoration.lineThrough : null)),
                                  Text(task.taskState(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w300,
                                      )),
                                  labels.isNotEmpty
                                      ? Row(
                                          children: [
                                            for (var label in task.labels)
                                              Padding(
                                                padding: const EdgeInsets.only(right: 4.0),
                                                child: Chip(
                                                  backgroundColor: Theme.of(context).primaryColor,
                                                  visualDensity: VisualDensity.compact,
                                                  padding: EdgeInsets.all(2),
                                                  label: Text(
                                                    label,
                                                    style: TextStyle(fontSize: 10, color: Colors.white),
                                                  ),
                                                ),
                                              )
                                          ],
                                        )
                                      : Container()
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            child: InkWell(
                              onTap: () {},
                              child: AppPopupMenu<int>(
                                menuItems: [
                                  PopupMenuItem(
                                      value: SET_TIME,
                                      child: ListTile(
                                        leading: Icon(Icons.watch_later_outlined),
                                        title: Text("Установить время"),
                                      )),
                                  PopupMenuItem(
                                      value: SET_AUTOMATIC_TIME,
                                      child: ListTile(
                                        leading: Icon(Icons.auto_awesome),
                                        title: Text("Автопланирование"),
                                      )),
                                  PopupMenuItem(
                                      value: SET_SCORES,
                                      child: ListTile(
                                        leading: Icon(Icons.star_border),
                                        title: Text("Оценить"),
                                      )),
                                  PopupMenuItem(
                                      value: MOVE,
                                      child: ListTile(
                                        leading: Icon(Icons.near_me),
                                        title: Text("Перенести"),
                                      )),
                                  PopupMenuItem(
                                      value: LABELS,
                                      child: ListTile(
                                        leading: Icon(Icons.label_important_outline),
                                        title: Text("Изменить метки"),
                                      )),
                                  PopupMenuItem(
                                      value: COMPLETE,
                                      child: ListTile(
                                        leading: Icon(Icons.check_box_outlined),
                                        title: Text(task.closed != true ? "Завершить" : "Переоткрыть"),
                                      )),
                                ],
                                onSelected: (int value) async {
                                  var id = task.id;
                                  var now = DateTime.now();
                                  final delta = 15;
                                  var mins = now.minute + delta;
                                  var hours = now.hour;
                                  if (mins > 60) {
                                    mins -= 60;
                                    hours++;
                                    if (hours >= 24) {
                                      hours = 23;
                                      mins = 59;
                                    }
                                  }
                                  var tod = TimeOfDay(hour: hours, minute: mins);
                                  switch (value) {
                                    case SET_TIME:
                                      var time = await showTimePicker(context: context, initialTime: tod);
                                      if (time != null) {
                                        setTime(time);
                                      }
                                      break;
                                    case SET_SCORES:
                                      score();
                                      break;
                                    case MOVE:
                                      var result = await showDatePicker(
                                        context: context,
                                        initialDate: todayMode ? DateTime.now().add(Duration(days: 1)) : DateTime.now(),
                                        firstDate: todayMode ? DateTime.now().add(Duration(days: 1)) : DateTime.now(),
                                        lastDate: DateTime.now().add(Duration(days: 365)),
                                      );
                                      if (result != null) {
                                        //change date in task list
                                        print("New date is $result");
                                        setDate(result);
                                      }
                                      break;
                                    case LABELS:
                                      setLabels();
                                      break;
                                    case SET_AUTOMATIC_TIME:
                                      setAutomaticTime();
                                      break;
                                    case COMPLETE:
                                      complete();
                                      break;
                                  }
                                  print("Value $value");
                                },
                                onCanceled: () {},
                                elevation: 6,
                                icon: const Icon(Icons.more_vert),
                                offset: const Offset(0, 30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: Colors.white,
                              ),
                            ),
                          ),
                          //Кнопка активации
                        ]),
                      ),
                    )),
              ),
            ))
        : Container();
  }
}

BottomNavigationBar buildNavBar(BuildContext context, int index) {
  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    currentIndex: index,
    onTap: (value) {
      switch (value) {
        case 0:
          gotoPage(context, routeToday);
          break;
        case 1:
          gotoPage(context, routeNow);
          break;
        case 2:
          gotoPage(context, routeGoals);
          break;
        case 3:
          gotoPage(context, routeProfile);
          break;
      }
      print(value);
    },
    items: [
      BottomNavigationBarItem(
          icon: Icon(
            Icons.calendar_today_outlined,
            color: Colors.black,
          ),
          label: "Сегодня",
          activeIcon: Icon(Icons.calendar_today_outlined, color: Theme.of(context).primaryColor)),
      BottomNavigationBarItem(
          icon: Icon(Icons.radio_button_checked, color: Colors.black),
          label: "Сейчас",
          activeIcon: Icon(Icons.radio_button_checked, color: Theme.of(context).primaryColor)),
      BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined, color: Colors.black),
          label: "Цели",
          activeIcon: Icon(Icons.dashboard_customize_outlined, color: Theme.of(context).primaryColor)),
      BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_outlined, color: Colors.black),
          label: "Профиль",
          activeIcon: Icon(Icons.person_outline_outlined, color: Theme.of(context).primaryColor))
    ],
    // ),
  );
}

class TodayContent {
  List<TaskDetails> tasks;

  TodayContent(this.tasks);
}

class Today extends StatefulWidget {
  @override
  _TodayState createState() => _TodayState();
}

class _TodayState extends State<Today> {
  DateTime lastUpdated;

  Future<TodayContent> getTodayData(context) async {
    var state = Provider.of<ApplicationState>(context, listen: false);
    var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}))
      ..interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
    var response = await dio.get(securePrefix + "/planofday");
    if (response.statusCode == 200) {
      var data = await response.data;
      var result = <TaskDetails>[];
      for (var d in data) {
        var td = TaskDetails.fromJson(d);
        print(td);
        await td.fillPrimaryColor(context, td);
        result.add(td);
      }
      return TodayContent(result);
    } else {
      return TodayContent([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context);
    var today = DateTime.now().toIso8601String().substring(0, 10);

    return Scaffold(
        backgroundColor: Colors.white,

        bottomNavigationBar: buildNavBar(context, 0),
        floatingActionButton: SpeedDial(
            icon: Icons.add,
            iconTheme: IconThemeData(color: Colors.white),
            activeIcon: Icons.close,
            backgroundColor: Theme.of(context).primaryColor,
            buttonSize: 56.0,
            visible: true,
            closeManually: false,
            curve: Curves.bounceIn,
            // overlayColor: Colors.black,
            // overlayOpacity: 0.1,
            shape: CircleBorder(),
            elevation: 8.0,
            children: [
              SpeedDialChild(
                  child: Icon(
                    Icons.add_task_outlined,
                    color: Colors.white,
                  ),
                  backgroundColor: Theme.of(context).primaryColorLight,
                  label: "Создать новую",
                  labelStyle: TextStyle(fontSize: 14.0),
                  onTap: () async {
                    await gotoPage(context, routeAdd);
                    setState(() {
                      lastUpdated = DateTime.now();
                    });
                  }),
              SpeedDialChild(
                  child: Icon(
                    Icons.note_add,
                    color: Colors.white,
                  ),
                  backgroundColor: Theme.of(context).primaryColorDark,
                  label: "Создать из шаблона",
                  labelStyle: TextStyle(fontSize: 14.0),
                  onTap: () async {
                    var state = Provider.of<ApplicationState>(context, listen: false);
                    var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
                    var presets = await dio.get(securePrefix + "/presets");
                    if (presets.statusCode == 200) {
                      var list = presets.data.map<PresetModel>((p) => PresetModel(id: p["id"], name: p["name"])).toList();
                      list.sort();
                      print(list);
                      SelectDialog.showModal<PresetModel>(context, label: "Выберите шаблон", items: list,
                          onChange: (selected) async {
                        await dio.post(securePrefix + "/task/template", data: json.encode({"preset": selected.id}));
                        setState(() {
                          lastUpdated = DateTime.now();
                        });
                      }, searchHint: "Поиск");
                    }
                  })
            ]),

        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Будет доступно в следующем обновлении")));
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
                onPressed: () {
                  gotoPage(context, routeInbox);
                },
                icon: Icon(
                  Icons.move_to_inbox_outlined,
                  color: Colors.black,
                ))
          ],
          title: Text(
            "План на день",
            style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ),
        body: FutureBuilder<TodayContent>(
            future: getTodayData(context),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Consumer<ApplicationState>(builder: (context, state, child) {
                        return Container(
                          width: mq.size.width,
                          padding: EdgeInsets.only(bottom: 16),
                          child: PhysicalModel(
                              color: Colors.white,
                              elevation: 8,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: mq.size.width / 100),
                                width: mq.size.width - 2 * mq.size.width / 100,
                                height: 128,
                                color: Colors.black26,
                                child: CustomPaint(
                                    painter: TimeLinePainter(
                                        (state.survey.sleep_time.hour * 60 +
                                                state.survey.sleep_time.minute -
                                                (state.survey.wake_time.hour * 60 + state.survey.wake_time.minute)) ~/
                                            15,
                                        15,
                                        state.survey.wake_time.hour * 60 + state.survey.wake_time.minute,
                                        [
                                          for (var activity in snapshot.data.tasks)
                                            if (activity.effectiveStart != null)
                                              Event(
                                                  activity.name,
                                                  activity.effectiveStart,
                                                  activity.plannedDuration?.toInt() ?? 25,
                                                  activity.primaryColor ??
                                                      activity.overrideColor ??
                                                      Color.fromRGBO(0, 0, 0, 0.5),
                                                  activity.closed == true ? 1 : 2),
                                        ],
                                        2,
                                        mq.size.width / 100)),
                              )),
                        );
                      }),
                      for (var task in snapshot.data.tasks)
                        if (task.closed != true)
                          TaskWidget(task, today, true, (DateTime newDate) async {
                            //изменение даты
                            setState(() {
                              setDate(context, task, newDate);
                              lastUpdated = DateTime.now();
                            });
                          }, (TimeOfDay newTime) async {
                            var now = DateTime.now();
                            var tm = DateTime(now.year, now.month, now.day, newTime.hour, newTime.minute);
                            //generate datetime from today and time
                            setState(() {
                              setTime(context, task, tm);
                              lastUpdated = DateTime.now();
                            });
                          }, () async {
                            setState(() {
                              setAutoTime(context, task);
                              lastUpdated = DateTime.now();
                            });
                          }, () async {
                            //start
                            await Navigator.of(context).pushNamed(routeDetails, arguments: IDArguments(task.id));
                            setState(() {
                              lastUpdated = DateTime.now();
                            });
                          }, () async {
                            //score
                            var score = await Navigator.of(context).pushNamed(routeScoring, arguments: IDArguments(task.id));
                            //reload scores for task!
                            var state = Provider.of<ApplicationState>(context, listen: false);
                            var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
                            var resp = await dio.get(securePrefix + "/task/${task.id}");
                            if (resp.statusCode == 200) {
                              var newTask = TaskDetails.fromJson(resp.data);
                              setState(() {
                                task.indIntellect = newTask.indIntellect;
                                task.indPhys = newTask.indPhys;
                                task.indStress = newTask.indStress;
                                task.indPleasure = newTask.indPleasure;
                                task.indSelfDev = newTask.indSelfDev;
                                task.indProfGrow = newTask.indProfGrow;
                                task.indHealth = newTask.indHealth;
                                task.indCreative = newTask.indCreative;
                                task.plannedDuration = newTask.plannedDuration;
                              });
                              print(newTask);
                            }
                            print("Score completed");
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
                                  print("New labels");
                                  print(selected);
                                  if (selected.isNotEmpty) {
                                    task.labels = selected;
                                  } else {
                                    task.labels = [];
                                  }
                                  Future.delayed(Duration(microseconds: 1), () async {
                                    await dio.put(securePrefix + "/task/${task.id}",
                                        data: json.encode({"labels": task.labels}));
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
                          }, true),
                      for (var task in snapshot.data.tasks)
                        if (task.closed == true)
                          TaskWidget(task, today, true, (DateTime newDate) async {
                            //изменение даты
                            setState(() {
                              setDate(context, task, newDate);
                            });
                          }, (TimeOfDay newTime) async {
                            var now = DateTime.now();
                            var tm = DateTime(now.year, now.month, now.day, newTime.hour, newTime.minute);
                            //generate datetime from today and time
                            setState(() {
                              setTime(context, task, tm);
                              lastUpdated = DateTime.now();
                            });
                          }, () async {
                            setState(() {
                              setAutoTime(context, task);
                              lastUpdated = DateTime.now();
                            });
                          }, () async {
                            //start
                            await Navigator.of(context).pushNamed(routeDetails, arguments: IDArguments(task.id));
                            lastUpdated = DateTime.now();
                          }, () async {
                            //score
                            var score = await Navigator.of(context).pushNamed(routeScoring, arguments: IDArguments(task.id));
                            //reload scores for task!
                            var state = Provider.of<ApplicationState>(context, listen: false);
                            var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
                            var resp = await dio.get(securePrefix + "/task/${task.id}");
                            if (resp.statusCode == 200) {
                              var newTask = TaskDetails.fromJson(resp.data);
                              setState(() {
                                task.indIntellect = newTask.indIntellect;
                                task.indPhys = newTask.indPhys;
                                task.indStress = newTask.indStress;
                                task.indPleasure = newTask.indPleasure;
                                task.indSelfDev = newTask.indSelfDev;
                                task.indProfGrow = newTask.indProfGrow;
                                task.indHealth = newTask.indHealth;
                                task.indCreative = newTask.indCreative;
                                task.plannedDuration = newTask.plannedDuration;
                              });
                              print(newTask);
                            }
                            print("Score completed");
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
                                  print("New labels");
                                  print(selected);
                                  if (selected.isNotEmpty) {
                                    task.labels = selected;
                                  } else {
                                    task.labels = [];
                                  }
                                  Future.delayed(Duration(microseconds: 1), () async {
                                    await dio.put(securePrefix + "/task/${task.id}",
                                        data: json.encode({"labels": task.labels}));
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
                          }, true),
                    ]),
                  ),
                );
              } else {
                return Center(
                    child: SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(),
                ));
              }
            }));
  }
}
