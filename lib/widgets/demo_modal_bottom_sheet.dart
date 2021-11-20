import 'package:flutter/material.dart';
import 'package:masterme_chat/widgets/rounded_button_widget.dart';
import 'package:masterme_chat/constants.dart';

class BottomModalochka extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
          color: Color(0xff737373),
          child: Container(
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                )),
            child: Column(
              children: [
                Text('Добавить контакт'),
                TextField(
                  autofocus: true,
                  onChanged: (value) {},
                ),
                RoundedButtonWidget(
                  text: Text(
                    'Добавить',
                    style: TextStyle(color: Colors.white),
                  ),
                  color: kPrimaryColor,
                  onPressed: () {},
                ),
              ],
            ),
          )),
    );
  }
}
