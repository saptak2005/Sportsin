class UserSearchResult {
  final String id;
  final String name;
  final String username;
  final String? profilePicture;

  UserSearchResult({
    required this.id,
    required this.name,
    required this.username,
    this.profilePicture,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      profilePicture: json['image'] as String?,
    );
  }
}
