import 'package:aircube/page/survey1.dart';
import 'package:aircube/page/survey2.dart';
import 'package:aircube/page/today.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/state.dart';
import 'login.dart';

const routeLogin = '/';
const routeSurveyFirst = '/survey/first';
const routeSurveySecond = '/survey/second';
const routeToday = "/primary/today";

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ApplicationState>(
        create: (context) => ApplicationState(), child: NavigatorPage());
  }
}

class NavigatorPage extends StatefulWidget {
  @override
  _NavigatorPageState createState() => _NavigatorPageState();
}

final _navigatorKey = GlobalKey<NavigatorState>();

void gotoPage(BuildContext context, String route) {
  _navigatorKey.currentState.pushNamed(route);
}

void goBack() {
  _navigatorKey.currentState.pop();
}

class AnimatedRoute<T> extends MaterialPageRoute<T> {
  AnimatedRoute({ WidgetBuilder builder, RouteSettings settings })
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    // return child;
    // if (settings.name==routeLogin)
    //   return child;
    // // Fades between routes. (If you don't want any animation,
    // // just return child.)
    return new FadeTransition(opacity: animation, child: child);
  }
}

class _NavigatorPageState extends State<NavigatorPage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return true;
      },
      child: Scaffold(
        body: Navigator(
          key: _navigatorKey,
          initialRoute: routeLogin,
          onGenerateRoute: _onGenerateRoute,
        ),
      ),
    );
  }

  Route _onGenerateRoute(RouteSettings settings) {
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
    }

    return AnimatedRoute(
      builder: (context) {
        return page;
      },
      settings: settings,
    );
  }
}
