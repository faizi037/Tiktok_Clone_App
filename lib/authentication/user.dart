import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? name;
  String? uid;
  String? email;
  String? youtube;
  String? facebook;
  String? instagram;
  String? twitter;

  UserModel({
    this.name,
    this.uid,
    this.email,
    this.youtube,
    this.facebook,
    this.instagram,
    this.twitter,
  });

  // Convert object to JSON
  Map<String, dynamic> toJson() => {
        "name": name,
        "uid": uid,
        "email": email,
        "youtube": youtube,
        "facebook": facebook,
        "instagram": instagram,
        "twitter": twitter,
      };

  // Create object from Firestore snapshot
  static UserModel fromSnap(DocumentSnapshot snapshot) {
    var dataSnapshot = snapshot.data() as Map<String, dynamic>;

    return UserModel(
      name: dataSnapshot["name"],
      uid: dataSnapshot["uid"],
      email: dataSnapshot["email"],
      youtube: dataSnapshot["youtube"],
      facebook: dataSnapshot["facebook"],
      instagram: dataSnapshot["instagram"],
      twitter: dataSnapshot["twitter"],
    );
  }
}
