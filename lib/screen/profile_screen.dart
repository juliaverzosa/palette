import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:project_pallete/screen/profile_settings.dart';
import 'package:project_pallete/screen/edit_profile_screen.dart';
import 'package:project_pallete/screen/saved_collection.dart'; 
import 'package:project_pallete/screen/welcome_screen.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import FirebaseFirestore
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';


class ProfileScreen extends StatefulWidget {
 
 
  //final String profilePhotoUrl;
  final String username;
   final String userId; 
    
   
  const ProfileScreen({
    super.key,
   // required this.profilePhotoUrl,
    required this.username,
    required this.userId,  // Add userId parameter
  });


  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _displayName;
  String? _username;
  String? _profilePhotoUrl;
  String? _about;
  String? _location;
  bool _isFollowing = false;
 List<QueryDocumentSnapshot> posts = [];


  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchUserProfileDetails();
     _fetchFollowStatus();
     _fetchUserPosts();
  }



  // Fetch the posts for the current user
  Future<void> _fetchUserPosts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        // Fetch posts from Firestore where userId matches the current user's ID
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)  // Get the current user's document
            .collection('posts')  // Fetch posts from the user's "posts" collection
            .orderBy('timestamp', descending: true)  // Order by timestamp (most recent first)
            .get();

        setState(() {
          posts = querySnapshot.docs; // Store the fetched posts in the list
        });
      } catch (e) {
        print("Error fetching user posts: $e");
      }
    }
  }

 Future<int> _fetchFollowersCount(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('followers').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        final List followers = doc['followerId'] ?? [];
        return followers.length;
      } else {
        return 0;
      }
    } catch (e) {
      print('Error fetching followers count: $e');
      return 0;
    }
  }

  // Method to fetch following count
  Future<int> _fetchFollowingCount(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('following').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        final List following = doc['followingId'] ?? [];
        return following.length;
      } else {
        return 0;
      }
    } catch (e) {
      print('Error fetching following count: $e');
      return 0;
    }
  }

   // Fetch user profile information from Firestore
  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;

   if (user != null) {
    try {
      // Fetch the user profile details from the correct Firestore path
final userDoc = await FirebaseFirestore.instance
    .collection('users') // Root collection
    .doc(widget.userId) // User's ID
    .get(); // Directly fetch the user's document



      if (userDoc.exists) {
        print("User Document: ${userDoc.data()}");

        setState(() {
          // Map the fields from Firestore to the local variables
          _username = userDoc.data()?['username'] ?? 'Unknown';
                  });
      } else {
        print("User document does not exist for user ID: ${widget.userId}");
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
  } else {
    print("No user is logged in.");
  }
}
Future<void> _fetchUserProfileDetails() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      // Fetch the user's profile details from the 'profileDetails' sub-collection
      final profileDoc = await FirebaseFirestore.instance
          .collection('users') // Root collection
          .doc(widget.userId) // User's ID
          .collection('profile_details') // Profile details sub-collection
          .doc('details') // Specific document inside 'profileDetails'
          .get(); // Fetch the profile details document

      if (profileDoc.exists) {
        print("Profile Document: ${profileDoc.data()}");
print("Current Profile Photo URL: $_profilePhotoUrl");  // After state update in the UI

        setState(() {
          // Map the fields from Firestore to the local variables
          _displayName = profileDoc.data()?['displayName'] ?? 'Default Display Name';
          _about = profileDoc.data()?['about'] ?? 'No information available.';
          _location = profileDoc.data()?['location'] ?? 'Location not provided';
          _profilePhotoUrl = profileDoc.data()?['profilePhotoUrl'];
          //_coverPhotoUrl = profileDoc.data()?['coverPhotoUrl'];
        });
      } else {
        print("Profile document does not exist for user ID: ${widget.userId}");
      }
    } catch (e) {
      print("Error fetching user profile details: $e");
    }
  } else {
    print("No user is logged in.");
  }
}


  // Method to update profile after EditProfileScreen
  void _updateProfile(String displayName, String about, String location, String profilePhotoUrl) {
    setState(() {
      _displayName = displayName;
      _about = about;
      _location = location;
      _profilePhotoUrl = profilePhotoUrl;
    });
  }

 Stream<int> _getFollowingCountStream(String userId) {
  return FirebaseFirestore.instance
      .collection('following')
      .doc(userId)
      .snapshots()
      .map((doc) => (doc.data()?['followingId'] as List).length);
}

Stream<int> _getFollowersCountStream(String userId) {
  return FirebaseFirestore.instance
      .collection('followers')
      .doc(userId)
      .snapshots()
      .map((doc) => (doc.data()?['followerId'] as List).length);
}


Future<void> _toggleFollow() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  final followedUserId = widget.userId; // The user being followed

  if (currentUser != null) {
    setState(() {
      _isFollowing = !_isFollowing;
    });

    try {
      final currentUserId = currentUser.uid;

      // Add to following collection
      if (_isFollowing) {
        await FirebaseFirestore.instance.collection('following').doc(currentUserId).set({
          'followingId': FieldValue.arrayUnion([followedUserId]),
        }, SetOptions(merge: true));

        // Add to followers collection of the followed user
        await FirebaseFirestore.instance.collection('followers').doc(followedUserId).set({
          'followerId': FieldValue.arrayUnion([currentUserId]),
        }, SetOptions(merge: true));
      } else {
        // Remove from following collection
        await FirebaseFirestore.instance.collection('following').doc(currentUserId).set({
          'followingId': FieldValue.arrayRemove([followedUserId]),
        }, SetOptions(merge: true));

        // Remove from followers collection
        await FirebaseFirestore.instance.collection('followers').doc(followedUserId).set({
          'followerId': FieldValue.arrayRemove([currentUserId]),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error toggling follow: $e");
    }
  }
}

void _fetchFollowStatus() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    final currentUserId = currentUser.uid;
    final followedUserId = widget.userId; // The user being followed

    try {
      final followingDoc = await FirebaseFirestore.instance.collection('following').doc(currentUserId).get();
      if (followingDoc.exists) {
        final followingIds = List<String>.from(followingDoc['followingId']);
        setState(() {
          _isFollowing = followingIds.contains(followedUserId);
        });
      }
    } catch (e) {
      print("Error fetching follow status: $e");
    }
  }
}
 Widget _buildGallery() {
    return MasonryGridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Two columns in the grid
      ),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      itemCount: posts.length, // Use the length of posts fetched
      itemBuilder: (context, index) {
        final post = posts[index].data() as Map<String, dynamic>;
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
      final currentUser = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2, // Number of tabs (Gallery, Feed, About)
      child: Scaffold(
        backgroundColor: Colors.white,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                backgroundColor: Colors.white,
                elevation: 0.0,
                shadowColor: Colors.transparent,
                floating: true,
                pinned: false,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: Text(
                  _username != null ? '@$_username' : 'Loading...',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    onPressed: () {
                      _showLogoutBottomSheet(context);
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(94, 232, 114, 134),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding:  EdgeInsets.all(20),
                      height: 300,
                      
                      child: Row(
                                                children: [
                          // Fetch and display the profile image
          Padding(
    padding: const EdgeInsets.only(right: 6.0), // Adjust padding as needed
    child: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
        ? CircleAvatar(
            radius: 50,
            
            backgroundImage: NetworkImage(_profilePhotoUrl!), // Load from network
          )
          
        : const CircleAvatar(
             radius: 50,
             //backgroundImage: AssetImage('assets/profile.png'),

            // Fallback color if no URL
          ),
  ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _displayName != null ? _displayName! : '',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  // Conditional button rendering
                                  currentUser?.uid == widget.userId
                                      ? ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => EditProfileScreen(
                                                  userId: currentUser!.uid, // Pass current userId
                                                  userName: _username ?? '', // Pass username
                                                  displayName: _displayName ?? '', // Pass display name
                                                  profilePhotoUrl: _profilePhotoUrl ?? '',
                                                  about: _about ?? '',
                                                  location: _location ?? '',
                                                  onProfileUpdate: _updateProfile, // Pass profile image URL
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor:
                                                const Color.fromARGB(255, 232, 114, 134),
                                            minimumSize: const Size(140, 40),
                                          ),
                                          child: const Text('Edit Profile'),
                                        )
                                      : ElevatedButton(
                                          onPressed: _toggleFollow,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _isFollowing ? Colors.white : Color.fromARGB(255, 232, 114, 134),
                                            foregroundColor: _isFollowing ? Colors.pink : Colors.white,
                                            minimumSize: const Size(140, 40),
                                          ),
                                          child: Text(_isFollowing ? 'Unfollow' : 'Follow'),
                                        ),
                                  const SizedBox(width: 10),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Column(
            children: [
              const TabBar(
                indicatorColor: Color.fromARGB(255, 232, 114, 134),
                labelColor: Color.fromARGB(255, 232, 114, 134),
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'Gallery'),
                 // Tab(text: 'Feed'),
                  Tab(text: 'About'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Gallery Tab
                    Expanded(child: _buildGallery()),  // Display gallery posts in staggered grid
 
                    // GridView.builder(
                    //   padding: const EdgeInsets.all(20),
                    //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    //     crossAxisCount: 2,
                    //     crossAxisSpacing: 10,
                    //     mainAxisSpacing: 10,
                    //   ),
                    //   itemBuilder: (context, index) {
                    //     return Container(
                    //       decoration: BoxDecoration(
                    //         color: const Color.fromARGB(255, 237, 237, 237),
                    //         borderRadius: BorderRadius.circular(10),
                    //       ),
                    //       child: Center(child: Text('Image ${index + 1}')),
                    //     );
                    //   },
                    //   //itemCount: 12, // Number of items in grid
                    // ),
                    // // Feed Tab
                    // ListView.builder(
                    //   padding: const EdgeInsets.all(20),
                    //   itemCount: 5, // Number of posts
                    //   itemBuilder: (context, index) {
                    //     return Container(
                    //       margin: const EdgeInsets.only(bottom: 20),
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           Row(
                    //             children: [
                    //               const CircleAvatar(
                    //                 radius: 20,
                    //                 backgroundImage:
                    //                     AssetImage('assets/profile.png'),
                    //               ),
                    //               const SizedBox(width: 10),
                    //               Text(
                    //                  _username != null ? '$_username' : 'Loading...',

                    //                 style: const TextStyle(fontWeight: FontWeight.bold),
                    //               ),
                    //             ],
                    //           ),
                    //           const SizedBox(height: 10),
                    //           Container(
                    //             height: 350,
                    //             decoration: BoxDecoration(
                    //               borderRadius: BorderRadius.circular(10),
                    //               color: Colors.grey[300],
                    //             ),
                    //             child: Center(
                    //               child: Text(
                    //                 'Post Image ${index + 1}',
                    //                 style: const TextStyle(color: Colors.black54),
                    //               ),
                    //             ),
                    //           ),
                    //           const SizedBox(height: 10),
                    //           Row(
                    //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //             children: [
                    //               Row(
                    //                 children: [
                    //                   IconButton(
                    //                     icon: const FaIcon(FontAwesomeIcons.heart),
                    //                     onPressed: () {},
                    //                   ),
                    //                   IconButton(
                    //                     icon: const FaIcon(FontAwesomeIcons.comment),
                    //                     onPressed: () {},
                    //                   ),
                    //                   IconButton(
                    //                     icon: const FaIcon(FontAwesomeIcons.retweet),
                    //                     onPressed: () {},
                    //                   ),
                    //                 ],
                    //               ),
                    //               IconButton(
                    //                 icon: const FaIcon(FontAwesomeIcons.bookmark),
                    //                 onPressed: () {},
                    //               ),
                    //             ],
                    //           ),
                    //           const Text(
                    //             'Liked by user1 and others',
                    //             style: TextStyle(color: Colors.grey),
                    //           ),
                    //           const SizedBox(height: 5),
                    //           const Text(
                    //             'View all comments',
                    //             style: TextStyle(color: Colors.grey),
                    //           ),
                    //         ],
                    //       ),
                    //     );
                    //   },
                    // ),
                    // About Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            _about != null ? _about! : 'Share about yourself!',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                          const SizedBox(height: 40),
                          // Location Section
                           Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.grey, size: 20),
                              SizedBox(width: 10),
                              Text(
                                _location != null ? _location! : 'No location.',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          // Followers/Following Section
                          Container(
  decoration: BoxDecoration(
    color: Colors.grey[200],
    borderRadius: BorderRadius.circular(15),
  ),
   padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
  child: FutureBuilder(
    future: Future.wait([
      _fetchFollowersCount(widget.userId),
      _fetchFollowingCount(widget.userId),
    ]),
builder: (context, snapshot) {
  // // Show a loading indicator while waiting for the data
  // if (snapshot.connectionState == ConnectionState.waiting) {
  //   return const Center(
  //     //child: CircularProgressIndicator(), // Show a loading indicator
  //   );
  // } 
  // // Handle any errors that might have occurred during data fetch
  // else if (snapshot.hasError) {
  //   return const Center(
  //     child: Text('Error loading counts'), // Handle errors gracefully
  //   );
  // } 
  // Once data is loaded, show the follower/following counts
  //else if (snapshot.hasData) {
    final counts = snapshot.data as List<int>;
    final followersCount = counts[0];
    final followingCount = counts[1];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            Text(
              '$followersCount', // Dynamically fetched followers count
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            const Text('Followers', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        Column(
          children: [
            Text(
              '$followingCount', // Dynamically fetched following count
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            const Text('Following', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ],
    );

  },

      
    // },
  ),
),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                color: isDeleteOption ? const Color.fromARGB(255, 255, 115, 105) : const Color.fromARGB(255, 82, 82, 82),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showLogoutBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white, // Set the background of the bottom sheet to white
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)), // Rounded top corners
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
_buildOption(
  icon: FontAwesomeIcons.bookmark,
  title: "Saved Collection",
  onTap: () {
    Navigator.pop(context); // Close the current screen or menu
    // Navigate to the SavedCollectionScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SavedCollectionScreen()),
    );
  },
),
            _buildOption(
              icon: FontAwesomeIcons.lock,
              title: "Change Password",
              onTap: () {
                Navigator.pop(context);
                // Add logic for Change Password
              },
            ),
            _buildOption(
              icon: FontAwesomeIcons.rightFromBracket,
              title: "Logout",
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                );
              },
              isDeleteOption: true, // Highlight logout as a special action
            ),
          ],
        ),
      );
    },
  );
}}