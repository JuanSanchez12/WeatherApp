import 'package:flutter/material.dart';
import '../Models/post_model.dart';

class PostProvider with ChangeNotifier {
  final List<Post> _posts = [];

  List<Post> get posts => _posts;

  void addPost(Post post) {
    _posts.insert(0, post);
    notifyListeners();
  }

  void editPost(String id, String newTitle, String newMessage, String newWeather) {
    final index = _posts.indexWhere((post) => post.id == id);
    if (index != -1) {
      _posts[index] = _posts[index].copyWith(
        title: newTitle,
        message: newMessage,
        weather: newWeather,
      );
      notifyListeners();
    }
  }

  void deletePost(String id) {
    _posts.removeWhere((post) => post.id == id);
    notifyListeners();
  }
}