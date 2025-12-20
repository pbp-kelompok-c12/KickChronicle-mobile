class UserProfile {
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? imageUrl; // Bisa null

  UserProfile({
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      imageUrl: json['image_url'], // Bisa null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}
