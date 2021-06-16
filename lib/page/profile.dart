import 'dart:convert';
import 'dart:io';

import 'package:aircube/constants.dart';
import 'package:aircube/model/state.dart';
import 'package:aircube/page/main.dart';
import 'package:aircube/page/today.dart';
import 'package:dio/dio.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime_type/mime_type.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

String pluralizer(int number, String singular, String pair, String other) {
  if (number==11 || number==12) return other;
  if (number % 10==1) return singular;
  if ([2,3,4].contains(number % 10)) return pair;
  return other;
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  var nameEditMode = false;

  Color getIndicatorColor(BuildContext context, int index, int value) {
    if (value == null) {
      return Colors.black38;
    }
    if (index == 1) {
      //stress
      if (value > 80) {
        return Theme.of(context).errorColor;
      } else if (value > 60) {
        return Colors.yellow.shade600;
      } else if (value < 20) {
        return Colors.green.shade300;
      } else
        return Theme.of(context).primaryColorLight;
    } else {
      if (value < 20) {
        return Theme.of(context).errorColor;
      } else if (value < 40) {
        return Colors.yellow.shade600;
      } else if (value >= 80) {
        return Colors.green.shade300;
      } else
        return Theme.of(context).primaryColorLight;
    }
  }

  Future getProfile() async {
    //extract data from profile
    var profile = await dio.get(securePrefix + "/profile");
    if (profile.statusCode == 200) {
      var d = await profile.data;
      print("Data is ");
      print(d);
      return d;
    } else {
      return {};
    }
    //
    // var prefs = EncryptedSharedPreferences();
    // return {"weight": await prefs.getString("weight"),
    // "sleep": await prefs.getString("sleep")};
  }

  double getNullableDouble(value) {
    if (value == null) return null;
    if (value.runtimeType == double) {
      return value;
    }
    var result = 0.0;
    try {
      result = double.tryParse(value);
    } catch (e) {}
    return result;
  }

  int getNullableInt(value) {
    if (value == null) return null;
    if (value.runtimeType == int) {
      return value;
    }
    var result = 0.0;
    try {
      result = double.tryParse(value);
    } catch (e) {}
    return result.round();
  }

  TextEditingController nameEditingController;

  String newName;

  ImageProvider photoImage;

  void nameChanged() async {
    var state = Provider.of<ApplicationState>(context, listen: false);
    var profile = {"name": newName};
    await dio.put(securePrefix + "/profile", data: json.encode(profile));
    setState(() {
      state.name = newName;
      nameEditMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var prefs = EncryptedSharedPreferences();
    var mq = MediaQuery.of(context);
    var editNameKey = GlobalKey<FormState>();
    var titles = ["Фокусировка", "Стресс", "Исполнительность", "Ритмичность", "Развитие", "Креативность"];

    return Scaffold(
        backgroundColor: Colors.white,

        bottomNavigationBar: buildNavBar(context, 3),
    body: FutureBuilder(
        future: getProfile(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var profile = snapshot.data;
            print("Profile");
            print(profile);
            String photo = profile["photo"];
            if (photo.startsWith("http")) {
              photoImage = NetworkImage(photo);
            } else {
              //decode from s3!
            }
            var weight = getNullableDouble(profile["weight"]);
            var sleep = getNullableDouble(profile["sleep"]);
            var perfHealth = getNullableInt(profile["perf_health"]);
            var perfFocus = getNullableInt(profile["perf_focus"]);
            var perfStress = getNullableInt(profile["perf_stress"]);
            var perfDiscipline = getNullableInt(profile["perf_discipline"]);
            var perfRhythm = getNullableInt(profile["perf_rhythm"]);
            var perfDevelopment = getNullableInt(profile["perf_development"]);
            var perfCreativity = getNullableInt(profile["perf_creative"]);
            var values = [perfFocus, perfStress, perfDiscipline, perfRhythm, perfDevelopment, perfCreativity];

            return SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: mq.size.width - 32,
                          height: 128,
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                            elevation: 6,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: mq.size.width * 0.05),
                                  child: GestureDetector(
                                    onTap: () async {
                                      //replace image
                                      var picker = ImagePicker();
                                      var file = await picker.getImage(source: ImageSource.gallery);
                                      if (file!=null) {
                                        var image = File(file.path);
                                        var mimeType = mime(file.path);
                                        var bytes = await image.readAsBytes();
                                        var data = {
                                          "content_type": mimeType,
                                          "data": base64.encode(bytes)
                                        };
                                        print(data);
                                        var filename = Uuid().v4();
                                        print(filename);
                                        var response = await dio.post(securePrefix+"/image/$filename", data: json.encode(data));
                                        if (response.statusCode==200) {
                                          var url = publicPrefix+"/image/"+filename;
                                          var response2 = await dio.put(securePrefix+"/profile", data: json.encode({"photo":url}));
                                          if (response2.statusCode==200) {
                                            print("State ok");
                                            setState(() {
                                              photoImage = NetworkImage(url);
                                            });
                                          }
                                        }
                                        print(response);
                                      }
                                    },
                                    child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        width: 84,
                                        height: 84,
                                        child: Container(
                                          padding: EdgeInsets.all(2),
                                          child: CircleAvatar(
                                            radius: 40,
                                            foregroundImage: photoImage,
                                          ),
                                        )),
                                  ),
                                ),
                                Container(
                                  height: 128,
                                  width: mq.size.width * 0.9 - 32 - 84 - 48,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                          top: 40,
                                          child: !nameEditMode
                                              ? Row(
                                                  children: [
                                                    Text(
                                                      profile["name"],
                                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 8.0),
                                                      child: GestureDetector(
                                                          onTap: () {
                                                            setState(() {
                                                              nameEditMode = true;
                                                              nameEditingController.text = profile["name"];
                                                            });
                                                          },
                                                          child: Icon(
                                                            Icons.edit,
                                                            color: Colors.black54,
                                                          )),
                                                    ),
                                                  ],
                                                )
                                              : Container(
                                                  height: 24,
                                                  width: 192,
                                                  child: Form(
                                                    key: editNameKey,
                                                    child: TextFormField(
                                                      style: TextStyle(
                                                          fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                                                      controller: nameEditingController,
                                                      onFieldSubmitted: (v) async {
                                                        nameChanged();
                                                      },
                                                      decoration: InputDecoration(
                                                        isDense: true,
                                                        suffixIconConstraints: BoxConstraints(minWidth: 2, minHeight: 2),
                                                        suffixIcon: InkWell(
                                                          onTap: () {
                                                            print("Pressed btn");
                                                            nameChanged();
                                                          },
                                                            child: Icon(Icons.check, color: Colors.black54)),
                                                      ),
                                                    ),
                                                  )
                                                )),
                                      Positioned(
                                          child: RichText(
                                              text: TextSpan(
                                                  style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor),
                                                  children: <TextSpan>[
                                                TextSpan(text: profile["age"].toString()+" "),
                                                TextSpan(
                                                    text: pluralizer(profile["age"], "год","года","лет")+", ", style: TextStyle(color: Theme.of(context).shadowColor)),
                                                TextSpan(text: profile["gender"] == 1 ? "👨" : "👩"),
                                              ])),
                                          bottom: 28),
                                    ],
                                  ),
                                ),
                                Container(
                                    padding: EdgeInsets.only(top: 24),
                                    child: GestureDetector(
                                        onTap: () {
                                          gotoPage(context, routeSettings);
                                        },
                                        child: Icon(Icons.settings, color: Theme.of(context).shadowColor, size: 24.0))),
                              ],
                            ),
                          )),
                      Container(
                          padding: EdgeInsets.only(top: 16),
                          child: Text("Характеристики", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10))),
                      SizedBox(
                        height: (mq.size.width+16)/3*2,
                        child: GridView.count(
                          crossAxisCount: 3,
                          children: List.generate(
                              6,
                              (index) => Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 4,
                                  child: AspectRatio(
                                    aspectRatio: 1.0,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                            top: 16,
                                            left: 8,
                                            child: Text(titles[index],
                                                style: TextStyle(
                                                    color: Theme.of(context).shadowColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold))),
                                        Align(
                                          alignment: Alignment.center,
                                          child: Container(
                                            padding: EdgeInsets.only(top: 16),
                                            child: Text(
                                              values[index] == null ? "-" : values[index].toString(),
                                              style: TextStyle(
                                                  fontSize: 28,
                                                  color: getIndicatorColor(context, index, values[index]),
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ))),
                        ),
                      ),
                      Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text("Здоровье", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10))),
                      Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                          elevation: 6,
                          child: Row(children: [
                            SizedBox(
                                width: (mq.size.width - 40) / 2,
                                height: 128,
                                child: CircularPercentIndicator(
                                  footer: Container(),
                                  addAutomaticKeepAlive: true,
                                  radius: 96.0,
                                  lineWidth: 10.0,
                                  circularStrokeCap: CircularStrokeCap.butt,
                                  animation: true,
                                  percent: perfHealth != null ? perfHealth / 100 : 0.0,
                                  center: new Text(
                                    perfHealth?.toString() ?? "-",
                                    style: new TextStyle(
                                        fontWeight: FontWeight.w500, fontSize: 32.0, color: Theme.of(context).primaryColor),
                                  ),
                                  progressColor: Theme.of(context).primaryColor,
                                )),
                            SizedBox(
                                width: (mq.size.width - 40) / 2,
                                height: 128,
                                child: Stack(
                                  children: [
                                    Positioned(
                                        top: 32,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                                width: 48,
                                                child: Text(
                                                  "Вес",
                                                  style: TextStyle(color: Theme.of(context).shadowColor, fontSize: 10),
                                                )),
                                            weight == null
                                                ? Text("?")
                                                : RichText(
                                                    text: TextSpan(
                                                        style: TextStyle(
                                                            fontSize: 24,
                                                            fontWeight: FontWeight.w500,
                                                            color: Colors.blue.shade900),
                                                        children: <TextSpan>[
                                                        TextSpan(text: weight.toStringAsFixed(1) + " "),
                                                        TextSpan(
                                                          text: "кг",
                                                          style: TextStyle(fontSize: 10),
                                                        )
                                                      ])),
                                          ],
                                        )),
                                    Positioned(
                                        bottom: 32,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                                width: 48,
                                                child: Text(
                                                  "Сон",
                                                  style: TextStyle(color: Theme.of(context).shadowColor, fontSize: 10),
                                                )),
                                            sleep == null
                                                ? Text("?")
                                                : RichText(
                                                    text: TextSpan(
                                                        style: TextStyle(
                                                            fontSize: 24,
                                                            color: Theme.of(context).primaryColor,
                                                            fontWeight: FontWeight.w500),
                                                        children: <TextSpan>[
                                                        TextSpan(text: "${(sleep / 60.0).toStringAsFixed(1)} "),
                                                        TextSpan(
                                                          text: "ч.",
                                                          style: TextStyle(fontSize: 10),
                                                        )
                                                      ])),
                                          ],
                                        )),
                                  ],
                                )),

                          ])),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(primary: Theme.of(context).primaryColor),
                                onPressed: () {
                                },
                                child: Text("Пройти обучение системы")
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        }));
  }

  Dio dio;

  @override
  void initState() {
    super.initState();
    var state = Provider.of<ApplicationState>(context, listen: false);
    dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}))
      ..interceptors.add(LogInterceptor(responseBody: true, requestBody: true));

    nameEditingController = TextEditingController();
    nameEditingController.addListener(() async {
      newName = nameEditingController.text;
    });
  }
}
