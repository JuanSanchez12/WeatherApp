import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Models/post_model.dart';

class PostProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Post> _posts = [];

  List<Post> get posts => _posts;

  Future<void> fetchPosts() async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();
      
      _posts = snapshot.docs.map((doc) => Post(
        id: doc.id,
        title: doc['title'],
        message: doc['message'],
        weather: doc['weather'],
        timestamp: (doc['timestamp'] as Timestamp).toDate(),
      )).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    }
  }

  Future<void> addPost(Post post) async {
  try {
    final docRef = await _firestore.collection('posts').add({
      'title': post.title,
      'message': post.message,
      'weather': post.weather,
      'timestamp': Timestamp.fromDate(post.timestamp),
      'userId': FirebaseAuth.instance.currentUser?.uid,
    });
    print('New post added with ID: ${docRef.id}');
    await fetchPosts();
  } catch (e) {
    debugPrint('Error adding post: $e');
    rethrow;
  }
}

  Future<void> editPost(String id, String newTitle, String newMessage, String newWeather) async {
    try {
      await _firestore.collection('posts').doc(id).update({
        'title': newTitle,
        'message': newMessage,
        'weather': newWeather,
      });
      await fetchPosts();
    } catch (e) {
      debugPrint('Error editing post: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String id) async {
    try {
      await _firestore.collection('posts').doc(id).delete();
      await fetchPosts();
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }
}