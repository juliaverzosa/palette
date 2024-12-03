import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class NewPostForm extends StatefulWidget {
  const NewPostForm({super.key});

  @override
  _NewPostFormState createState() => _NewPostFormState();
}

class _NewPostFormState extends State<NewPostForm> {
  // Key to manage form state
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String? _title;
  String? _caption;
  String? _tags;
  String? _category;
  File? _selectedImage; // Updated to use File instead of String for image

  // List of predefined categories
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
    '3D'
  ];

  // Function to pick an image
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path); // Save the picked image
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // Function to handle form submission
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Perform your submission logic here
      debugPrint('Form Submitted: Title: $_title, Category: $_category');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'New Post',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
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
                // Image Picker
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
                        ? const Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey)
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

                // Title Input Field
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Write a Title',
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey
                      ),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                  onSaved: (value) => _title = value,
                ),

                const SizedBox(height: 16),

                // Caption Input Field
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Write a Caption',
                    border: UnderlineInputBorder(),
                  ),
                  maxLines: 3,
                  onSaved: (value) => _caption = value,
                ),

                const SizedBox(height: 16),

                // Category Selection
                GestureDetector(
                  onTap: () async {
                    final selectedCategory = await showModalBottomSheet<String>(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top:Radius.circular(20)
                        ),
                      ),
                                         builder: (BuildContext context) {
                        return DraggableScrollableSheet(
                          expand: false,
                          initialChildSize: 0.4, // Initial height of bottom sheet
                          minChildSize: 0.2, 
                          maxChildSize: 0.8, 
                          builder: (context, scrollController) {
                            return Column(
                              children: [
                                Container(
                                  // Drag indicator
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
                                    itemCount: _categories.length, // Number of categories
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        title: Text(_categories[index]), // Category name
                                        onTap: () {
                                          Navigator.pop(context, _categories[index]); // Return selected category
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
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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

                // Tags Input Field
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    border: UnderlineInputBorder(),
                  ),
                  onSaved: (value) => _tags = value,
                ),

                const SizedBox(height: 80),

                // Upload Button
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
