import 'dart:async';

import 'package:aircube/model/state.dart';
import 'package:aircube/page/details.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/gestures/events.dart';
import 'package:provider/provider.dart';

import 'stars.dart';
import 'tooltip.dart';

class TimeLinePage extends StatelessWidget {
  Function prev;

  Function next;

  TimeLinePage(this.prev, this.next);

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(
      builder: (context, value, child) => TimeLineWidget(
          value.getCurrentActivity().name,
          value.getCurrentActivity().overrideColor,
          value.step,
          value.getActivitiesLength(),
          this.prev,
          this.next),
    );
  }
}

class TimeLinePageNew extends StatelessWidget {
  Function prev;

  Function next;

  TimeLinePageNew(this.prev, this.next);

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<ApplicationState>(context);
    //search for unsaved
    var notActivated = appState.activityNames
        .firstWhere((element) => !element.activated, orElse: () => null);
    if (notActivated == null) {
      notActivated = EventDescription("", Colors.grey, activated: false);
      // appState.activityNames.add(notActivated);
      appState.addEventDescription(notActivated);
    }
    // print(notActivated);
    var step = appState.activityNames.indexOf(notActivated);
    // print(step);
    appState.step = step;
    // print(appState.activityNames);

    return TimeLineWidget(
      appState.getCurrentActivity().name,
      appState.getCurrentActivity().overrideColor,
      appState.step,
      appState.getActivitiesLength(),
      this.prev,
      this.next,
      newActivity: true,
    );
  }
}

class TimeLineWidget extends StatefulWidget {
  int step;

  int steps;

  String name;

  Color color;

  Function prev;

  Function next;

  GlobalKey key;

  bool newActivity;

  TimeLineWidget(
      this.name, this.color, this.step, this.steps, this.prev, this.next,
      {this.newActivity = false});

  @override
  _TimeLineWidgetState createState() => _TimeLineWidgetState();
}

// GlobalKey timelineKey = GlobalKey();
// GlobalKey regionKey = GlobalKey();
class _TimeLineWidgetState extends State<TimeLineWidget> {
  GlobalKey timelineKey = GlobalKey();
  final _taskTimeKey = GlobalKey<FormState>();

  //todo: get from provider
  int start;
  int end;

  bool filled = false;

  int intervalDuration = 15;
  int intervals;

  int lastInterval = null;
  int dragStartInterval;
  Event lastEvent = null;
  SuperTooltip tooltip;
  Event selectedEvent = null;
  Event draggableEvent = null;
  Event editableEvent = null;
  int xShift = 0;
  bool isMoving;
  bool isResizing;
  int resizeSource;
  int originalDuration;

  Offset lastPosition;
  Offset lastMousePosition;

  String paddedNumber(int n) {
    if (n >= 10) return n.toString();
    return "0" + n.toString();
  }

  void closeTooltip() {
    if (tooltip != null) {
      try {
        tooltip.close();
      } catch (Exception) {}
    }
  }

  TextEditingController _hoursController;
  TextEditingController _minutesController;
  TextEditingController _hoursDurationController;
  TextEditingController _minutesDurationController;

  @override
  void initState() {
    var state = Provider.of<ApplicationState>(context, listen: false);
    start = state.awakeTime.hour * 60 + state.awakeTime.minute;
    end = state.sleepTime.hour * 60 + state.sleepTime.minute;
    // start = 9 * 60;
    // end = 23 * 60;
    var dayDuration = end - start;
    if (dayDuration < 0) {
      dayDuration += 24 * 60;
    }
    intervals = (dayDuration.toDouble() / intervalDuration).ceil();

    _hoursController = TextEditingController();
    _minutesController = TextEditingController();
    _hoursDurationController = TextEditingController();
    _minutesDurationController = TextEditingController();

    // print("Name=${widget.name}");
    // print("Color=${widget.color}");
  }

  String validateStartTime(hour, min, durationHour, durationMin) {
    var hours = int.tryParse(hour);
    if (hours == null) return "";
    var minutes = int.tryParse(min);
    if (minutes == null) return "";
    var durHours = int.tryParse(durationHour);
    if (durHours == null) return "";
    var durMinutes = int.tryParse(durationMin);
    if (durMinutes == null) return "";
    if (hours >= 24 ||
        minutes >= 60 ||
        durHours >= 24 ||
        durMinutes >= 60 ||
        durHours + durMinutes == 0) return "";

    var time = hours * 60 + minutes;
    if (time < start) {
      time += 24 * 60;
    }
    var realEnd = end;
    if (end < start) {
      realEnd += 24 * 60;
    }
    if (time + durHours * 60 + durMinutes > realEnd) return "";
    return null;
  }

  @override
  void didUpdateWidget(TimeLineWidget oldWidget) {
    setState(() {
      editableEvent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context);
    var realEnd = end;
    if (end < start) {
      realEnd += 24 * 60;
    }
    var xdelta = mq.size.width / 100;
    return Stack(children: [
      Positioned(
        width: mq.size.width,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: xdelta, vertical: 16),
          child: Consumer<ApplicationState>(
              builder: (context, value, child) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  widget.newActivity
                      ? Text("Новый вопрос ")
                      : Text(
                      "Вопрос ${widget.step + 1} из ${widget.steps}"),
                  if (!value.hasCurrentEvents() && !widget.newActivity)
                    TextButton(
                      child: Text("Пропустить"),
                      onPressed: () {
                        var state = Provider.of<ApplicationState>(context,
                            listen: false);
                        if (state.isNextStepAvailable()) {
                          state.nextStep();
                        } else {
                          widget.next();
                        }
                      },
                    )
                ],
              )),
        ),
      ),
      Positioned(
        top: 48,
        width: mq.size.width,
        height: 128,
        child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () {
              showContextMenu(lastMousePosition);
            },
            onTap: () {
              // print("Tapped");
              if (selectedEvent != null) {
                setState(() {
                  editableEvent = selectedEvent;
                  _hoursController.text =
                      paddedNumber(editableEvent.start ~/ 60);
                  _minutesController.text =
                      paddedNumber(editableEvent.start % 60);
                  _hoursDurationController.text =
                      paddedNumber(editableEvent.duration ~/ 60);
                  _minutesDurationController.text =
                      paddedNumber(editableEvent.duration % 60);
                });
              } else {
                // print("Add new");
                // print(lastInterval);
                if (lastInterval != null) {
                  var eventStart = start + lastInterval * intervalDuration;
                  if (eventStart >= 24 * 60) {
                    eventStart -= 24 * 60;
                  }
                  var newEvent = Event(this.widget.name, eventStart,
                      intervalDuration, this.widget.color, this.widget.step);
                  var state =
                  Provider.of<ApplicationState>(context, listen: false);
                  state.addEvent(newEvent);

                  setState(() {
                    editableEvent = state.getEvent(newEvent.id);
                    // print("Editable event: $editableEvent");
                    // print("Created event $editableEvent");
                    lastPosition = null;
                    var event = editableEvent;
                    Future.delayed(Duration(milliseconds: 200), () async {
                      highlightRegion(lastMousePosition, xdelta);
                      setState(() {
                        // print("Change state");
                        // print(event);
                        editableEvent = event;
                        selectedEvent = event;
                        // draggableEvent = event;
                        _hoursController.text =
                            paddedNumber(editableEvent.start ~/ 60);
                        _minutesController.text =
                            paddedNumber(editableEvent.start % 60);
                        _hoursDurationController.text =
                            paddedNumber(editableEvent.duration ~/ 60);
                        _minutesDurationController.text =
                            paddedNumber(editableEvent.duration % 60);
                      });
                    });
                  });
                }
              }
            },
            onHorizontalDragStart: (details) {
              // print("Drag started $details");
              // print("SelectedEvent: $selectedEvent");
              if (selectedEvent != null) {
                closeTooltip();
                draggableEvent = selectedEvent;
                editableEvent = selectedEvent;
                _hoursController.text = paddedNumber(editableEvent.start ~/ 60);
                _minutesController.text =
                    paddedNumber(editableEvent.start % 60);
                _hoursDurationController.text =
                    paddedNumber(editableEvent.duration ~/ 60);
                _minutesDurationController.text =
                    paddedNumber(editableEvent.duration % 60);
                dynamic customPaint = timelineKey.currentWidget;
                xShift = (details.localPosition.dx -
                    customPaint.painter
                        .minutesToPixels(selectedEvent.start))
                    .toInt();
                selectedEvent = null;
                dragStartInterval = lastInterval;
              }
            },
            onHorizontalDragUpdate: (details) {
              // print("Draggable event: $draggableEvent");
              if (draggableEvent != null) {
                dynamic customPaint = timelineKey.currentWidget;
                if (isMoving) {
                  // print("Local position: ${details.localPosition}");
                  // print("Check overlapped event");
                  double x = details.localPosition.dx - xShift;
                  double y = details.localPosition.dy;
                  Link link = customPaint.painter
                      .getExpandedLink(x: x, y: y, exclude: draggableEvent);
                  // print("Link is $link");
                  if (link == null) {
                    draggableEvent.temp = false;
                    var newInterval = getInterval(x);
                    // print("Moving to position: $newInterval");
                    if (newInterval != dragStartInterval) {
                      setState(() {
                        if (newInterval >= 0 && newInterval < intervals) {
                          var newStart = newInterval * intervalDuration + start;
                          var realEnd = end;
                          if (realEnd < start) {
                            realEnd += 24 * 60;
                          }
                          if (newStart >= start &&
                              newStart + draggableEvent.duration < realEnd) {
                            if (newStart >= 24 * 60) {
                              newStart -= 24 * 60;
                            }
                            draggableEvent.start = newStart;
                            _hoursController.text =
                                paddedNumber(draggableEvent.start ~/ 60);
                            _minutesController.text =
                                paddedNumber(draggableEvent.start % 60);

                            dragStartInterval = newInterval;
                          }
                        }
                      });
                    }
                  } else {
                    // print("Event: ${link.event.id}");
                    if (y >= link.boundary.top + (link.boundary.height * 0.7)) {
                      // print("Add new");
                      //add new
                    } else {
                      if (x < link.boundary.center.dx) {
                        // print("Add before");
                        //todo: check overlapping and day boundaries
                        setState(() {
                          draggableEvent.temp = true;
                          var newStart =
                              link.event.start - draggableEvent.duration;
                          if (newStart >= 24 * 60) {
                            newStart -= 24 * 60;
                          }
                          draggableEvent.start = newStart;
                          _hoursController.text =
                              paddedNumber(draggableEvent.start ~/ 60);
                          _minutesController.text =
                              paddedNumber(draggableEvent.start % 60);
                        });
                      } else {
                        setState(() {
                          draggableEvent.temp = true;
                          var newStart = link.event.start + link.event.duration;
                          if (newStart >= 24 * 60) {
                            newStart -= 24 * 60;
                          }
                          draggableEvent.start = newStart;
                          _hoursController.text =
                              paddedNumber(draggableEvent.start ~/ 60);
                          _minutesController.text =
                              paddedNumber(draggableEvent.start % 60);
                        });
                      }
                    }
                  }
                } else if (isResizing) {
                  double pixelDelta = details.localPosition.dx - resizeSource;
                  var newDuration = originalDuration +
                      customPaint.painter.pixelsToMinutes(pixelDelta);
                  // print("NewDuration: $newDuration");
                  // print("DE: ${draggableEvent.start + newDuration}");
                  // print("End: $end");

                  var realEnd = end;
                  if (realEnd < start) {
                    realEnd += 24 * 60;
                  }
                  if (newDuration >= 1 &&
                      draggableEvent.start + newDuration < realEnd) {
                    setState(() {
                      // print("Saved");
                      draggableEvent.duration = newDuration;
                      _hoursDurationController.text =
                          paddedNumber(draggableEvent.duration ~/ 60);
                      _minutesDurationController.text =
                          paddedNumber(draggableEvent.duration % 60);
                    });
                  }
                }
              }
            },
            onHorizontalDragEnd: (details) {
              setState(() {
                if (draggableEvent != null) {
                  draggableEvent.temp = false;
                }
              });
              draggableEvent = null;
            },
            onTapDown: (pos) {
              if (draggableEvent == null) {
                if (pos.localPosition.dx >= xdelta &&
                    pos.localPosition.dx < mq.size.width - xdelta) {
                  highlightRegion(pos.localPosition, xdelta);
                } else {
                  lastInterval = null;
                }
              }
            },
            onTapUp: (pos) {
              if (draggableEvent == null) {
                if (pos.localPosition.dx >= xdelta &&
                    pos.localPosition.dx < mq.size.width - xdelta) {
                  highlightRegion(pos.localPosition, xdelta);
                } else {
                  lastInterval = null;
                }
              }
            },
            child: MouseRegion(
                opaque: false,
                onEnter: (pos) {
                  if (pos.localPosition.dx >= xdelta &&
                      pos.localPosition.dx < mq.size.width - xdelta) {
                    highlightRegion(pos.localPosition, xdelta);
                  } else {
                    lastInterval = null;
                  }
                },
                onHover: (pos) {
                  if (draggableEvent == null) {
                    if (pos.localPosition.dx >= xdelta &&
                        pos.localPosition.dx < mq.size.width - xdelta) {
                      highlightRegion(pos.localPosition, xdelta);
                    } else {
                      lastInterval = null;
                    }
                  }
                },
                onExit: (_) {
                  closeTooltip();
                },
                child: PhysicalModel(
                  color: Colors.white,
                  elevation: 8,
                  child: Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: mq.size.width / 100),
                      width: mq.size.width - 2 * mq.size.width / 100,
                      height: 128,
                      color: Colors.black26,
                      child: Consumer<ApplicationState>(
                          builder: (context, value, child) => CustomPaint(
                              key: timelineKey,
                              painter: TimeLinePainter(
                                  intervals,
                                  intervalDuration,
                                  start,
                                  value.events,
                                  widget.step,
                                  mq.size.width / 100)))),
                ))),
      ),
      Positioned(
          top: 176,
          child: Container(
            width: mq.size.width,
            padding: EdgeInsets.symmetric(horizontal: xdelta, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(toHourMin(start), style: TextStyle(color: Colors.black38)),
                Text(toHourMin((start + realEnd) ~/ 2),
                    style: TextStyle(color: Colors.black38)),
                Text(
                  toHourMin(end),
                  style: TextStyle(color: Colors.black38),
                )
              ],
            ),
          )),
      Positioned(
        top: 216,
        width: mq.size.width,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: xdelta),
          child: PhysicalModel(
            elevation: 8,
            color: Colors.white,
            child: Container(
              child: SizedBox(
                  width: double.infinity,
                  height: widget.newActivity ? 180 : 168,
                  child: Form(
                      key: _taskTimeKey,
                      child: Column(children: [
                        !widget.newActivity
                            ? Row(children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: xdelta, vertical: 16.0),
                            child: Text(
                              this.widget.name,
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18),
                            ),
                          )
                        ])
                            : Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: xdelta, vertical: 16.0),
                          child: SizedBox(
                            width: mq.size.width,
                            child: Row(
                              children: [
                                Text("Название новой активности: ",
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54)),
                                SizedBox(
                                  width: mq.size.width * 0.5,
                                  child: TextField(
                                    onChanged: (val) {
                                      Future.delayed(
                                          Duration(milliseconds: 100),
                                              () async {
                                            var state =
                                            Provider.of<ApplicationState>(
                                                context,
                                                listen: false);
                                            state.setDescription(val);
                                            state.events.forEach((element) {
                                              if (element.step == state.step)
                                                element.name = val;
                                            });
                                          });
                                      // state.activityNames[state.step].name = val;
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        if (editableEvent == null)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                                !widget.newActivity
                                    ? "Нажмите на пустое место на временной шкале для добавления новой активности. Нажмите на созданную активность для редактирования. Для удаления, нажмите на активность правой кнопкой мыши или долгим нажатием. Затем оцените её по 8 шкалам."
                                    : "",
                                softWrap: true,
                                maxLines: 5,
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black54)),
                          ),
                        if (editableEvent != null)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: xdelta),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: (mq.size.width - 4 * xdelta) / 2,
                                    height: 16,
                                    child: Text("Время начала")),
                                SizedBox(
                                  width: (mq.size.width - 4 * xdelta) / 2,
                                  height: 56,
                                  child: Row(children: [
                                    SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: TextFormField(
                                        controller: _hoursController,
                                        autovalidateMode: AutovalidateMode.always,
                                        //   //todo: overlap problem
                                        validator: (value) {
                                          return validateStartTime(
                                              value,
                                              _minutesController.value.text,
                                              _hoursDurationController.value.text,
                                              _minutesDurationController
                                                  .value.text);
                                        },
                                        keyboardType: TextInputType.number,
                                        cursorColor: Colors.deepPurpleAccent,
                                        decoration: InputDecoration(
                                            errorMaxLines: 1,
                                            errorStyle: TextStyle(
                                                fontSize: 0.1,
                                                height: 0,
                                                color: Colors.transparent),
                                            errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.red)),
                                            border: OutlineInputBorder()),
                                        onChanged: (v) {
                                          // print("Minutes: ${_minutesController}");
                                          var newStart = int.parse(
                                              _minutesController.value.text) +
                                              int.parse(v) * 60;
                                          // print("New start: $newStart");
                                          // print("Start: $start");
                                          // print("End: $end");
                                          int realEnd = end;
                                          if (end < start) {
                                            realEnd += 24 * 60;
                                          }
                                          if (newStart < start) {
                                            newStart = 24 * 60 + newStart;
                                          }
                                          if (newStart + editableEvent.duration <=
                                              realEnd &&
                                              _taskTimeKey.currentState
                                                  .validate()) {
                                            setState(() {
                                              // print("Set from hours $newStart");
                                              editableEvent.start = newStart;
                                            });
                                          }
                                          // setState(() {
                                          //   _startTimeKey.currentState.validate();
                                          // });
                                          // if (!_startTimeKey.currentState.validate()) {
                                          //   ScaffoldMessenger.of(context)
                                          //       .showSnackBar(SnackBar(content: Text(_startTimeKey.currentState.)));
                                          // }
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9]')),
                                          LengthLimitingTextInputFormatter(2)
                                        ],
                                      ),
                                    ),
                                    Text(":"),
                                    SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: TextFormField(
                                        controller: _minutesController,
                                        autovalidateMode: AutovalidateMode.always,
                                        decoration: InputDecoration(
                                            errorMaxLines: 1,
                                            errorStyle: TextStyle(
                                                fontSize: 0.1,
                                                height: 0,
                                                color: Colors.transparent),
                                            errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.red)),
                                            border: OutlineInputBorder()),
                                        validator: (value) {
                                          return validateStartTime(
                                              _hoursController.value.text,
                                              value,
                                              _hoursDurationController.value.text,
                                              _minutesDurationController
                                                  .value.text);
                                        },
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) {
                                          var newStart = int.parse(
                                              _hoursController
                                                  .value.text) *
                                              60 +
                                              int.parse(v);
                                          int realEnd = end;
                                          if (end < start) {
                                            realEnd += 24 * 60;
                                          }
                                          if (newStart < start) {
                                            newStart = 24 * 60 + newStart;
                                          }
                                          if (newStart + editableEvent.duration <=
                                              realEnd &&
                                              _taskTimeKey.currentState
                                                  .validate()) {
                                            setState(() {
                                              // print("Set from minutes $newStart");
                                              editableEvent.start = newStart;
                                            });
                                          }
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9]')),
                                          LengthLimitingTextInputFormatter(2)
                                        ],
                                      ),
                                    )
                                  ]),
                                )
                              ],
                            ),
                          ),
                        if (editableEvent != null)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: xdelta,),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: (mq.size.width - 4 * xdelta) / 2,
                                    height: 16,
                                    child: Text(
                                        "Продолжительность (часы и минуты)")),
                                SizedBox(
                                  width: (mq.size.width - 4 * xdelta) / 2,
                                  child: Row(children: [
                                    SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: TextFormField(
                                        controller: _hoursDurationController,
                                        autovalidateMode:
                                        AutovalidateMode.always,
                                        //   //todo: overlap problem
                                        validator: (value) {
                                          return validateStartTime(
                                              _hoursController.value.text,
                                              _minutesController.value.text,
                                              value,
                                              _minutesDurationController
                                                  .value.text);
                                        },
                                        keyboardType: TextInputType.number,
                                        cursorColor: Colors.deepPurpleAccent,
                                        decoration: InputDecoration(
                                            errorMaxLines: 1,
                                            errorStyle: TextStyle(
                                                fontSize: 0.1,
                                                height: 0,
                                                color: Colors.transparent),
                                            errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.red)),
                                            border: OutlineInputBorder()),
                                        onChanged: (v) {
                                          var newDuration = int.parse(
                                              _minutesDurationController
                                                  .value.text) +
                                              int.parse(v) * 60;
                                          int realEnd = end;
                                          if (end < start) {
                                            realEnd += 24 * 60;
                                          }
                                          var newStart = editableEvent.start;
                                          if (newStart < start) {
                                            newStart = 24 * 60 + newStart;
                                          }
                                          if (newDuration > 0 &&
                                              newStart + newDuration <=
                                                  realEnd &&
                                              _taskTimeKey.currentState
                                                  .validate()) {
                                            setState(() {
                                              // print("Set from hours $newStart");
                                              editableEvent.duration =
                                                  newDuration;
                                            });
                                          }
                                          // setState(() {
                                          //   _startTimeKey.currentState.validate();
                                          // });
                                          // if (!_startTimeKey.currentState.validate()) {
                                          //   ScaffoldMessenger.of(context)
                                          //       .showSnackBar(SnackBar(content: Text(_startTimeKey.currentState.)));
                                          // }
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9]')),
                                          LengthLimitingTextInputFormatter(2)
                                        ],
                                      ),
                                    ),
                                    Text(":"),
                                    //todo: validate 0-59
                                    SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: TextFormField(
                                        controller: _minutesDurationController,
                                        autovalidateMode:
                                        AutovalidateMode.always,
                                        decoration: InputDecoration(
                                            errorMaxLines: 1,
                                            errorStyle: TextStyle(
                                                fontSize: 0.1,
                                                height: 0,
                                                color: Colors.transparent),
                                            errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.red)),
                                            border: OutlineInputBorder()),
                                        validator: (value) {
                                          return validateStartTime(
                                              _hoursController.value.text,
                                              _minutesController.value.text,
                                              _hoursDurationController
                                                  .value.text,
                                              value);
                                        },
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) {
                                          var newDuration = int.parse(
                                              _hoursDurationController
                                                  .value.text) *
                                              60 +
                                              int.parse(v);
                                          int realEnd = end;
                                          if (end < start) {
                                            realEnd += 24 * 60;
                                          }
                                          var newStart = editableEvent.start;
                                          if (newStart < start) {
                                            newStart = 24 * 60 + newStart;
                                          }

                                          if (newDuration > 0 &&
                                              newStart + newDuration <=
                                                  realEnd &&
                                              _taskTimeKey.currentState
                                                  .validate()) {
                                            setState(() {
                                              // print("Set from minutes $newStart");
                                              editableEvent.duration =
                                                  newDuration;
                                            });
                                          }
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9]')),
                                          LengthLimitingTextInputFormatter(2)
                                        ],
                                      ),
                                    )
                                  ]),
                                )
                              ],
                            ),
                          ),
                      ]))),
            ),
          ),
        ),
      ),
      Consumer<ApplicationState>(builder: (context, value, child) {
        return Positioned(
            width: mq.size.width,
            top: 388,
            child: ScrollableStars(value.step, null, 0, [0,0,0,0,0,0,0,0], key: UniqueKey()));
      }),
      Positioned(
          bottom: 0,
          child: Container(
            width: mq.size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: xdelta, vertical: 8.0),
                  child: OutlinedButton(
                    onPressed: () {
                      var value =
                      Provider.of<ApplicationState>(context, listen: false);
                      if (value.isPrevStepAvailable() && !widget.newActivity) {
                        value.prevStep();
                      } else {
                        if (widget.newActivity) {
                          value.events = value.events
                              .where((element) => element.step != value.step)
                              .toList();
                          if (value.scores.containsKey(value.step)) {
                            value.scores[value.step] = [
                              null,
                              null,
                              null,
                              null,
                              null,
                              null,
                              null,
                              null
                            ];
                          }
                        }
                        widget.prev();
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Назад"),
                    ),
                    style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30))),
                  ),
                ),
                Consumer<ApplicationState>(
                    builder: (context, value, child) => Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: xdelta, vertical: 8.0),
                      child: OutlinedButton(
                        onPressed: () {
                          if (widget.newActivity) {
                            if (value.hasCurrentEvents() &&
                                value.checkScoreFilled() &&
                                value.activityNames[value.step].name
                                    .isNotEmpty) {
                              value.activate();
                              widget.next();
                            }
                          } else {
                            if (value.hasCurrentEvents() &&
                                value.checkScoreFilled()) {
                              if (value.isNextStepAvailable()) {
                                value.save();
                                value.nextStep();
                              } else {
                                widget.next();
                              }
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Далее",
                              style: TextStyle(
                                color: value.hasCurrentEvents() &&
                                    value.checkScoreFilled() &&
                                    value.activityNames[value.step].name
                                        .isNotEmpty
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                              )),
                        ),
                        style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: value.hasCurrentEvents() &&
                                    value.checkScoreFilled() &&
                                    value.activityNames[value.step].name
                                        .isNotEmpty
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                                width: value.hasCurrentEvents() &&
                                    value.checkScoreFilled() &&
                                    value.activityNames[value.step].name
                                        .isNotEmpty
                                    ? 2
                                    : 1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30))),
                      ),
                    )),
              ],
            ),
          ))
    ]);
  }

  showContextMenu(Offset position) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final menuItem = await showMenu<int>(
        context: context,
        items: [
          PopupMenuItem(child: Text('Удалить'), value: 1),
        ],
        position:
        RelativeRect.fromSize(position & Size(48.0, 48.0), overlay.size));
    // Check if menu item clicked
    switch (menuItem) {
      case 1:
        var state = Provider.of<ApplicationState>(context, listen: false);
        state.removeEvent(selectedEvent.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Удалено'),
          behavior: SnackBarBehavior.floating,
        ));
        break;
      default:
    }
  }

  Future<void> _onPointerDown(PointerDownEvent event) async {
    // Check if right mouse button clicked
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons == kSecondaryMouseButton) {
      // print(selectedEvent);
      if (selectedEvent != null) {
        showContextMenu(event.position);
      }
    }
  }

  String toHourMin(int shift) {
    var hour = (shift / 60).floor();
    var minutes = shift % 60;
    return "${paddedNumber(hour)}:${paddedNumber(minutes)}";
  }

  void highlightRegion(Offset pos, double xdelta) {
    lastMousePosition = pos;
    lastPosition = pos;
    lastPosition = Offset(lastPosition.dx - xdelta, lastPosition.dy);
    dynamic customPaint = timelineKey.currentWidget;
    Link link = customPaint.painter.getLink(position: lastPosition);
    if (link == null) {
      if (getInterval(lastPosition.dx) != lastInterval) {
        if (tooltip != null) {
          try {
            tooltip.close();
          } catch (Exception) {}
        }
        showTimeTooltip(lastPosition, xdelta);
        lastEvent = null;
        draggableEvent = null;
        selectedEvent = null;
      }
    } else {
      Event event = link.event;
      Rect boundary = link.boundary;
      if (event != lastEvent) {
        if (tooltip != null) {
          try {
            tooltip.close();
          } catch (Exception) {}
        }
        showTextTooltip(lastPosition, event.name, boundary.center.dx, xdelta);
        lastEvent = event;
        lastInterval = null;
      }
      if (widget.step == event.step) {
        //todo: fix scale
        if (lastPosition.dx >
            boundary.right - MediaQuery.of(context).size.width / 200) {
          selectedEvent = event;
          isResizing = true;
          isMoving = false;
          resizeSource = lastPosition.dx.toInt();
          originalDuration = event.duration;
        } else {
          selectedEvent = event;
          isMoving = true;
          isResizing = false;
        }
      } else {
        selectedEvent = null;
      }
    }
  }

  int getInterval(double dx) {
    dynamic customPaint = timelineKey.currentWidget;
    return customPaint.painter.getInterval(dx);
  }

  void showTimeTooltip(Offset position, double xdelta) {
    dynamic customPaint = timelineKey.currentWidget;
    var interval = customPaint.painter.getInterval(position.dx);
    var timeshift = (start + intervalDuration * interval) % (24 * 60);
    var intervalCenter = customPaint.painter.getIntervalCenter(position.dx);

    showTextTooltip(position, toHourMin(timeshift), intervalCenter, xdelta);
  }

  void showTextTooltip(Offset position, String text, double x, double xdelta) {
    var renderBox = context.findRenderObject() as RenderBox;

    dynamic customPaint = timelineKey.currentWidget;
    var interval = customPaint.painter.getInterval(position.dx);
    lastInterval = interval;
    //todo: convert to global!
    // print(renderBox.size);
    // var targetGlobalCenter = renderBox
    //     .localToGlobal(renderBox.size.center(Offset.zero), ancestor: overlay);
    var targetGlobalCenter = Offset(0, 0) & Size(renderBox.size.width, 128);
    tooltip = SuperTooltip(
        left: (x - 25 + xdelta < 0)
            ? 0
            : ((x - 25 + xdelta < renderBox.size.width - 75)
            ? x - 25 + xdelta
            : renderBox.size.width - 75),
        popupDirection: TooltipDirection.down,
        arrowTipDistance: 15.0,
        arrowBaseWidth: 20.0,
        arrowLength: 20.0,
        borderColor: Colors.green,
        borderWidth: 1.0,
        snapsFarAwayVertically: false,
        containsBackgroundOverlay: false,
        // showCloseButton: ShowCloseButton.inside,
        hasShadow: false,
        // touchThrougArea: new Rect.fromLTWH(targetGlobalCenter.dx - 400,
        //     targetGlobalCenter.dy - 100, 200.0, 160.0),
        // touchThrougArea: new Rect.fromLTWH(0, 0, 100, 100),
        // touchThroughAreaShape: ClipAreaShape.rectangle,
        targetPosition:
        Offset(x + xdelta, targetGlobalCenter.bottomCenter.dy + 15),
        content: new Material(
            child: Container(
              // padding: const EdgeInsets.only(top: 10.0),
              child: Text(text),
            )));
    tooltip.show(context);
  }
}

class SimplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // TODO: implement paint
    var paint = Paint();
    paint.color = Color(0xFFFF0000);
    paint.style = PaintingStyle.stroke;
    canvas.drawRect(Offset(0, 0) & Size(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
    // throw UnimplementedError();
  }
}

class TimeLinePainter extends CustomPainter {
  int intervals;
  double intervalWidth;
  int start;
  int intervalDuration;
  int step;
  List<Event> events;
  List<Link> links;
  double xdelta;

  TimeLinePainter(this.intervals, this.intervalDuration, this.start,
      this.events, this.step, this.xdelta);

  Link getLink({Offset position, Event exclude}) {
    return links.firstWhere(
            (link) =>
        position >= link.boundary.topLeft &&
            position < link.boundary.bottomRight &&
            (exclude == null || link.event != exclude),
        orElse: () => null);
  }

  Link getExpandedLink({double x, double y, Event exclude}) {
    // print("Getting exlink");
    return links.firstWhere((link) {
      var start = getInterval(link.boundary.left) * intervalWidth;
      var end = getInterval(link.boundary.right) * intervalWidth;
      if ((link.boundary.right - end * intervalWidth).abs() > 0.5) {
        end += intervalWidth;
      }
      var ownStart = minutesToPixels(exclude.start);
      var ownEnd = minutesToPixels(exclude.start + exclude.duration);
      // print("Position: ${x}, start: $ownStart, end: $ownEnd");
      if (x.toInt() < ownStart.toInt() || x.toInt() > ownEnd.toInt()) {
        return false;
      }
      // var ownCenter = (ownStart + ownEnd) / 2;
      // if (((ownStart > start) && (position.dx > ownCenter)) ||
      //     (ownStart < start) && (position.dx < ownCenter)) {
      //   return false;
      // }
      // print("For link boundary ${link.boundary} start: $start, end: $end");
      // print("Own start: $ownStart, Own end: $ownEnd");
      // print("Conditions [1/5]: ${y >= link.boundary.top}");
      // print("[2/5] ${y < link.boundary.bottom}");
      // print("[3/5] ${(ownEnd >= start && ownStart <= end)}");
      // print("[4/5] ${(ownStart <= end && ownEnd >= start)}");
      // print("[5/5] ${(exclude == null || link.event != exclude)}");
      return y >= link.boundary.top &&
          y < link.boundary.bottom &&
          ((ownEnd >= start && ownStart < end) ||
              (ownStart < end && ownEnd >= start)) &&
          (exclude == null || link.event != exclude);
    }, orElse: () => null);
  }

  int timeOfDay(double x) {
    return ((x / intervalWidth) * intervalDuration).floor() + start;
  }

  int getInterval(double x) {
    return (x / intervalWidth).floor();
  }

  double getIntervalCenter(double x) {
    var interval = getInterval(x);
    return interval * intervalWidth + intervalWidth / 2;
  }

  int pixelsToMinutes(double dx) {
    return (dx / intervalWidth * intervalDuration).floor();
  }

  double minutesToPixels(int minutes) {
    int delta = minutes - start;
    if (delta < 0) {
      delta += 24 * 60;
    }
    return (delta.toDouble() / intervalDuration) * intervalWidth;
  }

  @override
  void paint(Canvas canvas, Size size) {
    links = [];
    // print(size);
    var paint = Paint();
    paint.color = Color(0xFFFFFFFF);
    paint.style = PaintingStyle.fill;
    canvas.drawRect(Offset(0, 0) & Size(size.width, size.height), paint);

    // canvas.drawRect(
    //     Offset(0, 0) & Size(size.width, size.height),
    //     Paint()
    //       ..color = Color(0xFFFF0000)
    //       ..style = PaintingStyle.stroke
    //       ..strokeWidth = 5);

    intervalWidth = (size.width) / intervals;

    var boxPaint = Paint()
      ..color = Color(0xff77777)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < intervals; i++) {
      canvas.drawRect(
          Offset(i * intervalWidth, 0) & Size(intervalWidth, size.height),
          boxPaint);
    }

    //draw events
    double minuteWidth = intervalWidth / intervalDuration;
    var eventGroups = [];
    for (int i = 0; i < events.length; i++) {
      if (events[i].step > step) {
        continue;
      }
      var group = <Event>[];
      // print("Testing ${events[i]}");
      var existingGroup = eventGroups
          .firstWhere((group) => group.contains(events[i]), orElse: () => null);
      // print("EG=$existingGroup");
      if (existingGroup != null) {
        group = existingGroup;
      }

      for (int j = 0; j < events.length; j++) {
        if (i == j) continue;
        if (events[j].start >= events[i].start + events[i].duration ||
            events[j].start + events[j].duration <= events[i].start) continue;
        if (group.contains(events[j])) continue;
        // print("Checking ${events[j]}");
        var exGroup = eventGroups.firstWhere(
                (group) => group.contains(events[j]),
            orElse: () => null);
        if (exGroup == null) {
          group.add(events[j]);
        } else {
          group.forEach((element) {
            if (!exGroup.contains(element)) exGroup = exGroup + [element];
          });
          existingGroup = exGroup;
        }
      }
      if (existingGroup == null) {
        if (group.isNotEmpty) {
          // print("Adding new group");
          group = [events[i]] + group;
          // print("Group: $group");
          eventGroups.add(group);
        } else {
          // print("Adding new single event");
          eventGroups.add([events[i]]);
        }
      } else {
        // print("EX Group: $existingGroup");
      }
    }
    // print(eventGroups);
    for (int i = 0; i < eventGroups.length; i++) {
      List<Event> event = eventGroups[i];
      event.asMap().forEach((key, value) {
        addActivity(value, minuteWidth, size, canvas, key, event.length);
      });
    }
  }

  void addActivity(Event event, double minuteWidth, Size size, Canvas canvas,
      int rowno, int rows) {
    var timeDelta = event.start - start;
    if (timeDelta < 0) {
      timeDelta = 24 * 60 + timeDelta;
    }
    Rect boundary =
    Offset(timeDelta * minuteWidth, rowno / rows * size.height) &
    Size(event.duration * minuteWidth, size.height / rows);
    var color = event.color;
    if (event.step < step) {
      //desaturate
      double f = 0.7; // desaturate by 70%
      double L = 0.3 * color.red + 0.6 * color.green + 0.1 * color.blue;
      double new_r = color.red + f * (L - color.red);
      double new_g = color.green + f * (L - color.green);
      double new_b = color.blue + f * (L - color.blue);
      color = Color.fromRGBO(new_r.toInt(), new_g.toInt(), new_b.toInt(), 0.6);
    } else if (event.temp) {
      double f = 0.3; // desaturate by 30%
      double L = 0.3 * color.red + 0.6 * color.green + 0.1 * color.blue;
      double new_r = color.red + f * (L - color.red);
      double new_g = color.green + f * (L - color.green);
      double new_b = color.blue + f * (L - color.blue);
      color = Color.fromRGBO(new_r.toInt(), new_g.toInt(), new_b.toInt(), 0.8);
    }
    canvas.drawRect(
        boundary,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
    links.add(Link(boundary, event));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }
}