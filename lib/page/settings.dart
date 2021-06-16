import 'dart:convert';

import 'package:aircube/constants.dart';
import 'package:aircube/model/state.dart';
import 'package:aircube/page/main.dart';
import 'package:dio/dio.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/oauth2/v2.dart' as oauth;
import 'package:health/health.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsItemWidget extends StatelessWidget {
  String title;

  String titleConnected;

  bool connected;

  Widget icon;

  Function onTap;

  SettingsItemWidget(this.connected, this.title, this.titleConnected, this.icon, this.onTap, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context);
    return GestureDetector(
      onTap: !this.connected ? onTap : null,
      child: Row(
        children: [
          GestureDetector(
            onTap: !this.connected ? onTap : null,
            child: SizedBox(
              height: 64,
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                  child: SizedBox(width: 64, height: 64, child: icon)),
            ),
          ),
          GestureDetector(
            onTap: !this.connected ? onTap : null,
            child: SizedBox(
                width: mq.size.width - 224,
                child: (!this.connected)
                    ? Text(this.title, style: TextStyle(fontSize: 12))
                    : Text(this.titleConnected, style: TextStyle(fontSize: 12))),
          ),
          if (this.connected) SizedBox(width: 32, height: 32, child: Icon(Icons.check_circle, color: Colors.green)),
        ],
      ),
    );
  }
}

class TaskManagerWidget extends StatelessWidget {
  String title;

  Widget icon;

  bool connected;

  Function onTap;

  Function onDisconnect;

  TaskManagerWidget(this.connected, this.title, this.icon, this.onTap, this.onDisconnect, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: !connected ? onTap : onDisconnect,
      child: Card(
        elevation: 1,
        child: AspectRatio(
            aspectRatio: 1,
            child: Column(children: [
              Padding(padding: EdgeInsets.only(top: 16, bottom: 8), child: SizedBox(width: 64, height: 64, child: icon)),
              Text(this.title),
              if (!connected)
                Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      "Подключить",
                      style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10),
                    )),
              if (connected)
                Padding(padding: EdgeInsets.only(top: 0), child: Text("Подключено", style: TextStyle(fontSize: 10))),
              if (connected)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text("Отключить", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10)),
                )
            ])),
      ),
    );
  }
}

Future<double> getWeight() async {
  var health = HealthFactory();
  var types = [HealthDataType.WEIGHT];
  var today = DateTime.now();
  var startOfDay = DateTime(today.year, today.month, today.day);
  var endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
  DateTime startDate = startOfDay;
  DateTime endDate = today;
  var data = await health.getHealthDataFromTypes(startDate, endDate, types);
  var diff = 1;
  while (data.isEmpty && diff < 30) {
    DateTime startDate = startOfDay.subtract(Duration(days: diff));
    DateTime endDate = endOfDay.subtract(Duration(days: diff));
    data = await health.getHealthDataFromTypes(startDate, endDate, types);
    if (data.isEmpty) {
      diff++;
      print("Diff ");
      print(diff);
    }
    print(data);
  }
  if (data.isEmpty) {
    return null;
  }
  return data.last.value;
}

Future<int> getSteps() async {
  var health = HealthFactory();
  var types = [HealthDataType.STEPS];
  var now = DateTime.now();
  var startDate = now.subtract(Duration(minutes: 30));
  var data = await health.getHealthDataFromTypes(startDate, now, types);
  var startInterval = now.subtract(Duration(minutes: 15));
  var steps = 0.0;
  print(startDate);
  print(now);
  data.forEach((element) {
    if (!(element.dateFrom.isBefore(startInterval) && element.dateTo.isBefore(startInterval))) {
      //todo: check last steps!
      var start = element.dateFrom;
      if (start.isBefore(startInterval)) start = startInterval;
      var end = element.dateTo;
      var delta = end.difference(start).inMilliseconds;
      steps += element.value * delta / (element.dateTo.difference(element.dateFrom).inMilliseconds);
    }
  });
  return steps.toInt();
}

Future<double> getSleepDuration(GoogleSignInAccount account) async {
  var now = DateTime.now();
  var utc = now.toUtc();
  var startOfDay = utc.subtract(Duration(hours: utc.hour, minutes: utc.minute, seconds: utc.second));
  var sleepStart = startOfDay.subtract(Duration(hours: 4));
  print(account.authHeaders);
  var dio = Dio(BaseOptions(headers: await account.authHeaders));
  var isoStart = startOfDay.toIso8601String().replaceAll(" ", "T");
  var isoEnd = utc.toIso8601String().replaceAll(" ", "T");
  var url = "https://www.googleapis.com/fitness/v1/users/me/sessions?startTime=${isoStart}&endTime=${isoEnd}&activityType=72";
  print(url);
  var response = await dio.get(url);
  if (response.statusCode == 200) {
    //get sleep duration
    var sleepDuration = 0.0;
    var data = await response.data;
    data["session"].forEach((session) {
      sleepDuration += (int.parse(session["endTimeMillis"]) - int.parse(session["startTimeMillis"])) / (1000 * 60);
    });
    return sleepDuration;
  }
  return null;
}

class GoogleClient extends http.BaseClient {
  GoogleSignInAccount account;

  GoogleClient(this.account) {
    _inner = http.Client();
  }

  http.Client _inner;

  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    var auth = await account.authHeaders;
    print("Auth is $auth");
    request.headers["Authorization"] = auth["Authorization"];
    return _inner.send(request);
  }
}

//проверить доступность scope
Future<bool> isScopeEnabled(GoogleSignInAccount account, String scope) async {
  var client = GoogleClient(account);
  var api = oauth.Oauth2Api(client);
  var info = await api.tokeninfo();
  var scopes = info.scope.split(" ");
  return scopes.contains(scope);
}

Future<List<String>> buildScopes(GoogleSignInAccount account) async {
  var scopes = <String>["email"];
  if (await isScopeEnabled(account, "https://www.googleapis.com/auth/fitness.activity.read")) {
    scopes.add("https://www.googleapis.com/auth/fitness.activity.read");
    scopes.add("https://www.googleapis.com/auth/fitness.body.read");
    scopes.add("https://www.googleapis.com/auth/fitness.sleep.read");
  }
  if (await isScopeEnabled(account, "https://www.googleapis.com/auth/calendar.events")) {
    scopes.add("https://www.googleapis.com/auth/calendar.events");
  }
  return scopes;
}

requestScopes(BuildContext context, List<String> scopes) async {
  var state = Provider.of<ApplicationState>(context, listen: false);
  var account = state.user;
  scopes.addAll(await buildScopes(account));
  await state.googleSignIn.requestScopes(scopes);
  state.lastUpdated = DateTime.now();
}

isCalendarConnected(GoogleSignInAccount account) async {
  return isScopeEnabled(account, "https://www.googleapis.com/auth/calendar.events");
}

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Define the types to get.
  List<HealthDataType> types = [
    HealthDataType.STEPS,
    HealthDataType.WEIGHT,
    HealthDataType.SLEEP_IN_BED,
  ];

  TextEditingController gitlabServerTEC;
  TextEditingController gitlabTokenTEC;
  TextEditingController githubTokenTEC;
  TextEditingController trelloKeyTEC;
  TextEditingController trelloTokenTEC;
  TextEditingController cubeTEC;

  String gitlabToken;
  String githubToken;
  String trelloToken;

  bool fitConnected = false;
  bool calendarConnected = false;
  bool gitlabConnected = false;
  bool githubConnected = false;
  bool trelloConnected = false;

  Dio dio;

  @override
  void initState() {
    gitlabServerTEC = TextEditingController(text: "gitlab.com");
    gitlabTokenTEC = TextEditingController();
    githubTokenTEC = TextEditingController();
    trelloKeyTEC = TextEditingController();
    trelloTokenTEC = TextEditingController();
    cubeTEC = TextEditingController();

    var state = Provider.of<ApplicationState>(context, listen: false);
    state.connectionCode = "";

    gitlabServerTEC.addListener(() {
      state.gitlabServer = gitlabServerTEC.text;
    });
    trelloKeyTEC.addListener(() {
      state.trelloKey = trelloKeyTEC.text;
    });
    gitlabTokenTEC.addListener(() {
      state.gitlabToken = gitlabTokenTEC.text;
    });
    githubTokenTEC.addListener(() {
      state.githubToken = githubTokenTEC.text;
    });
    trelloTokenTEC.addListener(() {
      state.trelloToken = trelloTokenTEC.text;
    });
    cubeTEC.addListener(() {
      print("CubeTEC");
      var value = cubeTEC.text;
      state.connectionCode = value;
      print("Update to ${state.connectionCode}");
    });

    print("STATE token is ${state.token}");
    dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}))
      ..interceptors.add(LogInterceptor(responseBody: true, requestBody: true));

    Future.delayed(Duration(milliseconds: 200), () async {
      await getSettings(state);
    });
  }

  EncryptedSharedPreferences prefs;

  Future getSettings(ApplicationState state) async {
    var calendar = false;
    try {
      calendar = await isCalendarConnected(state.user);
    } catch (e) {}
    HealthFactory health = HealthFactory();
    var fit = false;
    try {
      fit = await health.hasPermissions(types);
    } catch (e) {}

    //получить токены авторизации (для отображения состояния интеграций)
    var response = await dio.get(securePrefix + "/integrations");
    var data = {};
    if (response.statusCode == 200) {
      data = await response.data;
    } else {
      print("Error in get integrations");
    }

    fitConnected = fit;
    calendarConnected = calendar;

    state.gitlabServer = data["gitlab_domain"];
    state.gitlabToken = data["gitlab_token"];
    var glb = await checkGitLab(state);

    state.githubToken = data["github_token"];
    var ghb = await checkGitHub(state);

    state.trelloKey = data["trello_key"];
    state.trelloToken = data["trello_token"];
    var tlc = await checkTrello(state);

    setState(() {
      gitlabConnected = glb;
      githubConnected = ghb;
      trelloConnected = tlc;
    });
    return {};
  }

  Future<bool> checkGitLab(ApplicationState state) async {
    var dio = Dio(BaseOptions(headers: {"PRIVATE-TOKEN": state.gitlabToken}));
    var server = state.gitlabServer;
    try {
      var response = await dio.get("https://$server/api/v4/user");
      if (response.statusCode == 200) {
        //bound completed
        print("Bound!");
        print(await response.data);
        return true;
      } else {
        print("Error in bound!");
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  disconnectGitlab() async {
    try {
      var response = await dio.get(securePrefix + "/integrations");
      var data = await response.data;
      data["gitlab_token"] = null;
      data["gitlab_domain"] = null;
      dio.put(securePrefix + "/integrations", data: json.encode(data));
      return true;
    } catch (e) {
      return false;
    }
  }

  connectGitlab(ApplicationState state) async {
    try {
      var response = await dio.get(securePrefix+"/integrations");
      var data = await response.data;
      data["gitlab_token"] = state.gitlabToken;
      data["gitlab_domain"] = state.gitlabServer;
      dio.put(securePrefix + "/integrations", data: json.encode(data));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkGitHub(ApplicationState state) async {
    var dio =
        Dio(BaseOptions(headers: {"Accept": "application/vnd.github.v3+json", "Authorization": "token " + state.githubToken}));
    try {
      var response = await dio.get("https://api.github.com/user");
      if (response.statusCode == 200) {
        //bound completed
        print("Bound!");
        print(await response.data);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  disconnectGitHub() async {
    try {
      var response = await dio.get(securePrefix + "/integrations");
      var data = await response.data;
      data["github_token"] = null;
      dio.put(securePrefix + "/integrations", data: json.encode(data));
      return true;
    } catch (e) {
      return false;
    }
  }

  connectGitHub(ApplicationState state) async {
    try {
      var response = await dio.get(securePrefix+"/integrations");
      var data = await response.data;
      data["github_token"] = state.githubToken;
      dio.put(securePrefix + "/integrations", data: json.encode(data));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkTrello(ApplicationState state) async {
    var dio = Dio();
    var url = "https://api.trello.com/1/tokens/${state.trelloToken}?key=${state.trelloKey}&token=${state.trelloToken}";
    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        print("Bound");
        print(await response.data);
        return true;
      } else {
        print("Error");
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  disconnectTrello() async {
    try {
      var response = await dio.get(securePrefix + "/integrations");
      var data = await response.data;
      data["trello_token"] = null;
      data["trello_key"] = null;
      dio.put(securePrefix + "/integrations", data: json.encode(data));
      return true;
    } catch (e) {
      return false;
    }
  }

  connectTrello(ApplicationState state) async {
    try {
      var response = await dio.get(securePrefix+"/integrations");
      var data = await response.data;
      data["trello_token"] = state.trelloToken;
      data["trello_key"] = state.trelloKey;
      print("Trello connect");
      print(data);
      dio.put(securePrefix + "/integrations", data: json.encode(data));
      return true;
    } catch (e) {
      return false;
    }
  }



  var connectionCode;

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context);
    HealthFactory health = HealthFactory();
    return WillPopScope(
      onWillPop: () async {
        print("Settings back");
        Navigator.of(context).pushReplacementNamed(routeProfile);
        return false;
      },
      child: Scaffold(
          backgroundColor: Colors.white,

          appBar: AppBar(title: Text("Настройки")),
          body: Stack(children: [
            Container(
                height: mq.size.height - 192,
                child: SingleChildScrollView(
                    child: Container(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                        width: mq.size.width - 32,
                        height: 64,
                        child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                            elevation: 6,
                            child: SettingsItemWidget(
                                false, "Подключить устройство Cube", "", Image.asset("assets/cube.png"), () {
                              showModalBottomSheet(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Consumer<ApplicationState>(builder: (context, state, child) {
                                      return SingleChildScrollView(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Column(children: [
                                            Padding(
                                                padding: EdgeInsets.only(bottom: 16),
                                                child: Text("Подключение Cube",
                                                    style:
                                                    TextStyle(fontSize: 20, color: Theme.of(context).primaryColor))),
                                            Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                            child: Text("Введите код, отображаемый на устройстве или в эмуляторе",  style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16))),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                                              child: TextFormField(
                                                controller: cubeTEC,
                                                obscureText: true,
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  labelText: 'Код подключения',
                                                ),
                                              ),
                                            ),
                                            if (state.connectionCode!=null && state.connectionCode.isNotEmpty)
                                              TextButton(
                                                  onPressed: () async {
                                                    var pinData = {
                                                      "pin": state.connectionCode
                                                    };
                                                    var response = await dio.post(securePrefix+"/register_device", data: json.encode(pinData));
                                                    if (response.statusCode==200) {
                                                      print("Registered");
                                                    }
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text("Подключить", style: TextStyle(fontSize: 16))),
                                          ]),
                                        ),
                                      );
                                    });
                                  });
                            }))),
                    Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text("Сервисы Google", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10))),
                    SizedBox(
                        width: mq.size.width - 32,
                        height: 200,
                        child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                            elevation: 6,
                            child: Column(
                              children: [
                                SettingsItemWidget(
                                    false, "Подключить Google Home", "", Image.asset("assets/google-home-logo.png"), () async {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(content: Text("Будет реализовано в будущем")));
                                }),
                                SettingsItemWidget(calendarConnected, "Подключить Google Calendar", "Google Calendar подключен",
                                    Image.asset("assets/google-calendar.jpeg"), () async {
                                  requestScopes(context, [
                                    "https://www.googleapis.com/auth/calendar.events",
                                  ]);
                                  var state = Provider.of<ApplicationState>(context);
                                  var cc = await isScopeEnabled(state.user, "https://www.googleapis.com/auth/calendar.events");
                                  setState(() {
                                    calendarConnected = cc;
                                  });
                                }),
                                SettingsItemWidget(fitConnected, "Подключить Google Fit", "Google Fit подключен",
                                    Image.asset("assets/google-fit.png"), () async {
                                  bool accessWasGranted = await health.requestAuthorization(types);
                                  if (!accessWasGranted) {
                                    print("Access isn't granted");
                                  } else {
                                    print("Access is granted");
                                    var state = Provider.of<ApplicationState>(context, listen: false);
                                    state.lastUpdated = DateTime.now();
                                    //get weight for last day
                                  }
                                  setState(() {
                                    fitConnected = accessWasGranted;
                                  });
                                })
                              ],
                            ))),
                    Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text("Менеджеры задач", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10))),
                    SizedBox(
                        width: mq.size.width - 32,
                        height: 176,
                        child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                            elevation: 6,
                            child: SizedBox(
                              height: 176,
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    TaskManagerWidget(trelloConnected, "Trello", Image.asset("assets/trello.jpg"), () {
                                      showModalBottomSheet(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Consumer<ApplicationState>(builder: (context, state, child) {
                                              return SingleChildScrollView(
                                                child: Padding(
                                                  padding: EdgeInsets.all(16),
                                                  child: Column(children: [
                                                    Padding(
                                                        padding: EdgeInsets.only(bottom: 16),
                                                        child: Text("Подключение Trello",
                                                            style:
                                                                TextStyle(fontSize: 20, color: Theme.of(context).primaryColor))),
                                                    Linkify(
                                                        onOpen: (link) async {
                                                          await launch(link.url);
                                                        },
                                                        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
                                                        linkStyle:
                                                            TextStyle(color: Theme.of(context).primaryColorDark, fontSize: 16),
                                                        text:
                                                            "Перейдите по ссылке https://trello.com/app-key и введите ключ доступа ниже:"),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                                      child: TextFormField(
                                                        controller: trelloKeyTEC,
                                                        obscureText: true,
                                                        decoration: InputDecoration(
                                                          border: OutlineInputBorder(),
                                                          labelText: 'Ключ доступа',
                                                        ),
                                                      ),
                                                    ),
                                                    if (state.trelloKey != null && state.trelloKey.isNotEmpty)
                                                      Linkify(
                                                          options: LinkifyOptions(humanize: false),
                                                          onOpen: (link) async {
                                                            await launch(link.url);
                                                          },
                                                          style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
                                                          linkStyle:
                                                              TextStyle(color: Theme.of(context).primaryColorDark, fontSize: 16),
                                                          text:
                                                              "Перейдите по ссылке https://trello.com/1/authorize?expiration=never&scope=read,write,account&response_type=token&name=AirCube&key=${state.trelloKey} и введите токен доступа ниже:"),
                                                    if (state.trelloKey != null && state.trelloKey.isNotEmpty)
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                                                        child: TextFormField(
                                                          controller: trelloTokenTEC,
                                                          obscureText: true,
                                                          decoration: InputDecoration(
                                                            border: OutlineInputBorder(),
                                                            labelText: 'Токен доступа',
                                                          ),
                                                        ),
                                                      ),
                                                    if (state.trelloKey != null &&
                                                        state.trelloToken != null &&
                                                        state.trelloKey.isNotEmpty)
                                                      TextButton(
                                                          onPressed: () async {
                                                            print("Pressed");
                                                            if (await checkTrello(state)) {
                                                              print("Check ok");
                                                              if (await connectTrello(state)) {
                                                                print("Connect ok");
                                                                setState(() {
                                                                  trelloConnected = true;
                                                                });
                                                              }
                                                            }
                                                            Navigator.pop(context);
                                                          },
                                                          child: Text("Подключить", style: TextStyle(fontSize: 16))),
                                                  ]),
                                                ),
                                              );
                                            });
                                          });
                                    }, () async {
                                      //disconnect trello
                                      print("Trello");
                                      if (await disconnectTrello()) {
                                        setState(() {
                                          trelloConnected = false;
                                        });
                                      }
                                    }),
                                    TaskManagerWidget(githubConnected, "GitHub", Image.asset("assets/github.png"), () {
                                      showModalBottomSheet(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Consumer<ApplicationState>(builder: (context, state, child) {
                                              return SingleChildScrollView(
                                                  child: Padding(
                                                padding: EdgeInsets.all(16),
                                                child: Column(children: [
                                                  Padding(
                                                      padding: EdgeInsets.only(bottom: 16),
                                                      child: Text("Подключение GitHub",
                                                          style: TextStyle(fontSize: 20, color: Theme.of(context).primaryColor))),
                                                  Linkify(
                                                      options: LinkifyOptions(humanize: false),
                                                      onOpen: (link) async {
                                                        await launch(link.url);
                                                      },
                                                      style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
                                                      linkStyle:
                                                          TextStyle(color: Theme.of(context).primaryColorDark, fontSize: 16),
                                                      text:
                                                          "Перейдите по ссылке https://github.com/settings/tokens и введите токен доступа ниже (необходим доступ к repo):"),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                                    child: TextFormField(
                                                      controller: githubTokenTEC,
                                                      obscureText: true,
                                                      decoration: InputDecoration(
                                                        border: OutlineInputBorder(),
                                                        labelText: 'Токен доступа',
                                                      ),
                                                    ),
                                                  ),
                                                  if (state.githubToken != null)
                                                    TextButton(
                                                        onPressed: () async {
                                                          if (await checkGitHub(state)) {
                                                            if (await connectGitHub(state)) {
                                                              setState(() {
                                                                githubConnected = true;
                                                              });
                                                            }
                                                          }
                                                          Navigator.pop(context);
                                                        },
                                                        child: Text("Подключить", style: TextStyle(fontSize: 16))),
                                                ]),
                                              ));
                                            });
                                          });
                                    }, () async {
                                      if (await disconnectGitHub()) {
                                        setState(() {
                                          githubConnected = false;
                                        });
                                      }
                                    }),
                                    TaskManagerWidget(gitlabConnected, "GitLab", Image.asset("assets/gitlab.png"), () {
                                      showModalBottomSheet(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Consumer<ApplicationState>(builder: (context, state, child) {
                                              if (state.gitlabServer == null || state.gitlabServer.isEmpty) {
                                                state.gitlabServer = "gitlab.com";
                                              }
                                              return SingleChildScrollView(
                                                child: Padding(
                                                  padding: EdgeInsets.all(16),
                                                  child: Column(children: [
                                                    Padding(
                                                        padding: EdgeInsets.only(bottom: 16),
                                                        child: Text("Подключение GitLab",
                                                            style:
                                                                TextStyle(fontSize: 20, color: Theme.of(context).primaryColor))),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                                      child: TextFormField(
                                                        controller: gitlabServerTEC,
                                                        decoration: InputDecoration(
                                                          border: OutlineInputBorder(),
                                                          labelText: 'Адрес установки GitLab',
                                                        ),
                                                      ),
                                                    ),
                                                    Linkify(
                                                        options: LinkifyOptions(humanize: false),
                                                        onOpen: (link) async {
                                                          await launch(link.url);
                                                        },
                                                        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
                                                        linkStyle:
                                                            TextStyle(color: Theme.of(context).primaryColorDark, fontSize: 16),
                                                        text:
                                                            "Перейдите по ссылке https://${state.gitlabServer}/-/profile/personal_access_tokens (необходим доступ api) и введите токен доступа ниже:"),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                                      child: TextFormField(
                                                        controller: gitlabTokenTEC,
                                                        obscureText: true,
                                                        decoration: InputDecoration(
                                                          border: OutlineInputBorder(),
                                                          labelText: 'Токен доступа',
                                                        ),
                                                      ),
                                                    ),
                                                    if (state.gitlabToken != null)
                                                      TextButton(
                                                          onPressed: () async {
                                                            if (await checkGitLab(state)) {
                                                              if (await connectGitlab(state)) {
                                                                setState(() {
                                                                  gitlabConnected = true;
                                                                });
                                                              }
                                                            }
                                                            Navigator.pop(context);
                                                          },
                                                          child: Text("Подключить", style: TextStyle(fontSize: 16))),
                                                  ]),
                                                ),
                                              );
                                            });
                                          });
                                    }, () async {
                                      if (await disconnectGitlab()) {
                                        setState(() {
                                          gitlabConnected = false;
                                        });
                                      }
                                    }),
                                  ],
                                ),
                              ),
                            ))),
                  ]),
                ))),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GestureDetector(
                    onTap: () async {
                      var user = GoogleSignIn();
                      await user.disconnect();
                      gotoPage(context, routeLogin);
                    },
                    child: Text(
                      "Выход из системы",
                      style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14),
                    )),
              ),
            )
          ])),
    );
  }
}
