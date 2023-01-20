import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/db/user_chat_model.dart';
import 'package:masterme_chat/fonts/funtya.dart';
import 'package:masterme_chat/helpers/log.dart';
import 'package:masterme_chat/models/companies/catalogue.dart';
import 'package:masterme_chat/screens/companies/companies_listing_screen.dart';
import 'package:masterme_chat/screens/logic/companies_logic.dart';
import 'package:masterme_chat/widgets/call/in_call_widget.dart';
import 'package:masterme_chat/widgets/companies/catalogue_in_update.dart';
import 'package:masterme_chat/widgets/companies/floating_search_widget.dart';

class TabHomeView extends StatefulWidget {
  final Function setStateCallback;
  final PageController pageController;
  Map<String, dynamic> userData;

  // Т/к виджет будет пересоздаваться из root_wizard_screen
  // надо сразу оттуда передавать данные по curUser & loggedIn
  UserChatModel curUser;
  bool loggedIn = false;

  TabHomeView({this.pageController, this.setStateCallback, this.userData});

  @override
  _TabHomeViewState createState() => _TabHomeViewState();
}

class _TabHomeViewState extends State<TabHomeView> {
  static const TAG = 'TabHomeView';
  CompaniesScreenLogic logic;

  List<Catalogue> rubrics = [];

  @override
  void initState() {
    logic = CompaniesScreenLogic(setStateCallback: setStateCallback);
    // Прогружаем данные
    logic.loadCatalogue();
    super.initState();

    // Тестируем оверлей
    //showInCallOverlay('89999999999=>89148959223');
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void deactivate() {
    logic.deactivate();
    super.deactivate();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  // Обновление состояния
  void setStateCallback(Map<String, dynamic> state) {
    setState(() {
      if (state['rubrics'] != null) {
        rubrics = state['rubrics'];
      }
    });
  }

  Widget buildFloatingSearch() {
    return Stack(
      children: [
        CompaniesFloatingSearchWidget(),
      ],
    );
  }

  Widget buildAvatar(Catalogue rubric) {
    if (rubric.name == null) {
      return Icon(Icons.home_work_outlined);
    }
    if (rubric.icon != null && rubric.icon != '') {
      return Icon(
        Funtya.getIcon(rubric.icon),
        size: 42.0,
        color: rubric.color,
      );
    }
    return CircleAvatar(
      backgroundColor: rubric.color,
      child: Text('${rubric.name}'[0]),
    );
  }

  Widget buildRubricForRowMore() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          widget.setStateCallback({
            'setPageview': 5,
          });
        },
        child: Column(
          children: [
            Container(
              child: Container(
                child: Icon(
                  Icons.more_horiz,
                  size: 42.0,
                  color: Colors.green,
                ),
                height: 60.0,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5.0),
              child: Container(
                child: Text(
                  'Показать все',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRubricForRow(Catalogue rubric) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, CompaniesListingScreen.id, arguments: {
            'curCat': rubric,
          });
        },
        child: Column(
          children: [
            Container(
              child: Container(
                child: buildAvatar(rubric),
                height: 60.0,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5.0),
              child: Container(
                child: Text(
                  rubric.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCatalogue() {
    if (rubrics.length == 0) {
      return CatalogueInUpdate();
    }
    // Сортируем по позиции рубрики
    for (Catalogue rubric in rubrics) {
      if (rubric.position == null) {
        Log.d(TAG, 'pos null: $rubric');
        rubric.position = 9999;
      }
    }
    rubrics.sort((a, b) => a.position.compareTo(b.position));

    return Column(
            children: [
              // Подложка для поиска
              buildPanelForSearch(),
              SIZED_BOX_H12,
              Expanded(
                child: ListView(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(45),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey[300],
                            offset: Offset(-2, 0),
                            blurRadius: 7,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildRubricForRow(rubrics[0]),
                              buildRubricForRow(rubrics[1]),
                              buildRubricForRow(rubrics[2]),
                              buildRubricForRow(rubrics[3]),
                            ],
                          ),
                          SIZED_BOX_H20,
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildRubricForRow(rubrics[5]),
                              buildRubricForRow(rubrics[6]),
                              buildRubricForRow(rubrics[7]),
                              buildRubricForRowMore(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SIZED_BOX_H24,

                    CarouselSlider(
                      options: CarouselOptions(
                        aspectRatio: 2.0,
                        enlargeCenterPage: true,
                        scrollDirection: Axis.horizontal,
                        autoPlay: false,
                      ),
                      items: imageSliders,
                    ),

/*
                    ActionButton(
                      title: 'test',
                      onPressed: () {
                        PushNotificationsManager.showNotificationCustomSound();
                      },
                    ),
 */
                  ],
                ),
              ),
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        buildCatalogue(),
        buildFloatingSearch(),
      ],
    );
  }
}

final List<String> imgList = [
  '${DB_SERVER}${DB_LOGO_PATH}app_slider/1.jpg',
  '${DB_SERVER}${DB_LOGO_PATH}app_slider/2.jpg',
];

final List<Widget> imageSliders = imgList
    .map((item) => Container(
          child: Container(
            margin: EdgeInsets.all(5.0),
            child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(5.0)),
                child: Stack(
                  children: <Widget>[

                    //Image.network(item, fit: BoxFit.cover, width: 1000.0),
                    CachedNetworkImage(
                      height: double.infinity,
                      width: 1000.0,
                      imageUrl: item,
                      fit: BoxFit.cover,
                    ),

                    Positioned(
                      bottom: 0.0,
                      left: 0.0,
                      right: 0.0,
                      child: Container(
                        /*
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromARGB(200, 0, 0, 0),
                              Color.fromARGB(0, 0, 0, 0)
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        */
                        padding: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 20.0),
                        /* Test for each slide */
                        /*
                        child: Text(
                          'No. ${imgList.indexOf(item)} image',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        */
                      ),
                    ),
                  ],
                )),
          ),
        ))
    .toList();
