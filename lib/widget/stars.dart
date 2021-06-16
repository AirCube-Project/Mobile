import 'package:aircube/constants.dart';
import 'package:aircube/model/state.dart';
import 'package:aircube/page/details.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScrollableStars extends StatefulWidget {
  int step;

  TaskDetails details;

  List<int> data;

  int id;

  ScrollableStars(this.step, this.details, this.id, this.data, {Key key}) : super(key: key);

  @override
  _ScrollableStarsState createState() => _ScrollableStarsState();
}

class _ScrollableStarsState extends State<ScrollableStars> {
  var titles = [
    {
      "name": "Интеллектуальная сложность",
      "choices": ["Тяжело", "Сложно", "Средне", "Несложно", "Просто"]
    },
    {
      "name": "Физическая нагрузка",
      "choices": ["Тяжело", "Сложно", "Средне", "Несложно", "Просто"]
    },
    {
      "name": "Стресс",
      "choices": ["Сильный стресс", "Страх", "Тревога", "Волнение", "Спокойствие"]
    },
    {
      "name": "Удовольствие",
      "choices": ["Не нравится", "Безразлично", "Нормально", "Нравится", "Очень нравится"]
    },
    {
      "name": "Креативность",
      "choices": ["Рутинно", "Низкая креативность", "Средне", "Креативно", "Очень креативно"]
    },
    {
      "name": "Важность для профессионального роста",
      "choices": ["Совсем не важно", "Не важно", "Средне", "Важно", "Очень важно"]
    },
    {
      "name": "Важность для здоровья",
      "choices": ["Совсем не важно", "Не важно", "Средне", "Важно", "Очень важно"]
    },
    {
      "name": "Важность для саморазвития",
      "choices": ["Совсем не важно", "Не важно", "Средне", "Важно", "Очень важно"]
    },
  ];

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context);
    var height = mq.size.height;

    return ListView.builder(
        itemCount: titles.length,
        itemBuilder: (BuildContext context, int id) => StarsLine(
            key: UniqueKey(),
            stars: 5,
            choices: titles[id]["choices"],
            activeColor: Theme.of(context).primaryColor,
            size: 32,
            title: titles[id]["name"],
            data: widget.data,
            taskId: widget.id,
            grade: id));
  }
}

class StarsLine extends StatefulWidget {
  int stars;

  int grade;

  List<String> choices;

  double padding;

  double height;

  double size;

  String title;

  int star;

  List<int> data;

  int taskId;

  Color activeColor;
  Color inactiveColor;

  StarsLine(
      {this.stars = 5,
      this.choices,
      this.padding = 16,
      this.height = 72,
      this.size = 32,
      this.activeColor,
      this.inactiveColor = Colors.black26,
      this.title,
      this.data,
        this.taskId,
      @required this.grade,
      Key key})
      : super(key: key);

  @override
  _StarsLineState createState() => _StarsLineState();
}

class _StarsLineState extends State<StarsLine> {
  _StarsLineState();

  var star;

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context);
    var screenWidth = mq.size.width;
    var width = (screenWidth - 2 * widget.padding) / widget.stars;
    // print("Building...");
    return Container(
        padding: EdgeInsets.only(top: 8),
        child: Column(children: [
          Container(
            padding: EdgeInsets.only(left: widget.padding),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.title,
                style: TextStyle(color: Colors.black87, fontSize: 18),
              ),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var displayStar in List<int>.generate(widget.stars, (int n) => n + 1))
              SizedBox(
                width: width,
                height: widget.height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      child: IconButton(
                          icon: Icon(
                            displayStar == widget.data[widget.grade] ? Icons.star : Icons.star_border,
                            size: widget.size,
                            color: displayStar == star ? widget.activeColor : widget.inactiveColor,
                          ),
                          onPressed: () {
                            setState(() {
                              widget.data[widget.grade] = displayStar;

                              //store to server
                              var state = Provider.of<ApplicationState>(context,
                                  listen: false);
                              var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
                              Future.delayed(Duration(milliseconds: 1), () async {
                                var url = securePrefix+"/rating/${widget.taskId}/${widget.grade}/$displayStar";
                                print("URL is " + url);
                                await dio.post(url);
                              });

                              // state.setScore(this.widget.grade, displayStar);
                            });
                          }),
                    ),
                    Text(
                      widget.choices[displayStar - 1],
                      style: TextStyle(
                        fontSize: 9,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
          ])
        ]));
  }
}
