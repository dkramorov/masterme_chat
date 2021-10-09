import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/models/companies/orgs.dart';
import 'package:masterme_chat/screens/companies/tab_branches_view.dart';
import 'package:masterme_chat/screens/companies/tab_company_view.dart';
import 'package:masterme_chat/screens/companies/tab_phones_view.dart';
import 'package:masterme_chat/screens/logic/companies_logic.dart';

class CompanyWizardScreen extends StatefulWidget {
  static const String id = '/company_screen/';

  @override
  _CompanyWizardScreenState createState() => _CompanyWizardScreenState();
}

class _CompanyWizardScreenState extends State<CompanyWizardScreen> {
  static const TAG = 'CompanyWizardScreen';

  final Duration _durationPageView = Duration(milliseconds: 500);
  final Curve _curvePageView = Curves.easeInOut;

  CompaniesScreenLogic logic;
  Orgs company;

  final PageController _pageController = PageController(
    initialPage: 0,
    keepPage: false,
  );

  int _pageIndex = 0;
  String title = NavigationData.nav[0]['title'];

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    logic = CompaniesScreenLogic(setStateCallback: setStateCallback);
    logic.parseArguments(context);
    super.initState();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  setPageview(int index) {
    setState(() {
      _pageIndex = index;
    });
    _pageController.animateToPage(index,
        curve: _curvePageView, duration: _durationPageView);
  }

  void setStateCallback(Map<String, dynamic> newState) {
    setState(() {
      if (newState['curCompany'] != null) {
        company = newState['curCompany'];
        title = company.name;
      }
    });
    if (newState['setPageview'] != null) {
      setPageview(newState['setPageview']);
    }
  }

  @override
  Widget build(BuildContext context) {
    void _onPageChanged(int page) {
      setState(() {
        title = NavigationData.nav[page]['title'];
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: NeverScrollableScrollPhysics(),
          children: [
            TabCompanyView(
              pageController: _pageController,
              setStateCallback: setStateCallback,
              company: company,
            ),
            TabBranchesView(
              pageController: _pageController,
              setStateCallback: setStateCallback,
              company: company,
            ),
            TabPhonesView(
              pageController: _pageController,
              setStateCallback: setStateCallback,
              company: company,
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BORDER_RADIUS_32,
        child: SizedBox(
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _pageIndex,
            backgroundColor: kBackgroundLightColor,
            // Показывать подписи к вкладкам
            //showSelectedLabels: false,
            //showUnselectedLabels: false,
            elevation: 0,
            onTap: (index) {
              setPageview(index);
              setState(() => _pageIndex = index);
            },
            items: NavigationData.nav
                .map(
                  (navItem) => BottomNavigationBarItem(
                    icon: Icon(
                      navItem['icon'],
                      color: _pageIndex == navItem['index']
                          ? kPrimaryColor
                          : kUnseletedColor,
                    ),
                    tooltip: navItem['tooltip'],
                    label: navItem['label'],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class NavigationData {
  static List<dynamic> nav = [
    {
      'icon': Icons.info_outline,
      'index': 0,
      'label': 'Информация',
      'tooltip': 'Информация',
      'title': 'Информация',
    },
    {
      'icon': Icons.domain,
      'index': 1,
      'label': 'Адреса',
      'tooltip': 'Адреса',
      'title': 'Адреса',
    },
    {
      'icon': Icons.settings_phone_outlined,
      'index': 2,
      'label': 'Телефоны',
      'tooltip': 'Телефоны',
      'title': 'Телефоны',
    },
  ];
}
