import 'dart:convert';
import 'dart:io';

import 'package:aircube/model/state.dart';
import 'package:aircube/page/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime_type/mime_type.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';

class AddPage extends StatefulWidget {
  const AddPage({Key key}) : super(key: key);

  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  String task;

  String duration;

  String photoImage;

  String banner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(color: Colors.black54),
          title: Text(
            "Создание задачи",
            style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ),
        body: Container(
            color: Colors.white,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextFormField(
                        decoration: InputDecoration(hintText: "Название задачи"),
                        onChanged: (v) {
                          task = v;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        onChanged: (d) {
                          duration = d;
                        },
                        decoration: InputDecoration(hintText: "Ожидаемая длительность (в минутах)"),
                      ),
                    ),
                    AspectRatio(
                      aspectRatio: 2,
                      child: GestureDetector(
                        onTap: () async {
                          var state = Provider.of<ApplicationState>(context, listen: false);
                          var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));

                          //replace image
                          var picker = ImagePicker();
                          var file = await picker.getImage(source: ImageSource.gallery);
                          if (file != null) {
                            var image = File(file.path);
                            var mimeType = mime(file.path);
                            var bytes = await image.readAsBytes();
                            var data = {"content_type": mimeType, "data": base64.encode(bytes)};
                            // print(data);
                            var filename = Uuid().v4();
                            // print(filename);
                            var response = await dio.post(securePrefix + "/image/$filename", data: json.encode(data));
                            if (response.statusCode == 200) {
                              var url = publicPrefix + "/image/" + filename;
                              // print("State ok");
                              setState(() {
                                photoImage = url;
                                banner = photoImage.substring(photoImage.lastIndexOf("/") + 1);
                                // print("Banner " + banner);
                              });
                            }
                            // print(response);
                          }
                        },
                        child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor,
                            ),
                            width: 84,
                            height: 84,
                            child: CachedNetworkImage(
                              fit: BoxFit.cover,
                              imageUrl: photoImage,
                              placeholder: (context, url) => Image.asset("assets/placeholder.png"),
                              errorWidget: (context, url, error) => Image.asset("assets/placeholder.png"),
                            )),
                      ),
                    ),
                    ElevatedButton(
                        child: Text("Создать задачу"),
                        style: ElevatedButton.styleFrom(primary: Theme.of(context).primaryColor),
                        onPressed: () async {
                          var state = Provider.of<ApplicationState>(context, listen: false);
                          var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
                          var date = DateTime.now().toIso8601String().substring(0, 10);
                          var dur = null;
                          try {
                            dur = int.tryParse(duration);
                          } catch (Exception) {}
                          var dt =
                              json.encode({"name": task, "planned_date": date, "planned_duration": dur * 60, "banner": banner});
                          await dio.post(securePrefix + "/task", data: dt);
                          Navigator.of(context).pushReplacementNamed(routeToday);
                        })
                  ]),
                ))));
  }
}
