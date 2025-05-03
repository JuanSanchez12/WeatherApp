import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Models/post_model.dart';
import '../Providers/post_provider.dart';
import '../Screens/add_post_screen.dart';

// Screen for displaying community weather posts
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch posts after the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostProvider>(context, listen: false).fetchPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Posts'),
      ),
      // Main content area showing list of posts
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: postProvider.posts.length,
            itemBuilder: (context, index) {
              final post = postProvider.posts[index];
              return _buildPostCard(context, post);
            },
          );
        },
      ),
      // Button to add new post
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddPostScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Builds a card widget for an individual post
  Widget _buildPostCard(BuildContext context, Post post) {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    // Mapping of weather types to background colors
    final weatherOptions = {
      'clear': Colors.orange[100]!,
      'clouds': Colors.grey[200]!,
      'rain': Colors.blue[100]!,
      'snow': Colors.blue[50]!,
      'thunderstorm': Colors.purple[100]!,
    };
    
    // Mapping of weather types to icons
    final weatherIcons = {
      'clear': Icons.wb_sunny,
      'clouds': Icons.cloud,
      'rain': Icons.beach_access,
      'snow': Icons.ac_unit,
      'thunderstorm': Icons.flash_on,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column with user avatar and weather icon
            Column(
              children: [
                // User avatar placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: const Icon(Icons.person, size: 40, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                // Weather condition icon
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: weatherOptions[post.weather],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    weatherIcons[post.weather],
                    color: _getWeatherIconColor(post.weather),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Right column with post content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with edit/delete menu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          post.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      // Context menu for post actions
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            // Navigate to edit screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddPostScreen(existingPost: post),
                              ),
                            );
                          } else if (value == 'delete') {
                            // Delete the post
                            postProvider.deletePost(post.id);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Post message content
                  Text(post.message),
                  const SizedBox(height: 8),
                  // Post date
                  Text(
                    '${post.timestamp.day}/${post.timestamp.month}/${post.timestamp.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Returns appropriate icon color based on weather type
  Color _getWeatherIconColor(String weatherType) {
    switch (weatherType) {
      case 'clear': return Colors.orange;
      case 'clouds': return Colors.grey;
      case 'rain': return Colors.blue;
      case 'snow': return Colors.lightBlue;
      case 'thunderstorm': return Colors.deepPurple;
      default: return Colors.black;
    }
  }
}