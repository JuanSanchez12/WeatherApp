import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Models/post_model.dart';
import '../Providers/post_provider.dart';

/// Screen for creating or editing community posts
/// Can be used for both new posts and editing existing ones
class AddPostScreen extends StatefulWidget {
  final Post? existingPost; // Existing post to edit (null for new posts)

  const AddPostScreen({super.key, this.existingPost});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  late TextEditingController _titleController; // Controls title input
  late TextEditingController _messageController; // Controls message input
  late String _selectedWeather; // Currently selected weather condition

  // Maps weather conditions to background colors
  final Map<String, Color> _weatherOptions = {
    'clear': Colors.orange[100]!,
    'clouds': Colors.grey[200]!,
    'rain': Colors.blue[100]!,
    'snow': Colors.blue[50]!,
    'thunderstorm': Colors.purple[100]!,
  };

  // Maps weather conditions to display icons
  final Map<String, IconData> _weatherIcons = {
    'clear': Icons.wb_sunny,
    'clouds': Icons.cloud,
    'rain': Icons.beach_access,
    'snow': Icons.ac_unit,
    'thunderstorm': Icons.flash_on,
  };

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing post data (if editing)
    _titleController = TextEditingController(text: widget.existingPost?.title ?? '');
    _messageController = TextEditingController(text: widget.existingPost?.message ?? '');
    _selectedWeather = widget.existingPost?.weather ?? 'clear'; // Default to 'clear'
  }

  @override
  void dispose() {
    // Clean up controllers when widget is disposed
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPost == null ? 'Create Post' : 'Edit Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Title input field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              // Message input field
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 3, // Allow multiple lines for message
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a message' : null,
              ),
              const SizedBox(height: 16),
              // Weather selection dropdown
              DropdownButtonFormField<String>(
                value: _selectedWeather,
                items: _weatherOptions.keys.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        // Weather icon with colored background
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _weatherOptions[value],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _weatherIcons[value],
                            color: _getWeatherIconColor(value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Weather label (capitalized)
                        Text(value[0].toUpperCase() + value.substring(1)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedWeather = value!),
                decoration: const InputDecoration(labelText: 'Weather'),
              ),
              const Spacer(), // Pushes button to bottom
              // Submit button (changes label based on create/edit mode)
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(widget.existingPost == null ? 'Post' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns appropriate icon color based on weather condition
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

  /// Handles form submission for both new posts and updates
  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final postProvider = Provider.of<PostProvider>(context, listen: false);
        final newPost = Post(
          id: widget.existingPost?.id ?? '', // Keep existing ID if editing
          title: _titleController.text,
          message: _messageController.text,
          weather: _selectedWeather,
          timestamp: widget.existingPost?.timestamp ?? DateTime.now(), // Keep original timestamp if editing
        );

        // Determine whether to add new post or update existing
        if (widget.existingPost == null) {
          await postProvider.addPost(newPost);
        } else {
          await postProvider.editPost(
            widget.existingPost!.id,
            newPost.title,
            newPost.message,
            newPost.weather,
          );
        }
        Navigator.pop(context); // Return to previous screen after success
      } catch (e) {
        // Show error message if operation fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}