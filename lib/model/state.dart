import 'package:aircube/model/survey.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum Gender { female, male }


class Event {
  String id;

  String name;

  int start;

  int duration;

  Color color;

  int step;

  bool temp = false;

  Event(this.name, this.start, this.duration, this.color, this.step) {
    this.id = Uuid().v4();
  }

  @override
  String toString() {
    return "Event ${id}";
  }
}

class Link {
  Rect boundary;

  Event event;

  Link(this.boundary, this.event);
}

class ApplicationState with ChangeNotifier {
  String uuid;

  var activityNames = [
    EventDescription("Завтрак", Color.fromRGBO(0x34, 0xE0, 0x50, 1.0)),
    EventDescription("Обед", Color.fromRGBO(0x12, 0xA5, 0xE, 1.0)),
    EventDescription("Ужин", Color.fromRGBO(0x13, 0x69, 0x11, 1.0)),
    EventDescription(
        "Другие приемы пищи", Color.fromRGBO(0x32, 0xBE, 0x71, 1.0)),
    EventDescription("Принять душ", Color.fromRGBO(0x3, 0x9B, 0xED, 1.0)),
    EventDescription("Почистить зубы", Color.fromRGBO(0x8, 0x67, 0xB5, 1.0)),
    EventDescription("Уборка дома", Color.fromRGBO(0x24, 0x31, 0xD4, 1.0)),
    EventDescription("Мытье посуды", Color.fromRGBO(0x4, 0x1F, 0x5F, 1.0)),
    EventDescription(
        "Приготовление пищи", Color.fromRGBO(0x7C, 0xDF, 0xC, 1.0)),
    EventDescription("Посещение туалета", Color.fromRGBO(0x33, 0x4, 0x6A, 1.0)),
    EventDescription("Просмотр почты", Color.fromRGBO(0xE2, 0xA8, 0x14, 1.0)),
    EventDescription("Просмотр сериалов", Color.fromRGBO(0xDC, 0xE, 0xDC, 1.0)),
    EventDescription(
        "Просмотр новостей", Color.fromRGBO(0x2B, 0x27, 0x27, 1.0)),
    EventDescription("Чтение фантастики", Color.fromRGBO(0xBB, 0x4C, 0x7, 1.0)),
    EventDescription("Чтение детективов", Color.fromRGBO(0x64, 0x6, 0x6, 1.0)),
    EventDescription("Чтение художественной литературы",
        Color.fromRGBO(0xFC, 0x4B, 0x7, 1.0)),
    EventDescription(
        "Чтение научной литературы", Color.fromRGBO(0xFF, 0x62, 0x2, 1.0)),
    EventDescription(
        "Прослушивание аудиокниг", Color.fromRGBO(0xED, 0xA5, 0x10, 1.0)),
    EventDescription(
        "Составление презентации", Color.fromRGBO(0xF7, 0xE6, 0x6, 1.0)),
    EventDescription("Медитация", Color.fromRGBO(0x3, 0xFC, 0xFC, 1.0)),
    EventDescription(
        "Упражнения на гибкость", Color.fromRGBO(0x68, 0x40, 0x79, 1.0)),
    EventDescription("Йога", Color.fromRGBO(0x99, 0x1C, 0xEF, 1.0)),
    EventDescription(
        "Силовые упражнения", Color.fromRGBO(0x58, 0x9, 0xA4, 1.0)),
    EventDescription(
        "Кардио упражнения", Color.fromRGBO(0x39, 0x24, 0xA0, 1.0)),
    EventDescription("Прогулка", Color.fromRGBO(0x38, 0x82, 0x70, 1.0)),
    EventDescription("Пробежка", Color.fromRGBO(0x92, 0xAF, 0x3A, 1.0)),
    EventDescription("Путь на работу", Color.fromRGBO(0xE6, 0x93, 0xF5, 1.0)),
    EventDescription("Путь домой", Color.fromRGBO(0xCD, 0x2F, 0xEA, 1.0)),
    EventDescription("Просмотр фильмов", Color.fromRGBO(0xA0, 0x81, 0xD2, 1.0)),
    EventDescription("Совещание", Color.fromRGBO(0x85, 0x83, 0x7, 1.0)),
    EventDescription(
        "Взаимодействие с соцсетями", Color.fromRGBO(0x6F, 0x3, 0x3, 1.0)),
    EventDescription("Просмотр YouTube", Color.fromRGBO(0xC6, 0x7, 0x7, 1.0)),
    EventDescription(
        "Прослушивание подкастов", Color.fromRGBO(0xF3, 0x6D, 0x6D, 1.0)),
    EventDescription(
        "Прослушивание музыки", Color.fromRGBO(0x14, 0xC8, 0xA7, 1.0)),
    EventDescription("Игра на музыкальном инструменте",
        Color.fromRGBO(0xBE, 0xB9, 0x9, 1.0)),
    EventDescription(
        "Написание кода программы", Color.fromRGBO(0x1, 0x28, 0x21, 1.0)),
    EventDescription("Практика письма", Color.fromRGBO(0xA5, 0x8D, 0x3B, 1.0)),
    EventDescription(
        "Изучение иностранного языка", Color.fromRGBO(0x2D, 0xC1, 0xDE, 1.0)),
    EventDescription("Компьютерные игры", Color.fromRGBO(0x4, 0x52, 0x45, 1.0)),
  ];

  getCurrentActivity() {
    return activityNames[step];
  }

  getActivitiesLength() {
    return activityNames.length;
  }

  addEventDescription(EventDescription eventDescription) {
    activityNames.add(eventDescription);
    var last = activityNames.length - 1;
    scores[last] = [null, null, null, null, null, null, null, null];
    if (scrollPositions.length < last + 1) {
      scrollPositions.add(0);
    }
    //print(activityNames);
    // notifyListeners();
  }

  ApplicationState() {
    uuid = Uuid().v4();
    step = 0;
    events = [];
    scrollPositions = [];
    for (int i = 0; i < activityNames.length; i++) {
      scrollPositions.add(0);
    }
  }

  serialize() {
    var result = {
      "uuid": uuid,
      "step": step,
      "gender": _gender == Gender.male ? "M" : "F",
      "age": _age,
      "maritalStatus": _maritalStatus,
      "educationLevel": _educationLevel,
      "awakeTime": "${_awakeTime?.hour}:${_awakeTime?.minute}",
      "sleepTime": "${_sleepTime?.hour}:${_sleepTime?.minute}",
      "events": events
          .map((e) => {
        "name": e.name,
        "step": e.step,
        "start": e.start,
        "duration": e.duration,
        "id": e.id,
        "scores": scores[e.step],
      })
          .toList()
    };
    // print(result);
    return result;
  }

  setDescription(String name) {
    activityNames[this.step].name = name;
    // print("Activity name for step: ${this.step} set to $name");
    notifyListeners();
  }

  activate() {
    activityNames[this.step].activated = true;
  }

  bool _gender;
  int _age;
  String _maritalStatus;
  String _educationLevel;
  TimeOfDay _awakeTime;
  TimeOfDay _sleepTime;
  String token;
  String name;
  Survey survey;

  set awakeTime(TimeOfDay _awakeTime) {
    this._awakeTime = _awakeTime;
    notifyListeners();
  }

  set sleepTime(TimeOfDay _sleepTime) {
    this._sleepTime = _sleepTime;
    notifyListeners();
  }

  TimeOfDay get awakeTime => this._awakeTime;

  TimeOfDay get sleepTime => this._sleepTime;

  void save() {
    // var result = serialize();
    // Dio().post("https://survey.aircube.tech/backend/",
    //     data: json.encode(result));
  }

  void set gender(bool gender) {
    _gender = gender;
    notifyListeners();
  }

  bool get gender => _gender;

  void set age(int age) {
    _age = age;
    notifyListeners();
  }

  int get age => _age;

  void set maritalStatus(String maritalStatus) {
    _maritalStatus = maritalStatus;
    notifyListeners();
  }

  String get maritalStatus => _maritalStatus;

  void set educationLevel(String educationLevel) {
    _educationLevel = educationLevel;
    notifyListeners();
  }

  String get educationLevel => _educationLevel;

  var scores = <int, List<int>>{};
  var events = <Event>[];
  var scrollPositions = <double>[];
  var step;

  setScore(int grade, int value) {
    if (!scores.keys.contains(step)) {
      scores[step] = [null, null, null, null, null, null, null, null];
    }
    scores[step][grade] = value;
    notifyListeners();
  }

  getScore(int grade) {
    if (!scores.keys.contains(step)) {
      return 0;
    }
    return scores[step][grade];
  }

  checkScoreFilled() {
    if (!scores.keys.contains(step)) {
      return false;
    }
    return scores[step]
        .firstWhere((element) => element == null, orElse: () => -1) ==
        -1;
  }

  hasCurrentEvents() {
    // print("Check current events at step $step");
    // print(events);
    // if (events.length > 0) {
    //   print(events[0].step);
    // }
    var d = events.firstWhere((element) => element.step == step,
        orElse: () => null) !=
        null;
    // print("Result is $d");
    return d;
  }

  addEvent(Event event) {
    events.add(event);
    notifyListeners();
  }

  getEvent(String id) {
    return events.firstWhere((element) => element.id == id, orElse: () => null);
  }

  removeEvent(String uuid) {
    events.removeWhere((element) => element.id == uuid);
    notifyListeners();
  }

  setStart(Event event, int start) {
    event.start = start;
    notifyListeners();
  }

  setDuration(Event event, int duration) {
    event.duration = duration;
    notifyListeners();
  }

  isNextStepAvailable() {
    return step < activityNames.length - 1;
  }

  isPrevStepAvailable() {
    return step > 0;
  }

  nextStep() {
    if (isNextStepAvailable()) {
      step++;
      notifyListeners();
    }
  }

  prevStep() {
    if (isPrevStepAvailable()) {
      step--;
      notifyListeners();
    }
  }
}

class EventDescription {
  String name;

  Color color;

  bool activated;

  EventDescription(this.name, this.color, {this.activated = true});
}
