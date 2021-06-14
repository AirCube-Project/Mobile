import 'dart:convert';

import 'package:aircube/constants.dart';
import 'package:aircube/page/survey1.dart';
import 'package:aircube/page/survey2.dart';
import 'package:aircube/page/today.dart';
import 'package:cron/cron.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/state.dart';
import 'add.dart';
import 'details.dart';
import 'goals.dart';
import 'inbox.dart';
import 'login.dart';
import 'now.dart';
import 'profile.dart';
import 'scoring.dart';
import 'settings.dart';
import 'timer.dart';

const routeLogin = '/';
const routeSurveyFirst = '/survey/first';
const routeSurveySecond = '/survey/second';
const routeToday = "/primary/today";
const routeNow = "/primary/now";
const routeGoals = "/primary/goals";
const routeProfile = "/primary/profile";
const routeSettings = "/settings";
const routeDetails = "/details";
const routeScoring = "/scoring";
const routeInbox = "/inbox";
const routeAdd = "/add";
const routeTimer = "/timer";

class IDArguments {
  final int id;

  IDArguments(this.id);
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ApplicationState>(create: (context) => ApplicationState(), child: NavigatorPage(key: navigatorKey));
  }
}

class NavigatorPage extends StatefulWidget {

  NavigatorPage({Key key}) : super(key: key);

  @override
  _NavigatorPageState createState() => _NavigatorPageState();
}

final navigatorKey = GlobalKey<_NavigatorPageState>();

void gotoPage(BuildContext context, String route, {dynamic arguments = null}) {
  var state = Provider.of<ApplicationState>(context, listen: false);
  state.lastRoute = route;
  if (arguments==null) {
    Navigator.of(context).pushNamed(route);
  } else {
    Navigator.of(context).pushNamed(route, arguments: arguments);
  }
}

void goBack(BuildContext context) {
  print("Going back");
  navigatorKey.currentState.setState(() {
    print(navigatorKey.currentWidget.runtimeType);
    print(navigatorKey.currentState.runtimeType);
    (navigatorKey.currentState as _NavigatorPageState).visible = true;
  });
  Navigator.of(context).pop();
}

class AnimatedRoute<T> extends MaterialPageRoute<T> {
  AnimatedRoute({WidgetBuilder builder, RouteSettings settings}) : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    // return child;
    // if (settings.name==routeLogin)
    //   return child;
    // // Fades between routes. (If you don't want any animation,
    // // just return child.)
    return new FadeTransition(opacity: animation, child: child);
  }
}

class _NavigatorPageState extends State<NavigatorPage> {
  int _selected = 0;

  var visible = true;

  @override
  Widget build(BuildContext context) {
    var cron = Cron();
    // cron.schedule(new Schedule.parse('* * * * *'), () async {
    //   print("Every minute");
    //   var state = Provider.of<ApplicationState>(context, listen: false);
    //   var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}));
    //   var focus = await dio.get(securePrefix + "/focus");
    //   var focusMode = focus.data["focus_task"] != null;
    //   print("Focus mode is $focusMode");
    //   if (focusMode) {
    //     Navigator.of(context).pushReplacementNamed(routeDetails, arguments: IDArguments(focus.data["focus_task"]));
    //   }
    // });
    cron.schedule(new Schedule.parse('*/15 * * * *'), () async {
      print('every minute');
      var weight = await getWeight();
      var steps = await getSteps();
      print('Get signin');
      var state = Provider.of<ApplicationState>(context, listen: false);
      var auth = state.user;
      if (auth != null) {
        var sleep = await getSleepDuration(auth);
        print("Weight is");
        print(weight);
        print("Steps is");
        print(steps);
        print("Sleep is");
        print(sleep);
        //send to profile
        var dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}))
          ..interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
        var data = {};
        if (weight != null) {
          data["weight"] = weight;
        }
        if (sleep != null) {
          data["sleep"] = sleep;
        }
        if (steps != null) {
          data["steps"] = steps;
        }
        try {
          dio.put(securePrefix + "/profile", data: json.encode(data));
        } catch (Exception) {};
      }
      //request for recommendations
    });

    return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: Consumer<ApplicationState>(
          builder: (context, state, child) => Scaffold(
            backgroundColor: Colors.white,

            body: Navigator(
              initialRoute: routeLogin,
              onGenerateRoute: _onGenerateRoute,
            ),
          ),
        ));
  }

  Route _onGenerateRoute(RouteSettings settings) {
    Future.delayed(Duration(milliseconds: 100), () async {
      setState(() {
        if ([routeDetails, routeSettings].contains(settings.name)) {
          visible = false;
        } else {
          visible = true;
        }
      });
    });
    Widget page;
    // print("Generating route: ${settings.name}");
    switch (settings.name) {
      case routeLogin:
        page = LoginPage(); //func -> prev, next
        break;
      case routeSurveyFirst:
        page = SurveyFirst();
        break;
      case routeSurveySecond:
        page = SurveySecond();
        break;
      case routeToday:
        page = Today();
        break;
      case routeNow:
        page = NowPage();
        break;
      case routeGoals:
        page = GoalsPage();
        break;
      case routeProfile:
        page = ProfilePage();
        break;
      case routeSettings:
        page = SettingsPage();
        break;
      case routeDetails:
        page = DetailsPage();
        break;
      case routeScoring:
        page = ScoringPage();
        break;
      case routeInbox:
        page = InboxPage();
        break;
      case routeAdd:
        page = AddPage();
        break;
      case routeTimer:
        page = TimerPage();
        break;
    }

    return AnimatedRoute(
      builder: (context) {
        return page;
      },
      settings: settings,
    );
  }
}
