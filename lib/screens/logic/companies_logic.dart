import 'dart:async';

import 'package:masterme_chat/screens/logic/default_logic.dart';

class CompaniesScreenLogic extends AbstractScreenLogic {
  static const TAG = 'CompaniesScreenLogic';

  CompaniesScreenLogic({Function setStateCallback}) {
    this.setStateCallback = setStateCallback;
    checkState();

    this.screenTimer = Timer.periodic(Duration(seconds: 2), (Timer t) async {
      checkState();
      //Log.d(TAG, '${t.tick}');
    });
  }

  @override
  String getTAG() {
    return TAG;
  }

}
