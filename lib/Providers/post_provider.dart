import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Models/post_model.dart';

/// Manages all post-related operations (CRUD) with Firestore
/// Notifies listeners when post data changes
class PostProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Post> _posts = []; // Internal list of posts

  /// Public getter for posts list
  List<Post> get posts => _posts;

  /// Fetches all posts from Firestore, ordered by timestamp (newest first)
  Future<void> fetchPosts() async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();
      
      // Convert Firestore documents to Post objects
      _posts = snapshot.docs.map((doc) => Post(
        id: doc.id,
        title: doc['title'],
        message: doc['message'],
        weather: doc['weather'],
        timestamp: (doc['timestamp'] as Timestamp).toDate(),
      )).toList();
      
      notifyListeners(); // Notify widgets to rebuild
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    }
  }

  /// Adds a new post to Firestore
  /// [post] - The Post object to add
  Future<void> addPost(Post post) async {
    try {
      final docRef = await _firestore.collection('posts').add({
        'title': post.title,
        'message': post.message,
        'weather': post.weather,
        'timestamp': Timestamp.fromDate(post.timestamp),
        'userId': FirebaseAuth.instance.currentUser?.uid, // Track post owner
      });
      print('New post added with ID: ${docRef.id}');
      await fetchPosts(); // Refresh posts list
    } catch (e) {
      debugPrint('Error adding post: $e');
      rethrow; // Let the caller handle the error
    }
  }

  /// Updates an existing post in Firestore
  /// [id] - Document ID of the post to update
  /// [newTitle] - Updated title
  /// [newMessage] - Updated message content
  /// [newWeather] - Updated weather condition
  Future<void> editPost(String id, String newTitle, String newMessage, String newWeather) async {
    try {
      await _firestore.collection('posts').doc(id).update({
        'title': newTitle,
        'message': newMessage,
        'weather': newWeather,
      });
      await fetchPosts(); // Refresh posts list
    } catch (e) {
      debugPrint('Error editing post: $e');
      rethrow;
    }
  }

  /// Deletes a post from Firestore
  /// [id] - Document ID of the post to delete
  Future<void> deletePost(String id) async {
    try {
      await _firestore.collection('posts').doc(id).delete();
      await fetchPosts(); // Refresh posts list
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }
}