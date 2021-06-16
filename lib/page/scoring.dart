import 'dart:convert';
import 'dart:ui';

import 'package:aircube/model/state.dart';
import 'package:aircube/widget/stars.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import 'details.dart';
import 'main.dart';

class ScoringData {
  int ind_intellect;
  int ind_health;
  int ind_pleasure;
  int ind_creativity;
  int ind_phys;
  int ind_stress;
  int ind_prof_grow;
  int ind_pers_dev;

  int duration;
}

class ScoringPage extends StatelessWidget {
  const ScoringPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context).settings.arguments as IDArguments;
    var id = args.id;
    var mq = MediaQuery.of(context);
    return FutureBuilder<TaskDetails>(future: () async {
      var state = Provider.of<ApplicationState>(context, listen: false);
      var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
      print("URL IS /task/$id");
      var details = await dio.get(securePrefix + "/task/$id");
      print("Details status ${details.statusCode}");
      if (details.statusCode == 200) {
        print("Data accepted");
        print(details.data);
        return TaskDetails.fromJson(await details.data);
      } else {
        return null;
      }
    }(), builder: (context, snapshot) {
      if (snapshot.hasData) {
        return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
                leading: BackButton(
                  color: Colors.black54,
                ),
                backgroundColor: Colors.white,
                elevation: 0,
                title: Text(snapshot.data.name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black54))),
            body: KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
              return Column(
                children: [
                  Container(
                      color: Colors.white,
                      height: mq.size.height - 96 - 42 - (isKeyboardVisible ? 226 + 48 : 0),
                      child: ScrollableStars(1, snapshot.data, id, [
                        snapshot.data.indIntellect,
                        snapshot.data.indPhys,
                        snapshot.data.indStress,
                        snapshot.data.indPleasure,
                        snapshot.data.indCreative,
                        snapshot.data.indProfGrow,
                        snapshot.data.indHealth,
                        snapshot.data.indSelfDev
                      ])),
                  Container(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.black54, width: 2)),
                            color: Colors.white
                      ),
                        height: 48,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            Text("Продолжительность: "),
                            SizedBox(
                              height: 48,
                              width: mq.size.width / 3,
                              child: TextFormField(
                                initialValue: snapshot.data.plannedDuration?.toString() ?? "",
                                onChanged: (v) async {
                                  var state = Provider.of<ApplicationState>(context, listen: false);
                                  var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
                                  try {
                                    var p = double.tryParse(v);
                                    await dio.put(securePrefix + "/task/$id", data: json.encode({"planned_duration": (p * 60).toInt()}));
                                  } catch (Exception) {}
                                },
                              ),
                            ),
                            Text("мин")]),
                        )
                    ),
                  ),
                ],
              );
            }));
      } else {
        return Center(
            child: SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(),
        ));
      }
    });
  }
}
