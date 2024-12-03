import 'package:flutter/material.dart';
import 'package:project_pallete/form/post_form.dart';
import 'package:project_pallete/screen/comment_screen.dart';
import 'profile_screen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Track the index of the selected bottom navigation tab
  int _selectedIndex = 0;

  // List of feed items for Instagram-like design
  final List<Map<String, String>> feedItems = [
    {"image": "assets/arts/witchlet.jpg", "title": "Student Witchlet"},
    {"image": "assets/arts/bunnygirl.jpg", "title": "Dreamy Girl"},
    {"image": "assets/arts/summer_childe.jpg", "title": "Summer Childe"},
    {"image": "assets/arts/girlpond.jpg", "title": "Girl and Koi"},
    {"image": "assets/arts/nicole.jpg", "title": "Nicole Demara ZZZ"},
    {"image": "assets/arts/lumine.jpg", "title": "Modern AU Lumine"},
  ];

  // Track the state of the heart icon (liked or not) for each feed item
  List<bool> likedItems = List.generate(6, (index) => false); // Initialize all as not liked

  // Method to handle tab changes
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Handle add/upload action
  void _onAddButtonPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewPostForm()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      appBar: AppBar(
        automaticallyImplyLeading: false, // Prevent the back icon
        title: Text(
          _selectedIndex == 1
              ? 'Explore'
              : _selectedIndex == 2
                  ? 'Messages'
                  : 'Home', // Change AppBar title based on selected tab
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold, // Makes the text bold
          ),
        ),
        backgroundColor: Colors.white, // Set AppBar background color to white
        elevation: 0.0,
        shadowColor: Colors.transparent,
        actions: [
          // Show Notification icon only on the Home tab
          if (_selectedIndex == 0)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.bell, color: Colors.black),
              onPressed: () {
                // Handle notification tap
                print('Notifications tapped');
              },
            ),
            if (_selectedIndex == 1)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.search, color: Colors.black),
              onPressed: (){},
            ),
          // Profile icon
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
          const SizedBox(width: 10),
        ],
      ),
      body: _selectedIndex == 0 // Home tab
          ? Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: feedItems.length, // Number of posts
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Information Row
                              const Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage: AssetImage('assets/profile.png'),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'username',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Post Image Container
                              Container(
                                height: 350,
                                width: 350,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[300],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    feedItems[index]["image"]!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Action Buttons (Like, Comment, Share, Bookmark)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: FaIcon(
                                          likedItems[index]
                                              ? FontAwesomeIcons.solidHeart // Solid heart when liked
                                              : FontAwesomeIcons.heart, // Outline heart when not liked
                                          color: likedItems[index] ? Colors.pink : Colors.black, // Change color based on state
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            likedItems[index] = !likedItems[index]; // Toggle the like state
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const FaIcon(FontAwesomeIcons.comment),
                                          onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(
          postImage: feedItems[index]["image"]!, // Pass image to comment screen
          postTitle: feedItems[index]["title"]!, // Pass title to comment screen
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
                                    icon: const FaIcon(FontAwesomeIcons.bookmark),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                              // Likes and Comments Text
                              const Text(
                                'Liked by user1 and others',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'View all comments',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            )
          : _selectedIndex == 1 // Explore tab
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: MasonryGridView.builder(
                    gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Number of columns
                    ),
                    mainAxisSpacing: 10, // Space between items vertically
                    crossAxisSpacing: 10, // Space between items horizontally
                    itemCount: feedItems.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          // Handle item tap (e.g., navigate to a detail page)
                        },
                        child: Card(
                          color: Colors.white, // Set the card background to white
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15), // Apply border radius to all corners
                          ),
                          elevation: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15), // Round all corners of the image
                                child: Image.asset(
                                  feedItems[index]["image"]!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: index % 2 == 0 ? 200 : 150, // Vary height for effect
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(10),
                  child: ListView.builder(
                    itemCount: 5, // Example message count
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 25,
                                  backgroundImage: AssetImage('assets/profile.png'),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Friend Name', style: TextStyle(fontWeight: FontWeight.bold)),
                                    SizedBox(height: 5),
                                    Text('Hey! How are you?', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                            const Icon(Icons.message, color: Colors.grey),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white, // Set BottomNavigationBar background color to white
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 232, 114, 134), // Active tab color
        unselectedItemColor: Colors.grey, // Inactive tab color
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
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.comments),
            label: 'Messages',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 // Show add button only on Home tab
          ? FloatingActionButton(
              onPressed: _onAddButtonPressed,
              elevation: 4.0,
              shape: const CircleBorder(),
              tooltip: 'Upload',
              child: const FaIcon(FontAwesomeIcons.plus, color:Colors.white),
              backgroundColor: const Color.fromARGB(255, 232, 114, 134),
              
            )
          : null,
    );
  }
}
