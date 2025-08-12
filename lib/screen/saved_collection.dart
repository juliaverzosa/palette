import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class SavedCollectionScreen extends StatefulWidget {
  @override
  _SavedCollectionScreenState createState() => _SavedCollectionScreenState();
}

class _SavedCollectionScreenState extends State<SavedCollectionScreen> {
  List<QueryDocumentSnapshot> savedPosts = [];

  @override
  void initState() {
    super.initState();
    _fetchSavedPosts(); // Fetch saved posts
  }

  // Fetch saved posts for the current user
  Future<void> _fetchSavedPosts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        // Fetch the saved posts for the current user from the "saved" collection
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('saved') // Collection where the posts are saved
            .orderBy('timestamp', descending: true)
            .get();

        setState(() {
          savedPosts = querySnapshot.docs; // Store fetched posts
        });
      } catch (e) {
        print("Error fetching saved posts: $e");
      }
    }
  }

  // Build the Masonry Grid view for the saved collection
  Widget _buildSavedPostsGallery() {
    return MasonryGridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Two columns in the grid
      ),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      itemCount: savedPosts.length, // Use the length of saved posts fetched
      itemBuilder: (context, index) {
        final post = savedPosts[index].data() as Map<String, dynamic>;
        final postImageUrl = post['imageUrl'] ?? '';  // Assuming posts have an imageUrl

        return Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 237, 237, 237),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: postImageUrl.isNotEmpty
                ? Image.network(
                    postImageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,  // You can vary the height as needed
                  )
                : const Placeholder(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Saved Posts'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            // Saved Collection Tab
            Expanded(child: _buildSavedPostsGallery()),  // Display saved posts in Masonry grid
          ],
        ),
      ),
    );
  }
}
