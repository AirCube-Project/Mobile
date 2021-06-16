import 'dart:convert';

import 'package:aircube/model/state.dart';
import 'package:aircube/page/today.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:select_dialog/select_dialog.dart';

import '../constants.dart';

class Goal {
  int id;

  String image;

  String title;

  double progress;

  Goal(this.id, this.image, this.title, this.progress);
}

class Receipt {
  int id;

  String image;

  String title;

  Receipt(this.id, this.image, this.title);
}

class GoalsSegment extends StatelessWidget {
  String title;

  List<Widget> content;

  Color color1;

  Color color2;

  GoalsSegment(this.title, this.color1, this.color2, this.content, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
        child: AspectRatio(
          aspectRatio: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [color1, color2])),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
                Container(
                  height: 96,
                  child: Container(
                    padding: EdgeInsets.only(left: 16),
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: content.length,
                        itemBuilder: (context, index) {
                          return content[index];
                        }),
                  ),
                )
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class Goals {
  List<Receipt> actual;
  List<Goal> my;
  List<Receipt> receipts;

  Goals(this.actual, this.my, this.receipts);
}

class GoalWidget extends StatelessWidget {
  Goal goal;

  GoalWidget(this.goal, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 192,
        height: 96,
        child: InkWell(
          onTap: () {
            //show goal page
          },
          child: Card(
              child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                    width: 32,
                    height: 32,
                    child: Image.network(
                      publicPrefix + "/image/" + goal.image,
                      fit: BoxFit.cover,
                    )),
              ),
              SizedBox(
                width: 112,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(goal.title, softWrap: true, style: TextStyle(fontSize: 12)),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: LinearProgressIndicator(
                        value: goal.progress / 100,
                      ),
                    ),
                  ],
                ),
              )
            ],
          )),
        ));
    ;
  }
}

class ReceiptWidget extends StatelessWidget {
  Receipt receipt;

  ReceiptWidget(this.receipt, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 192,
        height: 96,
        child: InkWell(
          onTap: () {
            //show goal page
          },
          child: Card(
              child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                    width: 32,
                    height: 32,
                    child: Image.network(
                      publicPrefix + "/image/" + receipt.image,
                      fit: BoxFit.cover,
                    )),
              ),
              SizedBox(
                width: 112,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(receipt.title, softWrap: true, style: TextStyle(fontSize: 12)),
                  ],
                ),
              )
            ],
          )),
        ));
    ;
  }
}

class GoalsPage extends StatefulWidget {
  const GoalsPage({Key key}) : super(key: key);

  @override
  _GoalsPageState createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  DateTime lastUpdated;

  Future<Goals> getGoals(BuildContext context) async {
    var state = Provider.of<ApplicationState>(context, listen: false);
    var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
    var response = await dio.get(securePrefix + "/receipt");
    var actual = <Receipt>[];
    var receipts = <Receipt>[];
    var goals = <Goal>[];
    if (response.statusCode == 200) {
      response.data.forEach((receipt) {
        var rc = Receipt(receipt["id"], receipt["s3"], receipt["name"]);
        receipts.add(rc);
        if (receipt["actual"] == true) {
          actual.add(rc);
        }
      });
      var response2 = await dio.get(securePrefix + "/goal");
      if (response2.statusCode == 200) {
        response2.data.forEach((goal) {
          print(goal);
          goals.add(Goal(goal["id"], goal["s3"], goal["name"], 10.0));
        });
      }
    }

    return Goals(actual, goals, receipts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: buildNavBar(context, 2),
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text(
            "Цели",
            style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ),
        body: FutureBuilder<Goals>(
            future: getGoals(context),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      GoalsSegment("Актуальные", Color.fromRGBO(0xCF, 0x48, 0xF1, 0.8), Color.fromRGBO(0x15, 0x2A, 0xEB, 0.4),
                          [for (var receipt in snapshot.data.actual) ReceiptWidget(receipt)]),
                      GoalsSegment("Мои цели", Color.fromRGBO(0x93, 0x48, 0xF1, 0.5), Color.fromRGBO(0x15, 0x9E, 0xEB, 0.4), [
                        InkWell(
                            onTap: () {
                              var list =
                                  snapshot.data.receipts.map<PresetModel>((p) => PresetModel(id: p.id, name: p.title)).toList();
                              list.sort();
                              SelectDialog.showModal<PresetModel>(context, label: "Выберите рецепт", items: list,
                                  onChange: (selected) async {
                                var state = Provider.of<ApplicationState>(context, listen: false);
                                var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
                                await dio.post(securePrefix + "/goal", data: json.encode({"receipt": selected.id}));
                                setState(() {
                                  lastUpdated = DateTime.now();
                                });
                              }, searchHint: "Поиск");
                            },
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                    color: Theme.of(context).primaryColor,
                                    child: SizedBox(
                                        width: 96,
                                        height: 96,
                                        child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                                          Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          Text(
                                            "Добавить новую",
                                            style: TextStyle(fontSize: 10, color: Colors.white),
                                          )
                                        ]))))),
                        for (var goal in snapshot.data.my) GoalWidget(goal)
                      ]),
                      GoalsSegment("Рецепты", Color.fromRGBO(0xD7, 0x20, 0xF4, 0.48), Color.fromRGBO(0xE0, 0x9F, 0xF0, 0.49),
                          [for (var receipt in snapshot.data.receipts) ReceiptWidget(receipt)]),
                    ],
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
