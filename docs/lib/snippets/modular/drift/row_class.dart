// #docregion user
class User {
  final int id;
  final String name;

  User(this.id, this.name);
}
// #enddocregion user

// #docregion userwithfriends
class UserWithFriends {
  final User user;
  final List<User> friends;

  UserWithFriends(this.user, {this.friends = const []});
}
// #enddocregion userwithfriends
