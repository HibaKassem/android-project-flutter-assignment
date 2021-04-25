import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:hello_me/Models/userModel.dart';
import 'package:hello_me/Models/wordpair.dart';

import '../Models/userModel.dart';

class AuthProvider with ChangeNotifier {
  bool isLoading = false;
  bool isLoadingsignUp = false;
  String userImage = '';

  Future<void> signup(UserModel userModel, BuildContext context) async {
    isLoadingsignUp = true;
    notifyListeners();
    try {
      final ref = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: userModel.email, password: userModel.password);
      if (localWordPairs.isNotEmpty) {
        localWordPairs.forEach((element) async {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(ref.user.uid)
              .collection('words')
              .add({'wordpair': element});
        });
        localWordPairs = [];
      }
      await fetchWords();
      Navigator.pop(context);
      Navigator.pop(context);
      notifyListeners();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
    isLoadingsignUp = false;
    notifyListeners();
  }

  Future<void> login(UserModel userModel, BuildContext context) async {
    isLoading = true;
    notifyListeners();
    try {
      final ref = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: userModel.email, password: userModel.password);
      await fetchWords();
      if (localWordPairs.isNotEmpty) {
        localWordPairs.forEach((element) async {
          if(!userWordPairsStrings.contains(element)){
            await FirebaseFirestore.instance
                .collection('users')
                .doc(ref.user.uid)
                .collection('words')
                .add({'wordpair': element});
          }
        });
      }
      localWordPairs = [];
      await fetchWords();
      Navigator.pop(context);
      notifyListeners();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('There was an logging into the app'),
        ),
      );
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> imageUpload(File image) async {
    final uid = FirebaseAuth.instance.currentUser.uid;
    try {
      final ref = FirebaseStorage.instance.ref().child('avatars/$uid');
      final uploadTask = ref.putFile(image);

      final taskSnapshot = await uploadTask.whenComplete(() {});
      String thisimageFileURL = await taskSnapshot.ref.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'avatar': thisimageFileURL});
      userImage = thisimageFileURL;
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchImage() async {
    final uid = FirebaseAuth.instance.currentUser.uid;
    try {
      final ref =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (ref.exists) {
        userImage = ref.data()['avatar'];
        notifyListeners();
      } else {
        userImage = '';
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    localWordPairs = [];
    userWordPairsStrings = [];
    userImage = '';
    notifyListeners();
  }

  List<WordPairModel> userWordPairs = [];
  List<String> userWordPairsStrings = [];
  List<String> localWordPairs = [];

  Future<void> fetchWords() async {
    try {
      final ref = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser.uid)
          .collection('words')
          .get();
      List<WordPairModel> helperList = [];
      ref.docs.forEach((element) {
        helperList.add(WordPairModel(
            id: element.id, wordpair: element.data()['wordpair']));
      });
      userWordPairsStrings = helperList.map((e) => e.wordpair).toList();
      userWordPairs = helperList;

      notifyListeners();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> addWordPair(WordPair wordPair) async {
    if (FirebaseAuth.instance.currentUser == null) {
      localWordPairs.add(wordPair.asPascalCase);
      notifyListeners();
    } else {
      try {
        final ref = await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser.uid)
            .collection('words')
            .add({
          'wordpair': wordPair.asPascalCase.toString(),
        });
        userWordPairsStrings.add(wordPair.asPascalCase);
        userWordPairs
            .add(WordPairModel(id: ref.id, wordpair: wordPair.asPascalCase));
        notifyListeners();
      } catch (e) {
        print(e.toString());
      }
    }
  }

  Future<void> deletewordpair(
      {WordPairModel wordPairModel, String wordPair}) async {
    if (FirebaseAuth.instance.currentUser == null) {
      localWordPairs.remove(wordPair);
      notifyListeners();
    } else {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser.uid)
            .collection('words')
            .doc(wordPairModel.id)
            .delete();
        userWordPairs.remove(wordPairModel);
        userWordPairsStrings.remove(wordPairModel.wordpair);
        notifyListeners();
      } catch (e) {
        print(e.toString());
      }
    }
  }

  Future<void> deletewordpairfromMainScreen(WordPair wordPair) async {
    if (FirebaseAuth.instance.currentUser == null) {
      localWordPairs.remove(wordPair.asPascalCase);
      notifyListeners();
    } else {
      try {
        final ref = await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser.uid)
            .collection('words')
            .where('wordpair', isEqualTo: wordPair.asPascalCase)
            .get();
        print(ref.docs.first.id);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser.uid)
            .collection('words')
            .doc(ref.docs.first.id)
            .delete();

        userWordPairsStrings.remove(wordPair.asPascalCase);

        notifyListeners();
      } catch (e) {
        print(e.toString());
      }
    }
  }
}
