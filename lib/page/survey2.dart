import 'package:aircube/model/survey.dart';
import 'package:day_night_time_picker/day_night_time_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../model/state.dart';
import 'main.dart';


class SurveySecond extends StatefulWidget {
  SurveySecond();

  @override
  _SurveySecondState createState() => _SurveySecondState();
}

class _SurveySecondState extends State<SurveySecond> {
  bool correct = false;

  updateState(ApplicationState state) {
    setState(() {
      correct = state.educationLevel != null &&
          state.educationLevel.isNotEmpty &&
          state.maritalStatus != null &&
          state.maritalStatus.isNotEmpty &&
          state.gender != null &&
          state.age != null;
    });
  }

  String paddedNumber(int n) {
    if (n < 10) return "0" + n.toString();
    return n.toString();
  }


  Future<bool> saveSurvey(Survey survey) async {
    try {
      print(securePrefix + "/accounts/survey");
      await dio.post(securePrefix + "/accounts/survey", data: survey.toJSON());
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Dio dio;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    var state = Provider.of<ApplicationState>(context, listen: false);
    dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}))
      ..interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
    setState(() {
      _awakeTime = state.awakeTime;
      _sleepTime = state.sleepTime;
    });
  }

  String formatTOD(TimeOfDay tod) {
    return paddedNumber(tod.hour) + ":" + paddedNumber(tod.minute);
  }

  TimeOfDay _awakeTime;
  TimeOfDay _sleepTime;

  void onAwakeTimeChanged(TimeOfDay newAwakeTime) {
    var state = Provider.of<ApplicationState>(context, listen: false);
    state.awakeTime = newAwakeTime;

    setState(() {
      _awakeTime = newAwakeTime;
    });
  }

  void onSleepTimeChanged(TimeOfDay newSleepTime) {
    var state = Provider.of<ApplicationState>(context, listen: false);
    state.sleepTime = newSleepTime;

    setState(() {
      _sleepTime = newSleepTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer <ApplicationState>(
        builder: (context, state, child) =>
            KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
              return Stack(children: [
                if (!isKeyboardVisible)
                  Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                          height: 96,
                          padding: EdgeInsets.only(top: 48),
                          child: Image.asset("assets/logo.png"))),
                Center(
                  child: Stack(
                      children: [
                        SingleChildScrollView(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                        'Введите, пожалуйста, примерное время, в которое вы регулярно просыпаетесь и засыпаете.'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 16, top: 8),
                                    child: Row(children: [
                                      Text(
                                        'Время пробуждения',
                                        style: TextStyle(
                                          fontSize: 16,
                                          // fontWeight: FontWeight.bold,
                                        ),
                                        // textAlign: TextAlign.right,
                                      ),
                                    ]),
                                  ),
                                  if (_awakeTime != null)
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text("${formatTOD(_awakeTime)}"),
                                    ),
                                  OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).push(showPicker(
                                          blurredBackground: true,
                                          value: _awakeTime ??
                                              TimeOfDay(hour: 8, minute: 0),
                                          onChange: onAwakeTimeChanged,
                                          context: context,
                                          is24HrFormat: true,
                                          cancelText: ' Отмена',
                                          okText: 'Ок',
                                          hourLabel: 'часы',
                                          minuteLabel: 'минуты',
                                        )),
                                    child: Text('Выбрать время пробуждения'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 16, top: 8),
                                    child: Row(children: [
                                      Text(
                                        'Время засыпания',
                                        style: TextStyle(
                                          fontSize: 16,
                                          // fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ]),
                                  ),
                                  if (_sleepTime != null)
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text("${formatTOD(_sleepTime)}"),
                                    ),
                                  OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).push(showPicker(
                                          blurredBackground: true,
                                          value: _sleepTime ??
                                              TimeOfDay(hour: 23, minute: 0),
                                          onChange: onSleepTimeChanged,
                                          context: context,
                                          is24HrFormat: true,
                                          cancelText: 'Отмена',
                                          okText: 'Ок',
                                          hourLabel: 'часы',
                                          minuteLabel: 'минуты',
                                        )),
                                    child: Text('Выбрать время засыпания'),
                                  )
                                ]),
                          ),
                        ),
                      ]),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 64,
                    padding: EdgeInsets.only(bottom: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        OutlinedButton(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            child: Text('Назад'),
                          ),
                          onPressed: () {
                            goBack();
                          },
                          style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      30))),
                        ),
                        Consumer<ApplicationState>(
                            builder: (context, state, child) {
                              var correct = state.sleepTime != null &&
                                  state.awakeTime != null;
                              return OutlinedButton(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text('Далее', style: TextStyle(
                                      color: correct ? Theme
                                          .of(context)
                                          .primaryColor : Colors
                                          .grey),),
                                ),
                                onPressed: correct ? () async {
                                  var survey = Survey(
                                      state.age,
                                      state.gender ? 1 : 0,
                                      state.educationLevel,
                                      state.maritalStatus,
                                      state.awakeTime,
                                      state.sleepTime,
                                      1);
                                  var result = await saveSurvey(survey);
                                  if (!result) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Произошла ошибка при сохранении анкеты")));
                                  } else {
                                    state.survey = survey;
                                    gotoPage(context, routeToday);
                                  }
                                  // gotoP
                                } : null,
                                style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: correct
                                            ? Theme
                                            .of(context)
                                            .primaryColor
                                            : Colors.grey,
                                        width: correct ? 2 : 1),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(30))),
                              );
                            }),
                      ],
                    ),
                  ),
                ),

              ],
              );
            }));
  }
}
