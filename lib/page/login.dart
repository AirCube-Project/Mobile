import 'dart:convert';

import 'package:aircube/model/survey.dart';
import 'package:auth_buttons/auth_buttons.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health/health.dart';
import 'package:provider/provider.dart';
import '../widget/beauty_button.dart';
import '../model/state.dart';

import '../constants.dart';
import 'main.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(
  // Optional clientId
  // clientId: '479882132969-9i9aqik3jfjd7qhci1nqf0bm2g71rm1u.apps.googleusercontent.com',
  // clientId:
  //     "533588565528-gt6cvsjj9fjkn62n961c9c3gtb969r79.apps.googleusercontent.com",
  scopes: <String>[
    'email'
  ],
);

class LoginPage extends StatefulWidget {

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;
  bool passwordRecoveryMode = false;
  bool registerMode = false;

  String name;
  String email;
  String password;

  String message;

  GoogleSignInAccount _currentUser;

  Dio dio;

  Future<bool> register(email, password, name) async {
    var data = {"email": email, "password": password, "name": name};
    print(data);
    try {
      await dio.post(publicPrefix + "/accounts/register", data: json.encode(data));
      return true;
    } catch (Exception) {
      return false;
    }
  }

  Future<bool> login(email, password) async {
    var data = {"email": email, "password": password};
    try {
      var response = await dio.post(publicPrefix + "/accounts/auth", data: json.encode(data));
      var state = Provider.of<ApplicationState>(context, listen: false);
      state.token = response.data["token"];

      dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}))
        ..interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
      Future.delayed(Duration(milliseconds: 10), () async {
        var profile = await dio.get(securePrefix + "/profile");
        print("After logged");
        var profileData = await profile.data;

        state.name = profileData["name"];
        state.photo = profileData["photo"];

        print(response.data["survey"]["completed"]);
        if (response.data["survey"]["completed"] == 1) {
          state.survey = Survey.fromJSON(response.data["survey"]);
          print("Survey is got ");
          print(state.survey);
          gotoPage(context, routeToday);
        } else {
          gotoPage(context, routeSurveyFirst);
        }
      });
        return true;
    } catch (Exception) {
      return false;
    }
  }

  Future<bool> resetPassword(email) async {
    var data = {"email": email};
    try {
      await dio.post(publicPrefix + "/accounts/recover", data: json.encode(data));
      return true;
    } catch (Exception) {
      return false;
    }
  }

  void loggedIn(GoogleSignInAccount account) async {
    var signIn = {
      "email": account.email,
      "name": account.displayName,
      "hash": account.hashCode
    };
    // try {
    var response = await dio.post(
        publicPrefix + "/accounts/auth_google", data: json.encode(signIn));
    setState(() {
      message = null;
      print("Congrats, email is " + account.email);
    });
    var state = Provider.of<ApplicationState>(context, listen: false);

    state.googleSignIn = _googleSignIn;
    print(response.data);
    state.name = response.data["data"]["name"];
    state.token = response.data["token"];
    state.user = account;
    print(state.name);
    print(state.token);

    //get profile

    var name = account.displayName;
    var photo = account.photoUrl;
    dio = Dio(BaseOptions(headers: {'Authorization': 'bearer ' + state.token}))
      ..interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
    var profile = await dio.get(securePrefix+"/profile");
    print("After logged");
    var profileData = await profile.data;
    if (profileData["name"]==null) {
      //скопировать из google-авторизации
      var data = {"name": name};
      await dio.put(securePrefix+"/profile", data: json.encode(data));
      state.name = name;
    } else {
      state.name = profileData["name"];
    }
    if (profileData["photo"]==null) {
      //сохранить ссылку на фотографию в google
      var data = {"photo": photo};
      await dio.put(securePrefix+"/profile", data: json.encode(data));
      state.photo = photo;
    } else {
      state.photo = profileData["photo"];
    }

    print(response.data["survey"]["completed"]);
    if (response.data["survey"]["completed"]==1) {
      state.survey = Survey.fromJSON(response.data["survey"]);
      print("Survey is got ");
      print(state.survey);
      gotoPage(context, routeToday);
    } else {
      gotoPage(context, routeSurveyFirst);
    }
    // } catch (Exception) {
    //   setState(() {
    //     message = "Учётная запись не привязана к Google";
    //   });
    // }
  }

  var showUI = false;

  @override
  void initState() {
    super.initState();
    dio = Dio()
      ..interceptors.add(LogInterceptor(responseBody: true, requestBody: true));

    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) async {
      loggedIn(account);
    });
    Future.delayed(Duration(microseconds: 10), () async {
      if (await _googleSignIn.isSignedIn()) {
        print("SIGNED");
        _googleSignIn.signInSilently();
        Future.delayed(Duration(seconds: 3), () {
          setState(() {
            showUI = true;
          });
        });
      } else {
        setState(() {
          showUI = true;
        });
      }
    });
      }

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context);
    return showUI ? KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
      return Stack(
        children: [
          Center(
              child: Container(
                // color: Colors.lightGreen,
                height: 48 + (isKeyboardVisible ? 424.0 - 128.0 : 424.0) +
                    (message != null ? 32 : 0) + (registerMode ? 96 : 0) -
                    (passwordRecoveryMode ? 64 : 0),
                child: Column(
                  children: [
                    if (!isKeyboardVisible || passwordRecoveryMode)
                      Container(
                          padding: EdgeInsets.only(bottom: 32),
                          height: 128,
                          child: SizedBox(
                              width: mq.size.width * 0.8,
                              child: Image.asset("assets/logo.png"))),
                    if (!passwordRecoveryMode)
                      GoogleAuthButton(
                        key: const ValueKey<String>(''),
                        onPressed: () async {
                          try {
                            await _googleSignIn.signIn();
                          } catch (error) {
                            print(error);
                          }
                        },
                        onLongPress: () {},
                        text: (registerMode ? 'Регистрация' : 'Войти') +
                            ' с помощью Google',
                        darkMode: false,
                        isLoading: isLoading,
                        rtl: false,
                        style: AuthButtonStyle(
                          buttonColor: Colors.white,
                          splashColor: Colors.grey.shade100,
                          shadowColor: Colors.black38,
                          borderColor: Colors.black12,
                          borderRadius: 24.0,
                          borderWidth: 1.0,
                          elevation: 8.0,
                          width: mq.size.width > 360
                              ? mq.size.width * 0.8
                              : 320,
                          height: 48.0,
                          separator: 10.0,
                          iconSize: 40.0,
                          iconBackground: Colors.transparent,
                          iconType: AuthIconType.secondary,
                          buttonType: AuthButtonType.secondary,
                          padding: const EdgeInsets.all(8.0),
                          textStyle: const TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                          ),
                          progressIndicatorColor: Theme
                              .of(context)
                              .primaryColor,
                          progressIndicatorValueColor:
                          Theme
                              .of(context)
                              .primaryColor,
                          progressIndicatorStrokeWidth: 2.0,
                        ),
                      ),
                    if (!passwordRecoveryMode)
                      Container(
                        padding: EdgeInsets.only(top: 32),
                        child: Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    thickness: 1.5,
                                    indent: mq.size.width * 0.3,
                                    endIndent: 8,
                                    color: Colors.black54)),
                            Text(
                              "или",
                              style: TextStyle(color: Colors.black54),
                            ),
                            Expanded(
                                child: Divider(
                                    thickness: 1.5,
                                    indent: 8,
                                    endIndent: mq.size.width * 0.3,
                                    color: Colors.black54)),
                          ],
                        ),
                      ),
                    if (registerMode)
                      Container(
                        padding: EdgeInsets.only(
                            left: mq.size.width * 0.1,
                            right: mq.size.width * 0.1,
                            top: 32),
                        child: TextField(
                            key: ValueKey("name"),
                            controller: TextEditingController(text: name),
                            onChanged: (val) {
                              name = val;
                            },
                            decoration: InputDecoration(
                              contentPadding:
                              EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              hintText: "Ваше имя",
                            )),
                      ),
                    Container(
                      padding: EdgeInsets.only(
                          left: mq.size.width * 0.1,
                          right: mq.size.width * 0.1,
                          top: registerMode ? 16 : 32),
                      child: TextField(
                          key: ValueKey("email"),
                          controller: TextEditingController(text: email),
                          onChanged: (val) {
                            email = val;
                          },
                          decoration: InputDecoration(
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            hintText: "E-Mail",
                          )),
                    ),
                    if (!passwordRecoveryMode)
                      Container(
                        padding: EdgeInsets.only(
                            left: mq.size.width * 0.1,
                            right: mq.size.width * 0.1,
                            top: 16),
                        child: TextField(
                            controller: TextEditingController(text: password),
                            key: ValueKey("password"),
                            onChanged: (val) {
                              password = val;
                            },
                            obscureText: true,
                            decoration: InputDecoration(
                              contentPadding:
                              EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              hintText: "Пароль",
                            )),
                      ),
                    Container(
                      padding: EdgeInsets.only(top: 16),
                      width: mq.size.width * 0.8,
                      height: 56,
                      child: BeautyButton(
                          text: !passwordRecoveryMode
                              ? (!registerMode ? "Вход" : "Регистрация")
                              : "Восстановить пароль",
                          background: Theme
                              .of(context)
                              .primaryColor,
                          foreground: Theme
                              .of(context)
                              .buttonColor,
                          elevation: 4,
                          onClick: () async {
                            if (!passwordRecoveryMode) {
                              if (registerMode) {
                                var result = await register(
                                    email, password, name);
                                setState(() {
                                  if (!result) {
                                    message =
                                    "Такой e-mail уже зарегистрирован";
                                  } else {
                                    message = null;
                                  }
                                });
                              } else {
                                var result = await login(email, password);
                                setState(() {
                                  if (!result) {
                                    message = "Неправильный e-mail или пароль";
                                  } else {
                                    message = null;
                                  }
                                });
                              }
                            } else {
                              var result = await resetPassword(email);
                              setState(() {
                                if (!result) {
                                  message = "Адрес e-mail не зарегистрирован";
                                } else {
                                  passwordRecoveryMode = false;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(
                                          "Новый пароль отправлен на E-Mail")));
                                  message = null;
                                }
                              });
                            }
                          }),
                    ),
                    if (message != null)
                      Container(
                          padding: EdgeInsets.only(top: 16),
                          height: 32,
                          child: Text(
                            message,
                            style: TextStyle(
                                fontSize: 14, color: Theme
                                .of(context)
                                .errorColor),
                          )),

                  ],
                ),
              )),
          Positioned(
            child: Container(
              width: mq.size.width,
              child: Column(
                children: [
                  if (!passwordRecoveryMode)
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text("Забыли пароль?"),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              passwordRecoveryMode = true;
                              registerMode = false;
                              message = null;
                            });
                          },
                          child: Text(
                            "Восстановить пароль",
                            style: TextStyle(
                                color: Theme
                                    .of(context)
                                    .primaryColor),
                          ),
                        ),
                      )
                    ]),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          passwordRecoveryMode = false;
                          registerMode = !registerMode;
                          message = null;
                        });
                      },
                      child: Text(
                        !registerMode ? "Зарегистрироваться" : "Войти",
                        style: TextStyle(color: Theme
                            .of(context)
                            .primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottom: 24,
          )
        ],
      );
    }) : Center(child: SizedBox(width: 64, height: 64, child: CircularProgressIndicator()),);
  }
}