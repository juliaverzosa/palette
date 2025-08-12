import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String displayName;
  final String profilePhotoUrl;
  final String about;
  final String location;
  final Function(String, String, String, String) onProfileUpdate; // Callback function


  const EditProfileScreen({
    super.key,
  required this.userId,
    required this.userName,
    required this.displayName,
    required this.profilePhotoUrl,
    required this.about,
    required this.location,
    required this.onProfileUpdate
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  XFile? _selectedCoverImage;

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _isLoading = false;

  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Pick an image from the gallery
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _pickCoverImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedCoverImage = image;
    });
  }

  // Upload image to Supabase and return the public URL
  Future<String> _uploadImage(File image, String path) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
      final response = await _supabaseClient.storage
          .from('images') // Replace with your Supabase storage bucket name
          .upload('$path/$fileName', image);

      if (response.isEmpty) {
        throw Exception('Failed to upload image');
      }

      // Generate public URL
      final publicUrl = _supabaseClient.storage.from('images').getPublicUrl('$path/$fileName');
      return publicUrl;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  // Save user details to Firestore
  Future<void> _saveDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if userId is empty
      if (widget.userId.isEmpty) {
        throw Exception('User ID is empty');
      }

      print('Saving profile for user: ${widget.userId}'); // Debugging

      final userDoc = FirebaseFirestore.instance.collection('users').doc(widget.userId);

      String? profilePhotoUrl;
      String? coverImageUrl;

      // Check if any required fields are empty
      if (_displayNameController.text.isEmpty || _aboutController.text.isEmpty || _locationController.text.isEmpty) {
        throw Exception('Please fill in all fields.');
      }

      // Upload profile photo if selected
      if (_selectedImage != null) {
        profilePhotoUrl = await _uploadImage(File(_selectedImage!.path), 'profile-images');
        print('Profile image uploaded: $profilePhotoUrl');
      }

      // Upload cover photo if selected
      if (_selectedCoverImage != null) {
        coverImageUrl = await _uploadImage(File(_selectedCoverImage!.path), 'cover-images');
        print('Cover image uploaded: $coverImageUrl');
      }

      // Prepare data to update
      final Map<String, dynamic> updateData = {
        'displayName': _displayNameController.text.trim(),
        'about': _aboutController.text.trim(),
        'location': _locationController.text.trim(),
      };

      // Add image URLs if available
      if (profilePhotoUrl != null) {
        updateData['profilePhotoUrl'] = profilePhotoUrl;
      }

      if (coverImageUrl != null) {
        updateData['coverPhotoUrl'] = coverImageUrl;
      }

      // Ensure the "profile_details" document exists or create it
      final profileDetailsRef = userDoc.collection('profile_details').doc('details');
      await profileDetailsRef.set(updateData, SetOptions(merge: true));

      // After saving, go back to the profile screen with the updated data
      Navigator.pop(context, updateData);  // Passing updated data back to profile screen

      // Call the onProfileUpdate callback if needed
    widget.onProfileUpdate(
      _displayNameController.text.trim(),
      _aboutController.text.trim(),
      _locationController.text.trim(),
      profilePhotoUrl ?? widget.profilePhotoUrl,
    );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      // Log error and show feedback
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch user details to display in the form
  Future<void> _fetchUserDetails() async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(widget.userId);
      final userSnapshot = await userDoc.get();

      if (userSnapshot.exists) {
        final userData = userSnapshot.data();
        if (userData != null) {
          // Populate the text fields with user data
          setState(() {
            _displayNameController.text = userData['displayName'] ?? '';
            _aboutController.text = userData['about'] ?? '';
            _locationController.text = userData['location'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserDetails(); // Fetch user details when the screen is loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white, // Set the background color of the Scaffold to white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(  // Make the entire body scrollable
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // GestureDetector(
              //   onTap: _pickCoverImage,
              //   child: Container(
              //     height: 150,
              //     width: double.infinity,
              //     decoration: BoxDecoration(
              //       borderRadius: BorderRadius.circular(15),
              //       color: Colors.grey.shade300,
              //       image: _selectedCoverImage != null
              //           ? DecorationImage(
              //               image: FileImage(File(_selectedCoverImage!.path)),
              //               fit: BoxFit.cover,
              //             )
              //           : null,
              //     ),
              //     child: _selectedCoverImage == null
              //         ? const Center(
              //             child: Text(
              //               'Tap to upload cover photo',
              //               style: TextStyle(
              //                 color: Colors.black54,
              //                 fontSize: 16,
              //               ),
              //             ),
              //           )
              //         : null,
              //   ),
              // ),
              const SizedBox(height: 20),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _selectedImage != null
                          ? FileImage(File(_selectedImage!.path))
                          : NetworkImage(widget.profilePhotoUrl),
                    ),
                  ),
                  const SizedBox(width: 20),
                   Text(
                    '@${widget.userName}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: _aboutController,
                decoration: InputDecoration(
                  labelText: 'About',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 160),  // Added some spacing before the button
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 232, 114, 134),
                    minimumSize: const Size(350, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
