import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';

String? _deviceID;
String? _deviceName;

Future<void> initializeDevice() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  _deviceID = prefs.getString("deviceID");

  if (_deviceID == null) {
    _deviceID = const Uuid().v4();
    prefs.setString("deviceID", _deviceID!);
  }
  print("DEVICEID = $_deviceID");

  final deviceInfoPlugin = DeviceInfoPlugin();
  final deviceInfo = await deviceInfoPlugin.deviceInfo;
  final allInfo = deviceInfo.data;

  allInfo.forEach((key, value) {
    print("$key = $value");
  });

  _deviceName = allInfo["model"];
}

String deviceID() {
  return _deviceID!;
}

String deviceName() {
  return _deviceName ?? "Unknown";
}
