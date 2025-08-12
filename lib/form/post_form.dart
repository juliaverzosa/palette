import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class NewPostForm extends StatefulWidget {
  const NewPostForm({super.key});

  @override
  _NewPostFormState createState() => _NewPostFormState();
}

class _NewPostFormState extends State<NewPostForm> {
  final _formKey = GlobalKey<FormState>();

  String? _title;
  String? _caption;
  String? _tags;
  String? _category;
  File? _selectedImage;

  final List<String> _categories = [
    'Character Art',
    'Fanart',
    'Portrait',
    'Illustration',
    'Landscape',
    'Sketch',
    'Crafts',
    'Photography',
    'Comics',
    '3D',
  ];

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<String?> _uploadImageToSupabase(File image) async {
    try {
      final fileName = 'post_images/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Read the file as bytes
      final fileBytes = await image.readAsBytes();

      // Upload to Supabase storage
      await Supabase.instance.client.storage
          .from('images') // Ensure this matches your bucket name
          .uploadBinary(fileName, fileBytes);

      // Retrieve the public URL
      final publicUrl = Supabase.instance.client.storage
          .from('images')
          .getPublicUrl(fileName);

      debugPrint('Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error during image upload: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading...')),
      );

      try {
        String? imageUrl;

        // Upload image to Supabase if selected
        if (_selectedImage != null) {
          imageUrl = await _uploadImageToSupabase(_selectedImage!);
          if (imageUrl == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image.')),
            );
            return;
          }
        }

        // Get the current user ID
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to post.')),
          );
          return;
        }

 // Get the current user's username (you can store it in Firestore under user profile)
      // Assuming you have the username saved in Firestore or from user profile data
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String? userName = userDoc['username'] ?? 'Anonymous'; // Default to 'Anonymous' if no username is found

        // Create a new post object
        final post = {
          'title': _title,
          'caption': _caption,
          'tags': _tags,
          'category': _category,
          'imageUrl': imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'postUsername': userName,
        };

        // Add post to the user's sub-collection in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('posts')
            .add(post);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post uploaded successfully!')),
        );

        // Navigate back to home screen
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error uploading post: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload post.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'New Post',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _selectedImage == null
                        ? const Icon(Icons.add_photo_alternate,
                            size: 50, color: Colors.grey)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Write a Title',
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter a title' : null,
                  onSaved: (value) => _title = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Write a Caption',
                    border: UnderlineInputBorder(),
                  ),
                  maxLines: 3,
                  onSaved: (value) => _caption = value,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final selectedCategory = await showModalBottomSheet<String>(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (BuildContext context) {
                        return DraggableScrollableSheet(
                          expand: false,
                          initialChildSize: 0.4,
                          minChildSize: 0.2,
                          maxChildSize: 0.8,
                          builder: (context, scrollController) {
                            return Column(
                              children: [
                                Container(
                                  width: 50,
                                  height: 5,
                                  margin: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[400],
                                    borderRadius: BorderRadius.circular(2.5),
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    controller: scrollController,
                                    itemCount: _categories.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        title: Text(_categories[index]),
                                        onTap: () {
                                          Navigator.pop(
                                              context, _categories[index]);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                    if (selectedCategory != null) {
                      setState(() {
                        _category = selectedCategory;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _category ?? 'Select a Category',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    border: UnderlineInputBorder(),
                  ),
                  onSaved: (value) => _tags = value,
                ),
                const SizedBox(height: 80),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    foregroundColor: Colors.white,
                    backgroundColor: const Color.fromARGB(255, 232, 114, 134),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Upload'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

