import '../../elements/nonzas/Nonza.dart';

class Feature extends Nonza {

  Feature() {
    name = 'feature';
  }

  String get xmppVar {
    return getAttribute('var')?.value;
  }

  String toString() {
    return '$name $xmppVar';
  }

}
