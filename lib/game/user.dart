import 'package:steven/device.dart';

class User {
  const User(this.name, this.device);
  final String name;
  final String device;

  @override
  String toString() {
    if (device != deviceID()) {
      return "$name*";
    }
    return name;
  }
}
