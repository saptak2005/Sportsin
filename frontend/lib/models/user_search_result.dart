class UserSearchResult {
  final String id;
  final String name;
  final String username;

  UserSearchResult({
    required this.id,
    required this.name,
    required this.username,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
    );
  }
}
