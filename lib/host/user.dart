class User {
  const User(this.name, {this.onlineData});
  final String name;
  final OnlineData? onlineData;
}

class OnlineData {
  const OnlineData(this.userID);
  final String userID;
}
