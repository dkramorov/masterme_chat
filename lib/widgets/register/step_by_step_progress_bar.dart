import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';

class StepByStepProgressBar extends StatelessWidget {
  StepByStepProgressBar({int totalStep, int currentStep})
      : assert(currentStep <= totalStep),
        assert(currentStep > 0),
        assert(totalStep > 0),
        _currentStep = currentStep,
        _totalStep = totalStep;

  int _totalStep;
  int _currentStep;

  static const double _progressHeight = 8;

  @override
  Widget build(BuildContext context) {
    final _progressWidth = MediaQuery.of(context).size.width / 3;

    return Stack(
      children: [
        Container(
            width: _progressWidth,
            height: _progressHeight,
            decoration: BoxDecoration(
                color: kSizeBoxLightColor,
                borderRadius: BorderRadius.circular(4))),
        Container(
          height: _progressHeight,
          width: _progressWidth * _currentStep / _totalStep,
          decoration: BoxDecoration(
              color: kPrimaryColor, borderRadius: BorderRadius.circular(4)),
        )
      ],
    );
  }
}
