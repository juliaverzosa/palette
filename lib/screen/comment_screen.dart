import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:project_pallete/screen/profile_screen.dart';

class CommentScreen extends StatefulWidget {
  final String postImage;
  final String postTitle;

  const CommentScreen({super.key, required this.postImage, required this.postTitle});

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  // List of comments
  List<String> comments = [];

  // Text controller for the comment input
  TextEditingController _commentController = TextEditingController();

  // Method to add comment
  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      setState(() {
        comments.add(_commentController.text);
        _commentController.clear(); // Clear input field
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white
      appBar: AppBar(
        automaticallyImplyLeading: true, // Show the back button
        title: Text(
                  '@username', // Username displayed in the center
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.0,
        shadowColor: Colors.transparent,
        actions: [
                    GestureDetector(
            onTap: () {
              // Navigate to profile screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: const CircleAvatar(
              backgroundImage: AssetImage('assets/profile.png'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Post Image and Actions (like, comment, share)
          Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Information and Post Image
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('assets/profile.png'),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'username',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Post Image
                Container(
                  height: 350,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[300],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      widget.postImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Action Buttons (Like, Comment, Share)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.solidHeart),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.comment),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.retweet),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.bookmark),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Comment List
          Expanded(
            child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(comments[index]),
                );
              },
            ),
          ),
          // Comment Input Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Write a comment...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.paperPlane),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
