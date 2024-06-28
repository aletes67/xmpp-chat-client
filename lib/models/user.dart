class User {
  String username;
  String password;
  String displayName;
  String? photoUrl;
  String groupName;

  User({
    required this.username,
    required this.password,
    required this.displayName,
    required this.groupName,
    this.photoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      password: '', // la password non viene salvata nel profilo
      displayName: json['properties']['displayName'] ?? '',
      groupName: json['groupName'],
      photoUrl: json['properties']['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'properties': {
        'displayName': displayName,
        'photoUrl': photoUrl,
      },
      'groupName': groupName,
    };
  }
}
