class User {
  const User(this.name, {this.onlineData});
  final String name;
  final OnlineData? onlineData;

  @override
  String toString() {
    if (onlineData != null) {
      return "$name@${onlineData!.deviceName}";
    }
    return name;
  }
}

class OnlineData {
  const OnlineData(this.userID, this.deviceName, this.clientID);
  final String userID;
  final String deviceName;
  final int clientID;
}
