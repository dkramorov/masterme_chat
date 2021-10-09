import 'package:flutter/material.dart';
import 'package:masterme_chat/models/companies/search.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

class CompaniesFloatingSearchWidget extends StatefulWidget {
  @override
  _CompaniesFloatingSearchWidgetState createState() =>
      _CompaniesFloatingSearchWidgetState();
}

class _CompaniesFloatingSearchWidgetState
    extends State<CompaniesFloatingSearchWidget> {

  SearchModel searchModel;
  bool searchProcessing = false;
  List<Widget> searchResult = [];


  @override
  void initState() {
    searchModel = SearchModel(setStateCallback: setStateCallback);
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  // Обновление состояния
  void setStateCallback(Map<String, dynamic> state) {
    setState(() {
      if (state['searchResult'] != null) {
        searchResult = state['searchResult'];
      }
      if (state['searchProcessing'] != null) {
        searchProcessing = state['searchProcessing'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingSearchBar(
      hint: 'Поиск...',

      clearQueryOnClose: true,
      automaticallyImplyBackButton: false,
      iconColor: Colors.grey,
      progress: searchProcessing,
      onQueryChanged: (query) async {
        setState(() {
          searchProcessing = true;
        });
        await searchModel.onQueryChanged(query);
        setState(() {
          searchProcessing = false;
        });
      },
      //onQueryChanged: (query) {},

      //controller: controller,
      scrollPadding: const EdgeInsets.only(top: 16, bottom: 36),
      //transitionDuration: const Duration(milliseconds: 800),
      //transitionCurve: Curves.easeInOut,
      //transition: CircularFloatingSearchBarTransition(),
      isScrollControlled: true,
      backdropColor: Colors.black38,

      //physics: const BouncingScrollPhysics(),
      //axisAlignment: isPortrait ? 0.0 : -1.0,
      openAxisAlignment: 0.0,
      // не надо максималить - пусть на весь экран будет
      //maxWidth: isPortrait ? 600 : 500,
      debounceDelay: const Duration(milliseconds: 500),

      actions: [
        FloatingSearchBarAction(
          showIfOpened: false,
          child: CircularButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ),
        FloatingSearchBarAction.searchToClear(
          showIfClosed: false,
        ),
      ],
      builder: (context, transition) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: Colors.white,
            elevation: 4.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              /*
                  children: Colors.accents.map((color) {
                    return Container(
                      height: 112,
                      width: double.infinity,
                      color: color,
                      child: Text(
                        '${time.second}:${time.millisecond}',
                      ),
                    );
                  }).toList(),
                  */
              children: searchResult,
            ),
          ),
        );
      },
    );
  }
}
