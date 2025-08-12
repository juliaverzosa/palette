import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditPostForm extends StatefulWidget {
  final String postId;

  const EditPostForm({Key? key, required this.postId}) : super(key: key);

  @override
  _EditPostFormState createState() => _EditPostFormState();
}

class _EditPostFormState extends State<EditPostForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _captionController;
  late TextEditingController _categoryController;
  late TextEditingController _tagsController;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _captionController = TextEditingController();
    _categoryController = TextEditingController();
    _tagsController = TextEditingController();

    _fetchPostData(); // Fetch the post data when the form initializes
  }

  Future<void> _fetchPostData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

      if (doc.exists) {
        setState(() {
          _titleController.text = doc['title'] ?? '';
          _captionController.text = doc['caption'] ?? '';
          _categoryController.text = doc['category'] ?? '';
          _tagsController.text = (doc['tags'] as List<dynamic>)
              .map((tag) => tag.toString())
              .join(', ');
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post not found')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching post: $e')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _updatePost() async {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedTags = _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .update({
          'title': _titleController.text.trim(),
          'caption': _captionController.text.trim(),
          'category': _categoryController.text.trim(),
          'tags': updatedTags,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post updated successfully!')),
        );

        Navigator.pop(context); // Navigate back after updating
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _updatePost,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _captionController,
                      decoration: const InputDecoration(labelText: 'Caption'),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a caption';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags',
                        hintText: 'Enter tags separated by commas',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}
