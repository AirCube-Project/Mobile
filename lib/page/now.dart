//Страница "Сейчас"
import 'dart:convert';

import 'package:aircube/constants.dart';
import 'package:aircube/model/state.dart';
import 'package:aircube/page/main.dart';
import 'package:aircube/page/today.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../model/activity.dart';

class NowContent {
  //Описания основной и альтернативных активностей
  List<Activity> activities;

  NowContent(this.activities);
}

class NowPage extends StatefulWidget {
  @override
  _NowPageState createState() => _NowPageState();
}

class _NowPageState extends State<NowPage> {
  DateTime lastUpdated;

  cancelSuggestions(BuildContext context) async {
    var state = Provider.of<ApplicationState>(context, listen: false);
    var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
    await dio.delete(securePrefix + "/suggestions");
  }

  Future<NowContent> getNowData(BuildContext context) async {
    var state = Provider.of<ApplicationState>(context, listen: false);
    var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}))
      ..interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
    var formatter = DateFormat("HH:mm");
    var response = await dio.get(securePrefix + "/suggestions/" + formatter.format(DateTime.now()));
    if (response.statusCode == 200) {
      var data = await response.data;
      print(data.runtimeType);
      print("NowData");
      List<Activity> activities = [];
      data.forEach((d) {
        var act = Activity.fromJson(d);
        activities.add(act);
      });
      return NowContent(activities);
    }
  }

  @override
  Widget build(BuildContext context) {
    //Получить размер экрана
    var mq = MediaQuery.of(context);
    return Scaffold(
        backgroundColor: Colors.white,

        bottomNavigationBar: buildNavBar(context, 1),
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0, automaticallyImplyLeading: false,title: Text(
          "Сейчас",
          style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 24, fontWeight: FontWeight.w700),
        )),
        body: FutureBuilder<NowContent>(
          future: getNowData(context),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var content = snapshot.data;
              return Container(
                color: Colors.white,
                //Контейнер на весь экран (за исключением области навигации и строки состояния)
                width: mq.size.width,
                height: mq.size.height,
                child: Stack(children: [
                  //Верхняя прокручиваемая часть
                  Positioned(
                      top: 0,
                      bottom: 64,
                      child: SingleChildScrollView(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        //Заголовок страницы
                        for (var activity in content.activities)
                          InkWell(
                            onTap: () async {
                              var state = Provider.of<ApplicationState>(context, listen: false);
                              await Navigator.of(context).pushNamed(routeDetails, arguments: IDArguments(activity.id));
                              setState(() {
                                lastUpdated = DateTime.now();
                              });
                            },
                            child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                //Основная активность
                                child: SizedBox(
                                  width: mq.size.width - 24,
                                  height: (mq.size.width - 24) / 2.5,
                                  child: Card(
                                      //Карточка со скруглением
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(16)),
                                      ),
                                      child: Stack(children: [
                                        //Скругление основного изображения
                                        Container(
                                          width: mq.size.width - 32,
                                          height: (mq.size.width - 32) / 2,
                                          child: ClipRRect(
                                              borderRadius: BorderRadius.all(Radius.circular(16)),
                                              child: activity.image != null
                                                  ? Image.network(publicPrefix + "/image/" + activity.image, fit: BoxFit.cover)
                                                  : Container(color: activity.color ?? Color.fromRGBO(0,0,0,0.5))),
                                        ),
                                        //Отображение нижней панели с кнопкой активации
                                        Positioned(
                                            bottom: 0,
                                            child: Container(
                                                //Скругление фона (по нижней границе)
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.only(
                                                        bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))),
                                                width: mq.size.width - 2 * 16,
                                                height: 40,
                                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                  //Название активности
                                                  Padding(
                                                      padding: EdgeInsets.only(top: 8.0, bottom: 8.0, left: 24.0),
                                                      child: ConstrainedBox(
                                                        constraints: BoxConstraints(maxWidth: mq.size.width-4*16),
                                                        child: Text(activity.name, overflow: TextOverflow. ellipsis,softWrap: true,
                                                            style: TextStyle(
                                                                fontSize: 16, color: Theme.of(context).primaryColorDark)),
                                                      )),
                                                  if (activity.time != null && activity.time.isNotEmpty)
                                                    Padding(
                                                      padding: const EdgeInsets.only(right: 16.0),
                                                      child: Text(activity.time,
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                              color: Theme.of(context).primaryColor)),
                                                    )
                                                ])))
                                      ])),
                                )),
                          ),
                        //     )),
                        //     //Вывод альтернативных активностей
                        //     //   for (Activity event in content.secondaryActivities)
                        //     //Нижняя панель (отказ от предложенных активностей)
                      ]))),
                  Positioned(
                      width: mq.size.width,
                      bottom: 16,
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        //Текст (слева, ширина не более половины ширины экрана)
                        Container(
                          padding: EdgeInsets.only(left: 16),
                          width: mq.size.width * 0.5,
                          child: Text(
                            "Если все предложенные активности Вам не подходят",
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                        //Скругленная кнопка с текстом "Отказаться"
                        Container(
                          padding: EdgeInsets.only(right: 8),
                          child: OutlinedButton(
                              onPressed: () async {
                                //отмена предложений и запрос новых
                                await cancelSuggestions(context);
                                Navigator.of(context).pushReplacementNamed(routeNow);
                              },
                              style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  "Отказаться",
                                  style: TextStyle(fontSize: 16, color: Colors.black54),
                                ),
                              )),
                        )
                      ]))
                ]),
              );
            } else {
              return Center(
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(),
                ),
              );
            }
          },
        ));
  }

  Dio dio;
}
