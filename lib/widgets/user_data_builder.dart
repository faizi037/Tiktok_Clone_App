import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDataBuilder extends StatelessWidget {
  final String uid;
  final Widget Function(BuildContext context, Map<String, dynamic> userData) builder;
  final Widget? loadingWidget;

  const UserDataBuilder({
    super.key,
    required this.uid,
    required this.builder,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink(); // Or some error widget
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // If data is loading or doesn't exist, we might want to show a placeholder
          // or use the builder with empty/default data if provided.
          // For now, let's pass an empty map or default values if possible,
          // but since we don't know the defaults here, we'll return loading or empty.
          if (loadingWidget != null) return loadingWidget!;
          
          // Fallback to a "loading" state for the builder if possible, 
          // or just return a placeholder. 
          // However, to prevent UI jumping, we can try to pass null or empty map
          // and let the builder handle it, but the builder expects Map<String, dynamic>.
          return builder(context, {}); 
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        return builder(context, data);
      },
    );
  }
}
