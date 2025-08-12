import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditPost extends StatefulWidget {
  final String postId;

  const EditPost({
    required this.postId,
    Key? key,
  }) : super(key: key);

  @override
  _EditPostState createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _captionController;
  late TextEditingController _tagsController;
  late String _category;

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

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPostData();
  }

  Future<void> _fetchPostData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Handle user not logged in case
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to edit a post.')),
        );
        return;
      }

      final postDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('posts')
          .doc(widget.postId)
          .get();

      if (postDoc.exists) {
        setState(() {
          _titleController = TextEditingController(text: postDoc['title']);
          _captionController = TextEditingController(text: postDoc['caption']);
          _tagsController = TextEditingController(text: postDoc['tags']);
          _category = postDoc['category'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching post data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load post data.')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updating post...')),
      );

      try {
        // Get the current user ID
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to edit a post.')),
          );
          return;
        }

        // Prepare the updated post object
        final post = {
          'title': _titleController.text.trim(),
          'caption': _captionController.text.trim(),
          'tags': _tagsController.text.trim(),
          'category': _category,
          'timestamp': FieldValue.serverTimestamp(),
        };

        // Update the post in the Firestore collection (using postId)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('posts')
            .doc(widget.postId) // Update the existing post
            .update(post);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post updated successfully!')),
        );

        // Navigate back to the previous screen
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error updating post: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update post.')),
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
          'Edit Post',
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
        child: _isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Write a Title',
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Please enter a title' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _captionController,
                        decoration: const InputDecoration(
                          labelText: 'Write a Caption',
                          border: UnderlineInputBorder(),
                        ),
                        maxLines: 3,
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
                                                Navigator.pop(context, _categories[index]);
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
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags',
                          border: UnderlineInputBorder(),
                        ),
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
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
