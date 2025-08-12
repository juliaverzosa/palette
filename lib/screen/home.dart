import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pallete/form/edit_post.dart';
import 'package:project_pallete/form/post_form.dart';
import 'package:project_pallete/screen/comment_screen.dart';
import 'package:project_pallete/screen/notif_screen.dart';
import 'package:project_pallete/screen/search_screen.dart';
import 'profile_screen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart'; // Add this import to use date formatting



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _username;
  String? _userId;
  
   List<String> _followingUserIds = [];
  List<DocumentSnapshot> _posts = [];

   // Variable to store the username
  
  List<bool> likedItems = List.generate(6, (index) => false);
bool isLiked = false;  // Track like state



void _fetchUsername() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    setState(() {
      _username = userDoc['username'] ?? 'Unknown';
      _userId = user.uid;
    });
  }
}

  @override
  void initState() {
    super.initState();
    _fetchUsername(); // Fetch username when the page loads
    _fetchFollowingUsers(); 
    _checkLikeStatus();// Fetch the followed users
  }

Future<void> _checkLikeStatus() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final postRef = FirebaseFirestore.instance.collection('posts').doc();
    final postSnapshot = await postRef.get();
    
    if (postSnapshot.exists) {
      final likes = postSnapshot['likes'] ?? [];
      setState(() {
        isLiked = likes.contains(userId);  // Check if the user has already liked the post
      });
    }
  }

  // Fetch the list of users the current user is following
  Future<void> _fetchFollowingUsers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final followingDoc = await FirebaseFirestore.instance
            .collection('following')
            .doc(currentUser.uid)
            .get();

        if (followingDoc.exists) {
          setState(() {
            _followingUserIds = List<String>.from(followingDoc.data()?['followingId'] ?? []);
          });
          _fetchPosts();
        }
      } catch (e) {
        print("Error fetching following users: $e");
      }
    }
  }

  // Fetch posts from the followed users
  Future<void> _fetchPosts() async {
    if (_followingUserIds.isEmpty) return;

    try {
      final postsQuery = FirebaseFirestore.instance
          .collectionGroup('posts') // Query all posts subcollections
          .where('userId', whereIn: _followingUserIds) // Filter by followed users' IDs
          .orderBy('timestamp', descending: true);

      final querySnapshot = await postsQuery.get();

      setState(() {
        _posts = querySnapshot.docs;
      });
    } catch (e) {
      print("Error fetching posts: $e");
    }
  }


// Renaming the new _showPostOptions function
void _showPostOptions(String postUsername, String postId, Map<String, dynamic> post) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(30), // Rounded top corners
      ),
    ),
    builder: (context) {
      bool isOwnPost = _username == postUsername;

      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          color: Colors.white,
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
                          postId: postId,
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
                    // Add your save logic
                  },
                ),
                _buildOption(
                  icon: FontAwesomeIcons.paperPlane,
                  title: "Share",
                  onTap: () {
                    Navigator.pop(context);
                    // Add your share logic
                  },
                ),
                _buildOption(
                  icon: FontAwesomeIcons.trashCan,
                  title: "Delete Post",
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmationDialog(postId);
                  },
                  isDeleteOption: true,
                ),
              ] else ...[
                _buildOption(
                  icon: FontAwesomeIcons.bookmark,
                  title: "Save to Collection",
                  onTap: () {
                    Navigator.pop(context);
                    // Add your save logic
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
                color: isDeleteOption ?const Color.fromARGB(255, 255, 115, 105) : const Color.fromARGB(255, 82, 82, 82)),
            ),
          ],
        ),
      ),
    );
  }


// Function to show the delete confirmation dialog
void _showDeleteConfirmationDialog(String postId) {
  // Ensuring we're using the correct context
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

// Function to delete the post from Firestore
Future<void> _deletePost(String postId) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to delete a post.')),
      );
      return;
    }

    // Deleting the post from Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('posts')
        .doc(postId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post deleted successfully!')),
    );

    // Optionally, you can remove the post from your app's UI here
  } catch (e) {
    debugPrint('Error deleting post: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to delete the post.')),
    );
  }
}

  
  Future<Map<String, dynamic>> _fetchUserAndPosts() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return {};

  // Fetch user document to retrieve the username
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  // Fetch user's posts
  final postsQuery = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('posts')
      .orderBy('timestamp', descending: true)
      .get();


  return {
    'username': userDoc['username'] ?? 'Unknown User',
    'posts': postsQuery.docs,
  };
}



  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onAddButtonPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewPostForm()),
    );
  }

  // Fetch posts stream for the current user, ordered by timestamp (descending)
  Stream<QuerySnapshot> _fetchCurrentUserPostsStream() {
    final user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user == null) {
      return Stream.empty(); // Return an empty stream if no user is logged in
    }

    return FirebaseFirestore.instance
        .collection('users') // Assuming 'users' collection
        .doc(user.uid) // Fetch current user's document
        .collection('posts') // Fetch their posts
        .orderBy('timestamp', descending: true) // Order posts by timestamp in descending order
        .snapshots();
  }

Stream<QuerySnapshot> _fetchExplorePosts() {
  return FirebaseFirestore.instance
      .collectionGroup('posts') // Use collectionGroup to query 'posts' collection across all users
       // Order by timestamp
      .snapshots();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _selectedIndex == 1 ? 'Explore' : 'Home',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        shadowColor: Colors.transparent,
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.bell, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotifyScreen()),
                );
              },
            ),
          if (_selectedIndex == 1)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.search, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
            ),
          GestureDetector(
            onTap: () {
              final user = FirebaseAuth.instance.currentUser; // Get the current user
              if (user != null) { 
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                                  username: _username ?? 'No username', // Pass the username
                                //profilePhotoUrl: 'assets/profile.png', // You can pass the image URL here
                                userId: _userId ?? 'Unknown',
                    ), // Pass the userId
                  ),
                );
              }
            },
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/profile.png'),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _selectedIndex == 0
          ? StreamBuilder<QuerySnapshot>(
              stream: _fetchCurrentUserPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong.'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No posts available.'));
                }

                final posts = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index].data() as Map<String, dynamic>;
                    final postUsername = post['postUsername']; // Get the post's username from Firestore
                      final postId = posts[index].id;
                      final profilePhotoUrl = post['profilePhotoUrl'] ?? 'default_image_url';
                    final timestamp = post['timestamp'] as Timestamp?;
                    String formattedDate = '';

                    if (timestamp != null) {
                      formattedDate = DateFormat('MMM dd, yyyy').format(timestamp.toDate());
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(profilePhotoUrl),
                            ),
                              const SizedBox(width: 10),
                              // Display username once it's fetched
                              Text(
                                _username ?? 'Loading...', // Show loading text if username is null
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 350,
                            width: 350,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[300],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: post['imageUrl'] != null
                                  ? Image.network(
                                      post['imageUrl'],
                                      fit: BoxFit.cover,
                                    )
                                  : const Placeholder(),
                            ),
                          ),
                          const SizedBox(height: 2),
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
              final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

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
                                    icon: const FaIcon(FontAwesomeIcons.comment),
                                    onPressed: () {
                                             final post = posts[index].data() as Map<String, dynamic>;
                                             final postId = posts[index].id; // Get the Firestore document ID

    print(post); // Debugging line

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(
          postImage: post['imageUrl'] ?? '',
          postTitle: post['title'] ?? 'No Title',
          postCaption: post['caption'] ?? 'No Caption', // Ensure 'caption' is in Firestore
          postCategory: post['category'] ?? 'No Category', // Ensure 'category' is in Firestore
          postTags: post['tags'] ?? [], // Ensure 'tags' is a list in Firestore
          postDate: formattedDate,
          postId: postId,
          postUsername: post['postUsername'],
          username: _username ?? '',
          
                                          ),
                                        ),
                                      );
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
                                
                               onPressed:  () => _showPostOptions(postUsername, postId, post),  // Call the method to show the modal bottom sheet

                              ),
                            ],
                          ),

Padding(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), // Horizontal and vertical padding
  child: Text(
    post['title'] ?? 'No Title',
    style: const TextStyle(fontWeight: FontWeight.bold),
  ),
),
const SizedBox(height: 2),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0), // Horizontal and vertical padding
  child: Text(
    formattedDate.isNotEmpty ? formattedDate : 'Date not available',
    style: const TextStyle(color: Colors.grey),
  ),
),
                        ],
                      ),
                    );
                  },
                );
              },
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _fetchExplorePosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No posts available.'));
                }

                final posts = snapshot.data!.docs;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: MasonryGridView.builder(
                    gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                    ),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    itemCount: posts.length,
itemBuilder: (context, index) {
  final post = posts[index].data() as Map<String, dynamic>;

  // Check if timestamp exists to avoid errors
  String formattedDate = '';
  if (post['timestamp'] != null) {
    final timestamp = post['timestamp'] as Timestamp;
    formattedDate = DateFormat('MMM dd, yyyy').format(timestamp.toDate());
  }

  return GestureDetector(
    onTap: () {
      final postId = posts[index].id; // Get the Firestore document ID
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommentScreen(
            postImage: post['imageUrl'] ?? '',
            postTitle: post['title'] ?? 'No Title',
            postCaption: post['caption'] ?? 'No Caption',
            postCategory: post['category'] ?? 'No Category',
            postTags: post['tags'] ?? [], // Safely cast tags to List<String>
            postDate: formattedDate,
            postId: postId,
            postUsername: post['postUsername'] ?? 'Unknown User',
            username: _username ?? 'Unkown',
                                ),
        ),
      );
    },
                        child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: post['imageUrl'] != null
                                    ? Image.network(
                                        post['imageUrl'],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: index % 2 == 0 ? 200 : 150,
                                      )
                                    : const Placeholder(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 232, 114, 134),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.house),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.compass),
            label: 'Explore',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _onAddButtonPressed,
              elevation: 4.0,
              shape: const CircleBorder(),
              tooltip: 'Upload',
              child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
              backgroundColor: const Color.fromARGB(255, 232, 114, 134),
            )
          : null,
    );
  }
}
