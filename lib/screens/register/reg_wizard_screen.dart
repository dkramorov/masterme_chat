import 'package:flutter/material.dart';
import 'package:masterme_chat/screens/register/step_confirm_phone_view.dart';
import 'package:masterme_chat/screens/register/step_register_phone_view.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class RootWizardScreen extends StatefulWidget {
  static const String id = '/reg_wizard_screen/';
  @override
  _RootWizardScreenState createState() => _RootWizardScreenState();
}

class _RootWizardScreenState extends State<RootWizardScreen> {
  bool loading = false;
  Map<String, dynamic> userData = {};

  final PageController _pageController = PageController(
    initialPage: 0,
    keepPage: false,
  );

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  void setStateCallback(Map<String, dynamic> newState) {
    if (newState['loading'] != null && newState['loading'] != loading) {
      setState(() {
        loading = newState['loading'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget _pageViewBuilder(_, index) {
      switch (index) {
        case 1:
          return StepConfirmPhoneView(
            pageController: _pageController,
            setStateCallback: setStateCallback,
            userData: userData,
          );
          break;
        default:
          return StepRegisterPhoneView(
            pageController: _pageController,
            setStateCallback: setStateCallback,
            userData: userData,
          );
          break;
      }
    }

    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: loading,
        child: SafeArea(
          child: PageView.builder(
            itemCount: 2,
            itemBuilder: _pageViewBuilder,
            controller: _pageController,
          ),
        ),
      ),
    );
  }
}
