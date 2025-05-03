import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Models/post_model.dart';
import '../Providers/post_provider.dart';

class AddPostScreen extends StatefulWidget {
  final Post? existingPost;

  const AddPostScreen({super.key, this.existingPost});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  late String _selectedWeather;

  final Map<String, Color> _weatherOptions = {
    'clear': Colors.orange[100]!,
    'clouds': Colors.grey[200]!,
    'rain': Colors.blue[100]!,
    'snow': Colors.blue[50]!,
    'thunderstorm': Colors.purple[100]!,
  };

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
    _titleController = TextEditingController(text: widget.existingPost?.title ?? '');
    _messageController = TextEditingController(text: widget.existingPost?.message ?? '');
    _selectedWeather = widget.existingPost?.weather ?? 'clear';
  }

  @override
  void dispose() {
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
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a message' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedWeather,
                items: _weatherOptions.keys.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
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
                        Text(value[0].toUpperCase() + value.substring(1)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedWeather = value!),
                decoration: const InputDecoration(labelText: 'Weather'),
              ),
              const Spacer(),
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

  void _submitForm() async {
  if (_formKey.currentState?.validate() ?? false) {
    try {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final newPost = Post(
        id: widget.existingPost?.id ?? '',
        title: _titleController.text,
        message: _messageController.text,
        weather: _selectedWeather,
        timestamp: widget.existingPost?.timestamp ?? DateTime.now(),
      );

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
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
}