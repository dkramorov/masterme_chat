import 'package:flutter/material.dart';
import 'package:masterme_chat/screens/logic/call_logic.dart';

import 'action_button.dart';

List<Widget> buildNumPad(Function handleKeyPad) {
  return CallScreenLogic.numPadLabels
      .map(
        (row) => Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row
                .map(
                  (label) => ActionButton(
                    title: '${label.keys.first}',
                    //subTitle: '${label.values.first}',
                    onPressed: () => handleKeyPad(label.keys.first),
                    number: true,
                  ),
                )
                .toList(),
          ),
        ),
      )
      .toList();
}

List<Widget> buildPhoneUnregisterError() {
  return [
    Container(
      padding: EdgeInsets.all(20.0),
      child: Text(
        'Сначала зарегистрируйтесь, чтобы звонить бесплатно',
        style: TextStyle(
          fontSize: 24.0,
        ),
      ),
    ),
  ];
}
