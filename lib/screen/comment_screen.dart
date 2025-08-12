import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:project_pallete/form/edit_post.dart';
import 'package:project_pallete/screen/profile_screen.dart';
import 'package:timeago/timeago.dart' as timeago;



class CommentScreen extends StatefulWidget {
  final String postImage;
  final String postTitle;
  final String postCaption;
  final String postCategory;
  final String postTags;
  final String postDate;
  final String postId;
  final String postUsername;
  final String username; 
  

  const CommentScreen({
    super.key,
    required this.postImage,
    required this.postTitle,
    required this.postCaption,
    required this.postCategory,
    required this.postTags,
    required this.postDate,
    required this.postId,
    required this.postUsername,
    required this.username,
// Add this to the constructor
  });

  @override
  _CommentScreenState createState() => _CommentScreenState();
}
class _CommentScreenState extends State<CommentScreen> {
  // List of comments
  List<Map<String, dynamic>> comments = [];

  // Text controller for the comment input
  final TextEditingController _commentController = TextEditingController();
 bool isLiked = false;  // Track like state


  @override
  void initState() {
    super.initState();
    _fetchComments();
     _checkLikeStatus();  // Check the like status when the screen is loaded
  }

 Future<void> _checkLikeStatus() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    final postSnapshot = await postRef.get();
    
    if (postSnapshot.exists) {
      final likes = postSnapshot['likes'] ?? [];
      setState(() {
        isLiked = likes.contains(userId);  // Check if the user has already liked the post
      });
    }
  }


Future<void> _savePostToCollection(String postId, String postTitle, String postImage, String postCaption) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Save the post details to the user's savedPosts collection
      await FirebaseFirestore.instance
          .collection('users') // Access the users collection
          .doc(user.uid) // Access the current user by their UID
          .collection('savedPosts') // The subcollection where saved posts are stored
          .doc(postId) // Use the postId as the document ID
          .set({
        'postId': postId,
        'postTitle': postTitle,
        'postImage': postImage,
        'postCaption': postCaption,
        'savedAt': FieldValue.serverTimestamp(), // Timestamp of when the post was saved
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post saved to your collection!')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save post: $e')),
    );
  }
}

Future<void> _navigateToProfileScreen(String postUsername) async {
  try {
    // Fetch the userId corresponding to the postUsername
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: postUsername)
        .limit(1)
        .get();

    if (userDoc.docs.isNotEmpty) {
      // Extract userId from the query result
      final userId = userDoc.docs.first.id; // Assuming the document ID is the userId

      // Navigate to the ProfileScreen with both username and userId
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            username: postUsername,
            userId: userId,
          ),
        ),
      );
    } else {
      // Handle case where no user was found with that username
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user found for this username.')),
      );
    }
  } catch (e) {
    // Handle any errors that occur during the fetch
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error fetching user ID: $e')),
    );
  }
}


Future<String> _fetchProfilePhotoUrl(String username) async {
  
  try {
    // Fetch the profile photo URL from the user's profile details
    final profileDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc('username') // Access the user's document
        .collection('profile_details') // Assuming there's a profileDetails sub-collection
        .doc('details') // Assuming 'profile' is the document containing the photo
        .get();

    // Return the profile image URL if it exists, otherwise return an empty string or a default URL
    return profileDoc.exists ? profileDoc['profilePhotoUrl'] ?? '' : '';
  } catch (e) {
    print('Error fetching profile photo: $e');
    return ''; // Return an empty string in case of error
  }
}


Future<void> _fetchComments() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('posts') // Access posts collection
        .doc(widget.postId) // Access specific post
        .collection('comments') // Access comments for the post
        .orderBy('timestamp', descending: true) // Order by timestamp
        .get();

   final fetchedComments = await Future.wait(snapshot.docs.map((doc) async {
      // Fetch the profile image URL using the new function
      String profilePhotoUrl = await _fetchProfilePhotoUrl(doc['username']);


      return {
        'username': doc['username'],
        'comment': doc['comment'],
        'timestamp': (doc['timestamp'] as Timestamp).toDate(),
        'profilePhotoUrl': profilePhotoUrl, // Add profile image URL to the comment data
      };
    }).toList());

    setState(() {
      comments = fetchedComments;
    });
  } catch (e) {
    print('Error fetching comments: $e');
  }
}


Future<void> _addComment(String postId, String username) async {
  final newComment = _commentController.text.trim();
  if (newComment.isNotEmpty) {
    try {
      // Add comment to Firestore
      await FirebaseFirestore.instance
          .collection('posts') // Access posts collection
          .doc(postId) // Access specific post
          .collection('comments') // Access comments for the post
          .add({
        'username': username,
        'comment': newComment,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update UI
      setState(() {
        comments.insert(0, {
          'username': username,
          'comment': newComment,
          'timestamp': DateTime.now(),
        });
      });

      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $e')),
      );
    }
  }
}

  // Function to show post options including delete confirmation
  void _showPostOptions() {
    showModalBottomSheet(
       context: context,
       isScrollControlled: true, 
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20))
    ),
      builder: (context) {
        bool isOwnPost = widget.username == widget.postUsername; // Check if post is by the current user
         return ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20), // Rounded top-left corner
          topRight: Radius.circular(20), // Rounded top-right corner
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          color: Colors.white, // Set background color to white
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOwnPost) ...[
                _buildOption(
                   icon: FontAwesomeIcons.pen,
                  title: "Edit Post",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPost(
                          // postTitle: post['title'] ?? 'No Title',
                          // postCaption: post['caption'] ?? 'No Caption',
                          // postCategory: post['category'] ?? 'No Category',
                          // postTags: post['tags'] ?? [],
                          // postDate: post['postDate'],
                          postId: widget.postId,
                          //postUsername: post['postUsername'],
                        ),
                      ),
                    );
                  },
                ),
                 _buildOption(
                  icon: FontAwesomeIcons.bookmark,
                  title: "Save to Collection",
                  onTap: () {
                    Navigator.pop(context);
                    // Add your save to collection logic here
                    _savePostToCollection(widget.postId, widget.postTitle, widget.postImage, widget.postCaption);
                  },
                ),
                _buildOption(
                  icon: FontAwesomeIcons.trashCan,
                  title: "Delete",
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet
                    // Show delete confirmation dialog
                    _showDeleteConfirmationDialog(widget.postId);
                  },
                  isDeleteOption: true, // Custom styling for delete option
                ),
              ] else ...[
                
_buildOption(
                  icon: FontAwesomeIcons.bookmark,
                  title: "Save to Collection",
                  onTap: () {
                    Navigator.pop(context);
                    // Save the post to the current user's collection
                    _savePostToCollection(widget.postId, widget.postTitle, widget.postImage, widget.postCaption);
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
  // Function to create options with custom styling
  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDeleteOption = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 5, bottom: 5),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        decoration: BoxDecoration(
          color: Colors.grey[200], // Light gray background for options
          borderRadius: BorderRadius.circular(25), // Rounded corners
        ),
        child: Row(
          children: [
            Icon(icon, color: isDeleteOption ? const Color.fromARGB(255, 255, 115, 105) : const Color.fromARGB(255, 82, 82, 82)),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 14, // Larger text size
                fontWeight: FontWeight.bold,
                color: isDeleteOption ? const Color.fromARGB(255, 255, 115, 105) : const Color.fromARGB(255, 82, 82, 82)),
            ),
          ],
        ),
      ),
    );
  }



  // Function to show the delete confirmation dialog
  void _showDeleteConfirmationDialog(String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you sure?"),
          content: const Text("Do you really want to delete this post? This action cannot be undone."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deletePost(postId); // Proceed with deletion
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

// Function to show the delete comment confirmation dialog
void _showDeleteCommentDialog(String username, String commentText) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Are you sure?"),
        content: Text("Do you want to delete this comment by $username? This action cannot be undone."),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _deleteComment(username, commentText); // Proceed with comment deletion
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text("Delete"),
          ),
        ],
      );
    },
  );
}

// Function to delete a comment
Future<void> _deleteComment(String username, String commentText) async {
  try {
    // Find the comment in Firestore based on the username and comment text
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .where('username', isEqualTo: username)
        .where('comment', isEqualTo: commentText)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Get the comment document reference and delete it
      await snapshot.docs.first.reference.delete();

      // Update the UI to reflect the deletion
      setState(() {
        comments.removeWhere((comment) => comment['username'] == username && comment['comment'] == commentText);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment deleted successfully!')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete comment: $e')),
    );
  }
}

  // Function to delete the post
  Future<void> _deletePost(String postId) async {
    try {
      // Assuming you have Firebase or some other backend service
      // Here, we would delete the post using Firestore or a relevant service

      // Example Firebase deletion logic (Firebase Firestore is used here):
      // final user = FirebaseAuth.instance.currentUser;
      // if (user == null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('You must be logged in to delete a post.')),
      //   );
      //   return;
      // }

      // Delete from Firestore
      // await FirebaseFirestore.instance.collection('users')
      //     .doc(user.uid)
      //     .collection('posts')
      //     .doc(postId)
      //     .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully!')),
      );

      // Optionally, you can remove the post from the app's UI here
    } catch (e) {
      debugPrint('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete the post.')),
      );
    }
  }

 Future<String> _getProfilePhotoUrl(String userId) async {
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  return userDoc.data()?['profilePhotoUrl'] ?? ''; // Replace 'profileImage' with your field name
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white
      appBar: AppBar(
        automaticallyImplyLeading: true, // Show the back button
        title: Text(
          '@${widget.postUsername}', // Username displayed in the center
          style: const TextStyle(
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
 FutureBuilder<String>(
  future: _getProfilePhotoUrl(widget.postUsername), // Fetch the profile image URL
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.only(right: 10.0),
        child: CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, color: Colors.white), // Placeholder icon
        ),
      );
    }

    if (snapshot.hasError || !snapshot.hasData) {
      return const Padding(
        padding: EdgeInsets.only(right: 10.0),
        child: CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.error, color: Colors.white), // Error icon
        ),
      );
    }

    // Function to fetch the userId from Firestore based on postUsername
    Future<String?> _fetchUserId(String postUsername) async {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: postUsername)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs.first.id; // Extract userId from document
        } else {
          return null; // If no user is found, return null
        }
      } catch (e) {
        print('Error fetching userId: $e');
        return null; // Return null in case of an error
      }
    }

    // Make the CircleAvatar clickable
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: GestureDetector(
        onTap: () async {
          // Fetch the userId based on postUsername
          String? userId = await _fetchUserId(widget.postUsername);

          if (userId != null) {
            // Navigate to the ProfileScreen with both username and userId
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  username: widget.postUsername,
                  userId: userId,
                ),
              ),
            );
          } else {
            // Handle case if userId is not found (e.g., show an error message)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User not found')),
            );
          }
        },
        child: snapshot.data!.isNotEmpty
            ? CircleAvatar(
                backgroundImage: NetworkImage(snapshot.data!), // Profile image from snapshot
              )
            : const CircleAvatar(
                // Fallback profile image if data is empty or null
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
      ),
    );
  },
),

],

      
    ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Information and Post Image
             
                    const SizedBox(height: 10),
                    // Post Image
                    Container(
                  
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[300],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          widget.postImage,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Action Buttons (Like, Comment, Share)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
 IconButton(
            icon: FaIcon(
              isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
              color: isLiked ? Colors.pink : const Color.fromARGB(255, 68, 68, 68),
            ),
            onPressed: () async {
              setState(() {
                isLiked = !isLiked;
              });

              final userId = FirebaseAuth.instance.currentUser!.uid;
              final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

              if (isLiked) {
                await postRef.update({
                  'likes': FieldValue.arrayUnion([userId]),
                });
              } else {
                await postRef.update({
                  'likes': FieldValue.arrayRemove([userId]),
                });
              }
            },
          ),

      
                            IconButton(
                              icon: const FaIcon(FontAwesomeIcons.retweet),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.ellipsis),
                          onPressed: _showPostOptions,  // Call the method to show the modal bottom sheet
),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Post Details with padding
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.postTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.postCaption,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Category: ${widget.postCategory}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "#${widget.postTags}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "${widget.postDate}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    // Show placeholder image when comments are empty
if (comments.isEmpty)
  Column(
    children: [
      const SizedBox(height: 20), // Spacing
      Center(
        child: Image.asset(
          'assets/no_comments.png', // Path to the image in assets
          height: 100, // Adjust size as needed
          width: 100,
          fit: BoxFit.contain,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        "There are no comments here",
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  )
else

                  ListView.builder(
                    
                    
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: comments.length,
  itemBuilder: (context, index) {
    final comment = comments[index];
    final timeAgo = timeago.format(comment['timestamp']); // Format the timestamp
    final isOwner = widget.username == comment['username']; // Check if the current user owns the comment
    final isPostOwner = widget.username == widget.postUsername; // Check if the current user is the post owner


return Padding(
  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Profile image
 comments[index]['profilePhotoUrl'] != null && comments[index]['profilePhotoUrl'].isNotEmpty
          ? CircleAvatar(
              //radius: 50, // Larger profile picture
              backgroundImage: NetworkImage(comments[index]['profilePhotoUrl']), // Load from network
            )
          : const CircleAvatar(
              //radius: 50, // Fallback profile picture size
              //backgroundImage: AssetImage('assets/profile.png'), // Fallback image
            ),
      const SizedBox(width: 8), // Add spacing between profile image and text

          // Comment details on the left
          Expanded(
                    child: GestureDetector(
          // onLongPress: () {
          //   // Trigger the delete confirmation dialog on long press
          //   if (isOwner || isPostOwner) {
          //     _showDeleteCommentDialog(comment['username'], comment['comment']);
          //   }
          // },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment['username'], // Display the comment owner's username
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comment['comment'], // Display the comment text
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  timeAgo, // Optional: Display the timestamp
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    
          // Add ellipsis icon if the user can delete the comment
if (isOwner || isPostOwner)
  Padding(
    padding: const EdgeInsets.only(left: 8.0), // Adjust the padding to move it more to the right
    child: IconButton(
      icon: const Icon(Icons.more_vert),
      iconSize: 20.0, // Make the icon smaller by setting the iconSize
      onPressed: () {
        // Show delete confirmation dialog
        _showDeleteCommentDialog(comment['username'], comment['comment']);
      },
    ),
  ),
        ],
      ),
    );
  },
),


                  ],
                ),
              ),
            ),
          ),
          // Comment Input Section - Fixed at the bottom
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
                        borderRadius: BorderRadius.circular(20), // Rounded border
                        borderSide: BorderSide.none, // No visible border
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      filled: true,
                      fillColor: Colors.grey[200], // Light grey background
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
 GestureDetector(
        onTap: () => _addComment(widget.postId, widget.username), // Trigger the _addComment function
        child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 232, 114, 134),
                      shape: BoxShape.circle, // Circular shape
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.paperPlane,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
