import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Map<String, dynamic>> filteredSuggestions = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;

  // Fetch search results using multiple field queries
  Future<void> _fetchSearchResults(String query) async {
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final results = <Map<String, dynamic>>[];

      // Search for 'posts' collectionGroup based on multiple fields
      final queries = await Future.wait([
        FirebaseFirestore.instance
            .collectionGroup('posts')
            .where('title', isGreaterThanOrEqualTo: query)
            .where('title', isLessThanOrEqualTo: query + '\uf8ff')
            .get(),
        FirebaseFirestore.instance
            .collectionGroup('posts')
            .where('caption', isGreaterThanOrEqualTo: query)
            .where('caption', isLessThanOrEqualTo: query + '\uf8ff')
            .get(),
        FirebaseFirestore.instance
            .collectionGroup('posts')
            .where('category', isGreaterThanOrEqualTo: query)
            .where('category', isLessThanOrEqualTo: query + '\uf8ff')
            .get(),
        FirebaseFirestore.instance
            .collectionGroup('posts')
            .where('tags', arrayContains: query)
            .get(),
        FirebaseFirestore.instance
            .collectionGroup('posts')
            .where('username', isGreaterThanOrEqualTo: query)
            .where('username', isLessThanOrEqualTo: query + '\uf8ff')
            .get(),
      ]);

      // Combine results from all queries
      for (var querySnapshot in queries) {
        for (var doc in querySnapshot.docs) {
          results.add({
            'title': doc['title'] ?? '',
            'username': doc['username'] ?? '',
            'caption': doc['caption'] ?? '',
            'category': doc['category'] ?? '',
            'tags': List<String>.from(doc['tags'] ?? []),
            'imageUrl': doc['imageUrl'] ?? '',
          });
        }
      }

      // Remove duplicate results
      final uniqueResults = results.toSet().toList();

      setState(() {
        filteredSuggestions = uniqueResults;
      });
    } catch (e) {
      print('Error fetching search results: $e');
      setState(() {
        filteredSuggestions = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterSuggestions(String query) {
    _fetchSearchResults(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _filterSuggestions,
          decoration: const InputDecoration(
            hintText: 'Search artworks...',
            border: InputBorder.none,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredSuggestions.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filteredSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = filteredSuggestions[index];
                      return Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display Image
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: suggestion['imageUrl'].isNotEmpty
                                        ? NetworkImage(suggestion['imageUrl'])
                                        : const AssetImage('assets/placeholder.png')
                                            as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Display Title
                            Text(
                              suggestion['title'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Display Username
                            Text(
                              'By ${suggestion['username']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              : const Center(
                  child: Text('No results found.'),
                ),
    );
  }
}
