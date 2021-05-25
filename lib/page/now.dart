//Страница "Сейчас"
import 'package:flutter/material.dart';
import '../model/activity.dart';

class NowPage extends StatelessWidget {
  //Описание основной активности
  Activity primaryActivity;

  //Описания альтернативной активностей
  List<Activity> secondaryActivities;

  //Конструктор
  NowPage(this.primaryActivity, this.secondaryActivities) {}

  @override
  Widget build(BuildContext context) {
    //Получить размер экрана
    var mq = MediaQuery.of(context);
    return Container(
      //Контейнер на весь экран (за исключением области навигации и строки состояния)
      width: mq.size.width,
      height: mq.size.height,
      child: Stack(children: [
        //Верхняя прокручиваемая часть
        Positioned(
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //Заголовок страницы
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                        child: Text(
                          "Сейчас",
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          //Основная активность
                          child: Card(
                            //Карточка со скруглением
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(16)),
                              ),
                              child: Stack(children: [
                                //Скругление основного изображения
                                ClipRRect(
                                    borderRadius: BorderRadius.all(Radius.circular(16)),
                                    child: Image.asset(primaryActivity.image,
                                        fit: BoxFit.cover)),
                                //Отображение нижней панели с кнопкой активации
                                Positioned(
                                    bottom: 0,
                                    child: Container(
                                      //Скругление фона (по нижней границе)
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.only(
                                                bottomLeft: Radius.circular(16),
                                                bottomRight: Radius.circular(16))),
                                        width: mq.size.width - 2 * 16,
                                        child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                            children: [
                                              //Название активности
                                              Padding(
                                                  padding: EdgeInsets.only(
                                                      top: 16.0,
                                                      bottom: 16.0,
                                                      left: 24.0),
                                                  child: Text(primaryActivity.name,
                                                      style: TextStyle(fontSize: 16))),
                                              //Кнопка активации
                                              Padding(
                                                padding: EdgeInsets.only(right: 16),
                                                child: IconButton(
                                                    icon: Icon(
                                                      Icons.thumb_up_alt_outlined,
                                                      color: Colors.black38,
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context).pushNamed(
                                                          "/take/" +
                                                              primaryActivity.id.toString());
                                                    }),
                                              )
                                            ])))
                              ]))),
                      //Вывод альтернативных активностей
                      for (Activity event in secondaryActivities)
                        Padding(
                          //Карточка со скруглениями
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16)),
                                ),
                                child: SizedBox(
                                  width: mq.size.width - 2 * 16,
                                  height: 64,
                                  child: Stack(children: [
                                    //Изображение активности (квадрат 64х64 от центра)
                                    ClipRRect(
                                      //Скругление по левой стороне
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            bottomLeft: Radius.circular(16)),
                                        child: Container(
                                            width: 64,
                                            height: 64,
                                            //кадрировать изображение в квадрат (от центра)
                                            child: Image.asset(
                                              event.image,
                                              fit: BoxFit.cover,
                                              alignment: FractionalOffset.center,
                                            ))),
                                    //Название активности
                                    Positioned(
                                        top: 8,
                                        left: 64,
                                        child: Container(
                                          // decoration: BoxDecoration(
                                          //     color: Colors.white,
                                          //     borderRadius: BorderRadius.only(
                                          //         bottomLeft: Radius.circular(16),
                                          //         bottomRight: Radius.circular(16))),
                                            width: mq.size.width - 2 * 16,
                                            child: Padding(
                                                padding: EdgeInsets.only(
                                                    top: 16.0,
                                                    bottom: 16.0,
                                                    left: 24.0),
                                                child: Text(event.name,
                                                    style:
                                                    TextStyle(fontSize: 16))))),
                                    //Кнопка активации
                                    Positioned(
                                      top: 8,
                                      child: IconButton(
                                          icon: Icon(Icons.thumb_up_outlined,
                                            color: Colors.black38,
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pushNamed(
                                                "/take/" +
                                                    event.id.toString());
                                          }),
                                      right: 8,

                                    )
                                  ]),
                                ))),
                    ]))),
        //Нижняя панель (отказ от предложенных активностей)
        Positioned(
            width: mq.size.width,
            bottom: 16,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //Текст (слева, ширина не более половины ширины экрана)
                  Container(
                    padding: EdgeInsets.only(left: 16),
                    width: mq.size.width*0.5,
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
                        onPressed: () {
                          Navigator.of(context).pushNamed("/cancel");
                        },
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text("Отказаться",
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        )),
                  )
                ]))
      ]),
    );
  }
}
