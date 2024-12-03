import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:project_pallete/screen/profile_settings.dart';
import 'package:project_pallete/screen/welcome_screen.dart'; // Import your Welcome page

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs (Gallery, Feed, About)
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
                title: const Text(
                  '@username', // Username displayed in the center
                  style: TextStyle(
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
                        color: const Color.fromARGB(255, 237, 237, 237),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(20),
                      height: 300,
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage('assets/profile.png'),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'display name',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                "Bio",
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()
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
                  Tab(text: 'Feed'),
                  Tab(text: 'About'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Gallery Tab
                    GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 237, 237, 237),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text('Image ${index + 1}')),
                        );
                      },
                      itemCount: 12, // Number of items in grid
                    ),
                    // Feed Tab
                    ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: 5, // Number of posts
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage:
                                        AssetImage('assets/profile.png'),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'username',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 350,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[300],
                                ),
                                child: Center(
                                  child: Text(
                                    'Post Image ${index + 1}',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const FaIcon(FontAwesomeIcons.heart),
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
                    // About Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hawakan mo ako isa pa, makikila mo kung sino ako!',
                            style: TextStyle(
                                fontSize: 16, color: Colors.black54),
                          ),
                          const SizedBox(height: 40),
                          // Location Section
                          const Row(
                            children: [
                              Icon(Icons.location_on,
                                  color: Colors.grey, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Baracatan, Toril',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey),
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 20),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Followers
                                Column(
                                  children: [
                                    Text(
                                      '120',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Followers',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                // Following
                                Column(
                                  children: [
                                    Text(
                                      '200',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Following',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
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
            ],
          ),
        ),
      ),
    );
  }

  // Show bottom sheet with logout option
  void _showLogoutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.exit_to_app,
                    color: Color.fromARGB(255, 255, 87, 75),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 87, 75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
