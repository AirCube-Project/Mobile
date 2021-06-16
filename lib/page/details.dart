import 'dart:async';
import 'dart:convert';

import 'package:aircube/constants.dart';
import 'package:aircube/model/state.dart';
import 'package:aircube/page/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_glow/flutter_glow.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';

const MODE_FOCUS = 2;
const MODE_TIMER = 1;

const ANSWER_YES = 1;
const ANSWER_NO = 2;
const ANSWER_POSTPONE = 3;

class TaskDetails {
  int id;

  String name;

  String description;

  //todo: labels!
  // String labels;

  int priority;

  String dueDate;

  String plannedDateTime;
  bool closed;

  double plannedDuration;
  List labels;
  int indIntellect;
  int indPhys;
  int indStress;
  int indCreative;
  int indPleasure;
  int indProfGrow;
  int indHealth;
  int indSelfDev;
  String banner;
  int source;
  int sourceId;
  Color primaryColor;
  Color overrideColor;
  String plannedDay;
  String dynamicTime;
  int effectiveStart;

  TaskDetails.fromJson(data) {
    print(data);
    id = data["id"];
    name = data["name"];
    description = data["description"];
    labels = data["labels"];
    priority = data["priority"];
    dueDate = data["due_date"];
    plannedDateTime = data["planned_date"];
    if (data["planned_duration"] != null) {
      plannedDuration = data["planned_duration"].toDouble() / 60.0;
    } else {
      plannedDuration = null;
    }
    indIntellect = data["ind_intellect"];
    indPhys = data["ind_phys"];
    indStress = data["ind_stress"];
    indCreative = data["ind_creative"];
    indPleasure = data["ind_pleasure"];
    indProfGrow = data["ind_prof_grow"];
    indHealth = data["ind_health"];
    indSelfDev = data["ind_self_dev"];
    source = data["source"];
    sourceId = data["source_id"];
    banner = data["banner"];
    overrideColor = rgbToColor(data["color"]);
    primaryColor = rgbToColor(data["primary_color"]);
    // print("Primary Color $primaryColor");
    // print("Override Color $overrideColor");
    plannedDay = data["planned_day"];
    closed = data["closed"];
    dynamicTime = data["dynamic_time"];
    TimeOfDay dTime; //динамическое расположение
    TimeOfDay fTime; //фиксированное расположение
    if (dynamicTime != null) {
      var dts = dynamicTime.split(":");
      dTime = TimeOfDay(hour: int.parse(dts[0]), minute: int.parse(dts[1]));
    }
    try {
      if (plannedDateTime != null) {
        if (plannedDateTime.contains("T"))
          plannedDateTime = plannedDateTime.substring(plannedDateTime.indexOf("T") + 1);
        else
          plannedDateTime = plannedDateTime.substring(plannedDateTime.indexOf(" ") + 1);
        var pts = plannedDateTime.split(":");
        fTime = TimeOfDay(hour: int.parse(pts[0]), minute: int.parse(pts[1]));
      }
    } catch (Exception) {
      print(StackTrace.current);
    }
    effectiveStart = null;
    if (fTime == null) {
      if (dTime != null) {
        effectiveStart = dTime.hour * 60 + dTime.minute;
      }
    } else {
      effectiveStart = fTime.hour * 60 + fTime.minute;
    }
    print("Effective start is $effectiveStart");
  }

  bool validInd(int score) {
    return score != null && score >= 1 && score <= 5;
  }

  taskState() {
    var states = [];
    // print("Getting state");
    var scored = validInd(indSelfDev) &&
        validInd(indHealth) &&
        validInd(indProfGrow) &&
        validInd(indCreative) &&
        validInd(indPleasure) &&
        validInd(indStress) &&
        validInd(indPhys) &&
        validInd(indIntellect) &&
        plannedDuration != null &&
        plannedDuration != 0;
    if (!scored) {
      states.add("Не оценена");
    } else {
      states.add("Оценена");
    }
    states.add(plannedDateTime != null && plannedDateTime != "" ? "время вручную" : "автопланирование");
    return states.join(", ");
  }

  String colorToHex(Color color) {
    var r = color.red.toRadixString(16);
    if (r.length < 2) r = "0" + r;
    var g = color.green.toRadixString(16);
    if (g.length < 2) g = "0" + g;
    var b = color.blue.toRadixString(16);
    if (b.length < 2) b = "0" + b;
    return "#" + r + g + b;
  }

  fillPrimaryColor(BuildContext context, TaskDetails task) async {
    // print("Task is $task");
    if (banner != null && banner.isNotEmpty && task.primaryColor == null) {
      try {
        //fill primary color
        var generator = await PaletteGenerator.fromImageProvider(NetworkImage(publicPrefix + "/image/" + banner));
        this.primaryColor = generator.mutedColor.color;
        var state = Provider.of<ApplicationState>(context, listen: false);
        var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
        await dio.put(securePrefix + "/task/${task.id}", data: json.encode({"primary_color": colorToHex(this.primaryColor)}));
      } catch (Exception) {}
    }
  }
}

Color rgbToColor(String color) {
  if (color == null || color.length != 7) {
    return null;
  }
  // print("Translating color " + color);
  color = color.toUpperCase();
  int r = int.parse(color.substring(1, 3), radix: 16);
  int g = int.parse(color.substring(3, 5), radix: 16);
  int b = int.parse(color.substring(5, 7), radix: 16);
  return Color.fromRGBO(r, g, b, 1);
}

String twoDigits(int d) {
  if (d < 10)
    return "0$d";
  else
    return d.toString();
}

String toTime(int seconds) {
  return twoDigits((seconds / 3600).toInt()) + ":" + twoDigits(((seconds % 3600) / 60).toInt()) + ":" + twoDigits(seconds % 60);
}

class DetailsData {
  TaskDetails task;
  bool focus;

  DetailsData(this.task, this.focus);
}

class DetailsPage extends StatefulWidget {
  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute
        .of(context)
        .settings
        .arguments as IDArguments;
    var id = args.id;
    var mq = MediaQuery.of(context);
    // print("Details for $id");
    return WillPopScope(
        onWillPop: () async {
          goBack(context);
          return false;
        },
        child: FutureBuilder<DetailsData>(future: () async {
          // print("Get data!!!!!!");
          var state = Provider.of<ApplicationState>(context, listen: false);
          var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
          // print("URL IS /task/$id");
          var details = await dio.get(securePrefix + "/task/$id");
          // print("Details status ${details.statusCode}");
          if (details.statusCode == 200) {
            // print("Data accepted");
            // print(details.data);

            var focus = await dio.get(securePrefix + "/focus");
            // print("Focus is $focus");
            var focusMode = false;
            if (focus.statusCode == 200) {
              focusMode = focus.data["focus_task"] != null;
              if (focusMode) {
                // print(focus.data);
                state.focusTask = focus.data["focus_task"];
                state.initialTimerValue = focus.data["timer_value"].toDouble();
                state.timerValue = focus.data["timer_value"].toDouble();
                state.timerStart = DateTime.now();
                state.timerDirection = focus.data["timer_direction"];
              }
            }
            // print("Data filled");
            return DetailsData(TaskDetails.fromJson(await details.data), focusMode);
          } else {
            return null;
          }
        }(), builder: (context, snapshot) {
          var state = Provider.of<ApplicationState>(context, listen: false);
          return Container(
            color: Color.fromRGBO(47, 11, 111, 1),
            child: AnimatedOpacity(
                opacity: snapshot.hasData ? 1.0 : 0.0,
                duration: Duration(seconds: 1),
                child: snapshot.hasData
                    ? DetailsContent(snapshot.data, id, snapshot.data.focus, state)
                    : Container(color: Color.fromRGBO(47, 11, 111, 1))),
          );
        }));
  }
}

class DetailsContent extends StatefulWidget {
  DetailsContent(this.data, this.id, this.focus, this.state, {Key key}) : super(key: key);

  DetailsData data;

  bool focus;

  ApplicationState state;

  var color = Color.fromRGBO(47, 11, 111, 1);

  int id;

  @override
  _DetailsContentState createState() => _DetailsContentState();
}

class _DetailsContentState extends State<DetailsContent> {
  DateTime lastUpdated;

  DetailsData data;

  bool focus;

  taskConfirmation(ApplicationState state, Dio dio) {
    Future.delayed(Duration(milliseconds: 100), () async {
      var confirm = await showModalActionSheet<int>(
          context: context,
          title: "Вы завершили активность?",
          actions: [
            SheetAction<int>(label: "Да", key: ANSWER_YES),
            SheetAction<int>(label: "Нет", key: ANSWER_NO),
            SheetAction<int>(label: "Отложить", key: ANSWER_POSTPONE),
          ],
          cancelLabel: "Нет");
      switch (confirm) {
        case ANSWER_YES:
          var data = json.encode({"state": "closed"});
          await dio.put(securePrefix + "/task/${widget.id}", data: data);
          goBack(context);
          break;
        case ANSWER_POSTPONE:
          goBack(context);
          break;
        case ANSWER_NO:
          var time = await dio.put(securePrefix + "/task/${widget.id}/initial",
              data: json.encode({"mode": MODE_FOCUS}));
          var data = {
            "timer_start": time.data["initial_timer"],
            "timer_direction": time.data["timer_direction"]
          };
          await dio.put(securePrefix + "/task/${widget.id}/take", data: json.encode(data));
          setState(() {
            state.timerStart = DateTime.now();
            state.timerValue = time.data["initial_timer"].toDouble();
            state.initialTimerValue = state.timerValue;
            state.timerDirection = time.data["timer_direction"];
            state.focusTask = widget.id;
            lastUpdated = DateTime.now();
            focus = true;

            state.timer = createTimer(state);
          });
          break;
      }
    });
  }

  Timer createTimer(ApplicationState state) {
    var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
    return Timer.periodic(Duration(seconds: 1), (timer)
    {
      setState(() {
        var now = DateTime.now();
        var diff = now
            .difference(state.timerStart)
            .inSeconds;
        var tv = state.initialTimerValue + diff * state.timerDirection;
        if (tv <= 0) {
          //completed!
          tv = 0;
          // print("Completed");
          if (state.timer != null) {
            state.timer.cancel();
          }
          focus = false;
          var task = state.focusTask;
          Future.delayed(Duration(milliseconds: 1), () async {
            await dio.get(securePrefix + "/task/$task/finish");
          });

          taskConfirmation(state, dio);
        }
        state.timerValue = tv;
        lastUpdated = DateTime.now();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context);
    return Consumer<ApplicationState>(
        builder: (context, state, child) =>
            Scaffold(
                appBar: AppBar(
                  backgroundColor: widget.color,
                  elevation: 0,
                  automaticallyImplyLeading: !focus,
                ),
                body: Container(
                  color: widget.color,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0.1 * mq.size.height,
                        left: 0.1 * mq.size.width,
                        child: GlowContainer(
                            spreadRadius: 2,
                            glowColor: Theme
                                .of(context)
                                .primaryColor,
                            width: mq.size.width * 0.8,
                            height: mq.size.width * 0.8 / 2,
                            child: CachedNetworkImage(
                              imageUrl: publicPrefix + "/image/${data.task.banner}",
                              placeholder: (context, url) =>
                                  Container(
                                    color: data.task.overrideColor,
                                  ),
                              errorWidget: (context, url, error) => Container(color: data.task.overrideColor),
                              fit: BoxFit.cover,
                            )),
                      ),
                      if (!focus)
                        Positioned(
                          bottom: 128,
                          left: mq.size.width * 0.1,
                          child: InkWell(
                            onTap: () async {
                              var state = Provider.of<ApplicationState>(context, listen: false);
                              var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
                              var time = await dio.put(securePrefix + "/task/${widget.id}/initial",
                                  data: json.encode({"mode": MODE_FOCUS}));
                              // print(time.data);
                              setState(() {
                                state.timerStart = DateTime.now();
                                state.timerValue = time.data["initial_timer"].toDouble();
                                state.initialTimerValue = state.timerValue;
                                state.timerDirection = time.data["timer_direction"];
                                state.focusTask = widget.id;
                                lastUpdated = DateTime.now();
                                focus = true;
                                // print("Entering timer mode");
                                Future.delayed(Duration(microseconds: 10), () async {
                                  var data = {
                                    "timer_start": state.initialTimerValue.toInt(),
                                    "timer_direction": state.timerDirection
                                  };
                                  // print(data);
                                  var dx = json.encode(data);
                                  // print("DX=$dx");
                                  // print("ID=${widget.id}");
                                  await dio.put(securePrefix + "/task/${widget.id}/take", data: dx);
                                  state.timer = createTimer(state);
                                  });
                              });
                            },
                            child: GlowContainer(
                              // color: Colors.indigo,
                              color: Theme
                                  .of(context)
                                  .primaryColor,
                              width: mq.size.width * 0.8,
                              spreadRadius: 3.0,
                              borderRadius: BorderRadius.circular(32.0),
                              glowColor: Theme
                                  .of(context)
                                  .primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              // style: OutlinedButton.styleFrom(
                              //   side: BorderSide(color: Theme.of(context).primaryColorLight),
                              //     shape: RoundedRectangleBorder(
                              //         borderRadius: BorderRadius.circular(32))),
                              child: Text("Сфокусироваться",
                                  textAlign: TextAlign.center, style: TextStyle(color: Theme
                                      .of(context)
                                      .buttonColor)),
                            ),
                          ),
                        ),
                      if (focus)
                        Positioned(
                          bottom: 128,
                          left: mq.size.width * 0.1,
                          child: InkWell(
                            onTap: () async {
                              var state = Provider.of<ApplicationState>(context, listen: false);
                              var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
                              await dio.get(securePrefix + "/task/${state.focusTask}/finish");
                              setState(() {
                                if (state.timer != null) {
                                  state.timer.cancel();
                                }
                                state.timer = null;

                                state.focusTask = null;
                                lastUpdated = DateTime.now();
                                focus = false;
                              });
                              taskConfirmation(state, dio);
                            },
                            child: GlowContainer(
                              // color: Colors.indigo,
                              color: Theme
                                  .of(context)
                                  .primaryColor,
                              width: mq.size.width * 0.8,
                              spreadRadius: 3.0,
                              borderRadius: BorderRadius.circular(32.0),
                              glowColor: Theme
                                  .of(context)
                                  .primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              // style: OutlinedButton.styleFrom(
                              //   side: BorderSide(color: Theme.of(context).primaryColorLight),
                              //     shape: RoundedRectangleBorder(
                              //         borderRadius: BorderRadius.circular(32))),
                              child: Text("Остановить",
                                  textAlign: TextAlign.center, style: TextStyle(color: Theme
                                      .of(context)
                                      .buttonColor)),
                            ),
                          ),
                        ),
                      Positioned(
                        top: mq.size.height * 0.4,
                        child: Container(
                            width: mq.size.width,
                            child: Text(data.task.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Theme
                                    .of(context)
                                    .buttonColor, fontSize: 22, fontWeight: FontWeight.w200))),
                      ),
                      if (!focus && data.task.plannedDuration != null && data.task.plannedDuration != 0)
                        Positioned(
                          top: mq.size.height * 0.5 - 10,
                          child: Container(
                            width: mq.size.width,
                            child: Text(
                              "Ожидаемая продолжительность",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Theme
                                  .of(context)
                                  .buttonColor, fontSize: 12),
                            ),
                          ),
                        ),
                      if (!focus)
                        if (data.task.plannedDuration != null && data.task.plannedDuration != 0)
                          Positioned(
                              top: mq.size.height * 0.5 + 20,
                              child: Container(
                                width: mq.size.width,
                                child: Text(
                                  toTime((data.task.plannedDuration * 60)?.toInt()),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.w100, fontSize: 42, color: Theme
                                      .of(context)
                                      .buttonColor),
                                ),
                              )),
                      if (focus)
                        Positioned(
                            top: mq.size.height * 0.5 + 20,
                            child: Container(
                              width: mq.size.width,
                              child: Text(
                                toTime(state.timerValue.toInt()),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w100, fontSize: 42, color: Theme
                                    .of(context)
                                    .buttonColor),
                              ),
                            )),
                      if (!focus)
                        Positioned(
                          bottom: 64,
                          left: mq.size.width * 0.1,
                          child: InkWell(
                            onTap: () async {
                              var state = Provider.of<ApplicationState>(context, listen: false);
                              var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
                              var time = await dio.put(securePrefix + "/task/${widget.id}/initial",
                                  data: json.encode({"mode": MODE_TIMER}));
                              // print(time.data);
                              setState(() {
                                state.timerStart = DateTime.now();
                                state.timerValue = time.data["initial_timer"].toDouble();
                                state.initialTimerValue = state.timerValue;
                                state.timerDirection = time.data["timer_direction"];
                                state.focusTask = widget.id;
                                lastUpdated = DateTime.now();
                                focus = true;

                                Future.delayed(Duration(microseconds: 10), () async {
                                  var data = {
                                    "timer_start": state.initialTimerValue.toInt(),
                                    "timer_direction": state.timerDirection
                                  };
                                  await dio.put(securePrefix + "/task/${widget.id}/take", data: json.encode(data));
                                  state.timer = createTimer(state);
                                });
                              });
                            },
                            child: GlowContainer(
                              width: mq.size.width * 0.8,
                              color: widget.color,
                              // color: Theme.of(context).primaryColor.withOpacity(0.35),
                              glowColor: Theme
                                  .of(context)
                                  .primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              border: Border.all(color: Theme
                                  .of(context)
                                  .primaryColorLight),
                              borderRadius: BorderRadius.circular(32.0),
                              spreadRadius: 1.0,
                              child: Text(
                                "Секундомер",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Theme
                                    .of(context)
                                    .buttonColor),
                              ),
                            ),
                          ),
                        )
                    ],
                  ),
                )));
  }

  @override
  void initState() {
    setState(() {
      print("Initializing state");
      data = widget.data;
      focus = widget.focus;
      if (focus) {
        Future.delayed(Duration(microseconds: 10), () async {
          print("Timer run");
          widget.state.timer = Timer.periodic(Duration(seconds: 1), (timer) {
            setState(() {
              var now = DateTime.now();
              var diff = now
                  .difference(widget.state.timerStart)
                  .inSeconds;
              var tv = widget.state.initialTimerValue + diff * widget.state.timerDirection;
              if (tv <= 0) {
                //completed!
                tv = 0;
              }
              widget.state.timerValue = tv;
              lastUpdated = DateTime.now();
            });
          });
        });
      }
    });
  }
}
