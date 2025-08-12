import 'package:flutter/material.dart';

class ProfileModel extends ChangeNotifier {
  String? _displayName;
  String? _username;
  String? _profileImageUrl;
  String? _about;
  String? _location;

  String? get displayName => _displayName;
  String? get username => _username;
  String? get profileImageUrl => _profileImageUrl;
  String? get about => _about;
  String? get location => _location;

  void updateProfile({
    required String displayName,
    required String about,
    required String location,
    required String profileImageUrl,
  }) {
    _displayName = displayName;
    _about = about;
    _location = location;
    _profileImageUrl = profileImageUrl;
    notifyListeners();
  }

  void clearProfile() {
    _displayName = null;
    _username = null;
    _profileImageUrl = null;
    _about = null;
    _location = null;
    notifyListeners();
  }
}
