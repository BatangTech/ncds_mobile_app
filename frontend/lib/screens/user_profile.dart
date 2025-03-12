//ใช้งาน
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile extends StatelessWidget {
  final String userId;

  const UserProfile({Key? key, required this.userId}) : super(key: key);

  Future<Map<String, String>> _getUserProfile() async {
    var userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return {
        'name': userDoc['name'],
        'email': userDoc['email'],
      };
    }
    return {'name': 'Unknown', 'email': 'Unknown'};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _getUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${snapshot.data!['name']}',
                    style: TextStyle(fontSize: 20)),
                Text('Email: ${snapshot.data!['email']}',
                    style: TextStyle(fontSize: 20)),
              ],
            ),
          );
        } else {
          return Center(child: Text('No data found'));
        }
      },
    );
  }
}
