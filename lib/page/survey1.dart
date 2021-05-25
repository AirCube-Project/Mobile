import 'dart:convert';

import 'package:aircube/model/survey.dart';
import 'package:aircube/page/main.dart';
import 'package:aircube/widget/beauty_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import '../model/state.dart';
import '../widget/labeled_radio.dart';
import 'package:aircube/constants.dart';


class GenderWidget extends StatefulWidget {
  Function onChange;

  GenderWidget({this.onChange});

  @override
  _GenderWidgetState createState() => _GenderWidgetState();
}

class _GenderWidgetState extends State<GenderWidget> {
  bool _gender;

  @override
  void initState() {
    // var state = Provider.of<ApplicationState>(context, listen: false);
    // _gender = state.gender;
  }

  void changeGender(bool value) {
    var state = Provider.of<ApplicationState>(context, listen: false);
    state.gender = value;
    setState(() {
      _gender = value;
    });
    widget.onChange();
  }

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32.0, top: 24.0),
          child: Align(
            child: Text("Пол",
                style: TextStyle(
                  fontSize: 16,
                )),
            alignment: Alignment.topLeft,
          ),
        ),
        Row(
          children: <Widget>[
            SizedBox(
              width: (mq.size.width / 2) - 32,
              height: 32,
              child: LabeledRadio(
                padding: EdgeInsets.only(left: 20),
                label: "женский",
                key: Key("female_gender"),
                value: false,
                groupValue: _gender,
                onChanged: (_) {
                  changeGender(false);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 8),
              child: SizedBox(
                width: (mq.size.width / 2) - 32,
                height: 32,
                child: LabeledRadio(
                  padding: EdgeInsets.only(left: 20),
                  label: "мужской",
                  key: Key("male_gender"),
                  value: true,
                  groupValue: _gender,
                  onChanged: (_) {
                    changeGender(true);
                  },
                ),
              ),
            )
          ],
        ),
      ],
    );
  }
}

GlobalKey<FormState> _ageForm = GlobalKey();

class AgeWidget extends StatefulWidget {
  Function onChange;

  AgeWidget({this.onChange});

  @override
  _AgeWidgetState createState() => _AgeWidgetState();
}

class _AgeWidgetState extends State<AgeWidget> {
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    var state = Provider.of<ApplicationState>(context, listen: false);
    _controller = TextEditingController(
        text: state.age != null ? state.age.toString() : "");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32.0, top: 32.0),
          child: Align(
              alignment: Alignment.topLeft,
              child: Text("Возраст",
                  style: TextStyle(
                    fontSize: 16,
                  ))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _ageForm,
            child: Container(
              padding: EdgeInsets.only(top: 8),
              child: TextFormField(
                decoration: InputDecoration(isCollapsed: true),
                key: Key("age"),
                controller: _controller,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Должно быть введено";
                  if (int.tryParse(value) == null) return "Введите число";
                  if (int.parse(value) < 3 || int.parse(value) > 95)
                    return "Введите корректный возраст";
                  return null;
                },
                onChanged: (v) {
                  var state =
                      Provider.of<ApplicationState>(context, listen: false);
                  if (_ageForm.currentState.validate()) {
                    state.age = int.parse(_controller.value.text);
                  } else {
                    state.age = null;
                  }
                  widget.onChange();
                },
                // onSubmitted: (String value) {
                //   print(value);
                // },
              ),
            ),
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class MaritalStatusWidget extends StatefulWidget {
  Function onChange;

  MaritalStatusWidget({this.onChange});

  @override
  _MaritalStatusWidgetState createState() => _MaritalStatusWidgetState();
}

class _MaritalStatusWidgetState extends State<MaritalStatusWidget> {
  String _maritalStatus;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    var state = Provider.of<ApplicationState>(context, listen: false);
    _maritalStatus = state.maritalStatus;
    if (_maritalStatus != null && _maritalStatus.isEmpty) _maritalStatus = null;
  }

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32.0, top: 32.0),
          child: Align(
              alignment: Alignment.topLeft,
              child: Text("Семейное положение",
                  style: TextStyle(
                    fontSize: 16,
                  ))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: mq.size.width,
            child: DropdownButton<String>(
              key: Key("marital_status"),
              value: _maritalStatus,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down),
              style: TextStyle(color: Colors.deepPurple),
              onChanged: (String value) {
                var state =
                    Provider.of<ApplicationState>(context, listen: false);
                state.maritalStatus = value;
                // print(state.maritalStatus);
                setState(() {
                  _maritalStatus = value;
                });
                widget.onChange();
              },
              items: <String>[
                "одинок",
                "в отношениях",
                "в браке",
                "в разводе",
                "вдова/вдовец"
              ]
                  .map((String value) => DropdownMenuItem(
                        child: Text(value),
                        value: value,
                      ))
                  .toList(),
            ),
          ),
        )
      ],
    );
  }
}

class EducationLevelWidget extends StatefulWidget {
  Function onChange;

  EducationLevelWidget({this.onChange});

  @override
  _EducationLevelWidgetState createState() => _EducationLevelWidgetState();
}

class _EducationLevelWidgetState extends State<EducationLevelWidget> {
  String _educationLevel;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    var state = Provider.of<ApplicationState>(context, listen: false);
    _educationLevel = state.educationLevel;
    if (_educationLevel != null && _educationLevel.isEmpty)
      _educationLevel = null;
  }

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32.0, top: 32.0),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Уровень образования",
                  style: TextStyle(
                    fontSize: 16,
                  ))),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32),
          child: SizedBox(
            width: mq.size.width,
            child: DropdownButton<String>(
              key: Key("education_level"),
              value: _educationLevel,
              icon: Icon(Icons.arrow_drop_down),
              isExpanded: true,
              style: TextStyle(color: Colors.deepPurple),
              onChanged: (String value) {
                var state =
                    Provider.of<ApplicationState>(context, listen: false);
                state.educationLevel = value;
                setState(() {
                  _educationLevel = value;
                });
                widget.onChange();
              },
              items: <String>[
                "без образования",
                "основное общее образование (9 классов)",
                "среднее общее образование (11 классов)",
                "среднее профессиональное образование",
                "бакалавриат",
                "специалитет",
                "магистратура",
                "аспирантура",
                "ординатура",
                "докторантура",
                "другое"
              ]
                  .map((String value) => DropdownMenuItem(
                        child: Text(value),
                        value: value,
                      ))
                  .toList(),
            ),
          ),
        )
      ],
    );
  }
}

class SurveyFirst extends StatefulWidget {
  SurveyFirst();

  @override
  _SurveyFirstState createState() => _SurveyFirstState();
}

class _SurveyFirstState extends State<SurveyFirst> {
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


  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(
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
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 32.0, bottom: 8),
                                child: Text("Регистрация",
                                    key: Key('welcome_title'),
                                    style: TextStyle(fontSize: 22)),
                              ),
                              if (!isKeyboardVisible)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                                  child: Text(
                                      "Система будет задавать Вам вопросы, чтобы подстроиться под Ваш ритм жизни, для достижения наилучших результатов отнеситесь с пониманием и постарайтесь отвечать честно",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.black38)),
                                ),
                              GenderWidget(
                                onChange: () {
                                  updateState(state);
                                },
                              ),
                              AgeWidget(
                                onChange: () {
                                  updateState(state);
                                },
                              ),
                              MaritalStatusWidget(
                                onChange: () {
                                  updateState(state);
                                },
                              ),
                              EducationLevelWidget(
                                onChange: () {
                                  updateState(state);
                                },
                              ),
                            ]),
                      )
                    ],
                  ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Назад'),
                          ),
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey, width: 1),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30))),
                        ),
                        Consumer<ApplicationState>(
                            builder: (context, state, child) {
                          return OutlinedButton(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Далее',
                                style: TextStyle(
                                    color: correct
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey),
                              ),
                            ),
                            onPressed: correct
                                ? () async {
                                    gotoPage(context, routeSurveySecond);
                                  }
                                : null,
                            style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: correct
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                    width: correct ? 2 : 1),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30))),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ]);
            }));
  }
}
