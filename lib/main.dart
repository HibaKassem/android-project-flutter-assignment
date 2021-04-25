import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hello_me/Models/userModel.dart';
import 'package:hello_me/Models/wordpair.dart';
import 'package:hello_me/Providers/AuthProvider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';

import 'Models/userModel.dart';
import 'Models/userModel.dart';
import 'Providers/AuthProvider.dart';
import 'Providers/AuthProvider.dart';
import 'Providers/AuthProvider.dart';
import 'Providers/AuthProvider.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'Startup Name Generator',
        theme: ThemeData(
          // Add the 3 lines from here...
          primaryColor: Colors.red,
        ),
        home: RandomWords(),
      ),
    );
  }
}

class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[]; // NEW
  final _saved = <WordPair>{}; // NEW
  final _biggerFont = const TextStyle(fontSize: 18); // NEW

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return Scaffold(
          // Add from here...
          appBar: AppBar(
            title: Text('Startup Name Generator'),
            actions: [
              IconButton(
                icon: Icon(Icons.favorite),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SavedSuggestions(),
                      ));
                },
              ),
              snapshot.hasData
                  ? IconButton(
                      icon: Icon(Icons.exit_to_app),
                      onPressed: () async {
                        await Provider.of<AuthProvider>(context, listen: false)
                            .logout();
                      },
                    )
                  : IconButton(
                      icon: Icon(Icons.login),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginPage(),
                            ));
                      },
                    )
            ],
          ),
          body: SnappingSheet(
            snappingPositions: [
              SnappingPosition.factor(positionFactor: 0.03),
              SnappingPosition.factor(positionFactor: 0.18),
            ],
            initialSnappingPosition:
                SnappingPosition.factor(positionFactor: 0.03),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              // The itemBuilder callback is called once per suggested
              // word pairing, and places each suggestion into a ListTile
              // row. For even rows, the function adds a ListTile row for
              // the word pairing. For odd rows, the function adds a
              // Divider widget to visually separate the entries. Note that
              // the divider may be difficult to see on smaller devices.
              itemBuilder: (BuildContext _context, int i) {
                // Add a one-pixel-high divider widget before each row
                // in the ListView.
                if (i.isOdd) {
                  return Divider();
                }

                // The syntax "i ~/ 2" divides i by 2 and returns an
                // integer result.
                // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
                // This calculates the actual number of word pairings
                // in the ListView,minus the divider widgets.
                final int index = i ~/ 2;
                // If you've reached the end of the available word
                // pairings...
                if (index >= _suggestions.length) {
                  // ...then generate 10 more and add them to the
                  // suggestions list.
                  _suggestions.addAll(generateWordPairs().take(10));
                }
                return _buildRow(_suggestions[index]);
              },
            ),
            grabbingHeight: 58,
            grabbing: snapshot.hasData
                ? ListTile(
                    trailing: Icon(Icons.keyboard_arrow_up),
                    tileColor: Colors.grey,
                    title: Text(
                      'Welcome Back, ${FirebaseAuth.instance.currentUser.email}',
                      style: TextStyle(color: Colors.black),
                    ),
                  )
                : null,
            sheetBelow: snapshot.hasData
                ? SnappingSheetContent(
                    child: ListTile(
                      tileColor: Colors.white,
                      leading: Consumer<AuthProvider>(
                        builder: (context, authProvider, child) =>
                            FutureBuilder(
                          future: authProvider.fetchImage(),
                          builder:
                              (BuildContext context, AsyncSnapshot snapshot) {
                            return

                                // snapshot.connectionState ==
                                //         ConnectionState.waiting
                                //     ? CircleAvatar(
                                //         child: CircularProgressIndicator(),
                                //         radius: 25,
                                //       )
                                //     :

                                authProvider.userImage.isEmpty
                                    ? CircleAvatar(
                                        radius: 25,
                                      )
                                    : CircleAvatar(
                                        radius: 25,
                                        backgroundImage: NetworkImage(
                                          authProvider.userImage,
                                        ),
                                      );
                          },
                        ),
                      ),
                      title: Text(
                        FirebaseAuth.instance.currentUser.email,
                      ),
                      subtitle: Row(
                        children: [
                          TextButton(
                              onPressed: () async {
                                PickedFile file = await ImagePicker().getImage(
                                  source: ImageSource.gallery,
                                );

                                if (file != null) {
                                  File image = File(file.path);
                                  Provider.of<AuthProvider>(context,
                                          listen: false)
                                      .imageUpload(image);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('No Image Selected')));
                                }
                              },
                              style: TextButton.styleFrom(
                                  backgroundColor: Colors.green),
                              child: Text(
                                'Change Avatar',
                                style: TextStyle(color: Colors.white),
                              )),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  void showSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login is not implemented yet'),
      ),
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // NEW lines from here...
        builder: (BuildContext context) {
          final tiles = _saved.map(
            (WordPair pair) {
              return ListTile(
                  title: Text(
                    pair.asPascalCase,
                    style: _biggerFont,
                  ),
                  trailing: IconButton(
                      icon: Icon(
                        Icons.delete_outline_outlined,
                        color: Colors.red,
                      ),
                      onPressed: showDeleteSnackbar));
            },
          );

          List<Widget> divided;
          if (tiles.isEmpty) {
            divided = [];
          } else {
            divided =
                ListTile.divideTiles(context: context, tiles: tiles).toList();
          }

          return Scaffold(
            appBar: AppBar(
              title: Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        }, // ...to here.
      ),
    );
  }

  void showDeleteSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deletion is not implemented yet'),
      ),
    );
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair); // NEW
    return Wordtile(
      // biggerFont: _biggerFont,
      wordPair: pair,
    );
  }
}

class Wordtile extends StatefulWidget {
  final WordPair wordPair;
  const Wordtile({
    Key key,
    this.wordPair,
  }) : super(key: key);

  @override
  _WordtileState createState() => _WordtileState();
}

class _WordtileState extends State<Wordtile> {
  bool isSeleted = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, value, _) {
      // print(value.onlyWordPairs);
      return ListTile(
        title: Text(
          widget.wordPair.asPascalCase,
          style: TextStyle(fontSize: 18),
        ),
        trailing: Icon(
          // NEW from here...
          // alreadySaved ? Icons.favorite : Icons.favorite_border,
          value.localWordPairs.contains(widget.wordPair.asPascalCase) ||
                  value.userWordPairsStrings
                      .contains(widget.wordPair.asPascalCase)
              ? Icons.favorite
              : Icons.favorite_border,
          color: value.localWordPairs.contains(widget.wordPair.asPascalCase) ||
                  value.userWordPairsStrings
                      .contains(widget.wordPair.asPascalCase)
              ? Colors.red
              : null,
        ),
        onTap: value.localWordPairs.contains(widget.wordPair.asPascalCase) ||
                value.userWordPairsStrings
                    .contains(widget.wordPair.asPascalCase)
            ? () {
                // print('working');
                // setState(() {
                //   isSeleted = false;
                // });
                value.deletewordpairfromMainScreen(widget.wordPair);
              }
            : () {
                // NEW lines from here...
                // setState(() {
                //   if (alreadySaved) {
                //     _saved.remove(pair);
                //   } else {
                //     _saved.add(pair);
                //   }
                // });
                setState(() {
                  isSeleted = true;
                });

                Provider.of<AuthProvider>(context, listen: false)
                    .addWordPair(widget.wordPair);
              }, // ... to here.
      );
    });
  }
}

class SavedSuggestions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Suggestions'),
      ),
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return snapshot.hasData
              ? FutureBuilder(
                  future: Provider.of<AuthProvider>(context, listen: false)
                      .fetchWords(),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    return snapshot.connectionState == ConnectionState.waiting
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : Consumer<AuthProvider>(
                            builder: (context, value, child) {
                              return ListView.builder(
                                itemCount: value.userWordPairs.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return Column(
                                    children: [
                                      ListTile(
                                        title: Text(
                                          '${value.userWordPairs[index].wordpair}',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(
                                            Icons.delete_outline_outlined,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            value.deletewordpair(
                                                wordPairModel:
                                                    value.userWordPairs[index]);
                                          },
                                        ),
                                      ),
                                      Divider(
                                        height: 1,
                                        thickness: 1,
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                  },
                )
              : Consumer<AuthProvider>(
                  builder: (context, value, child) {
                    return ListView.builder(
                      itemCount: value.localWordPairs.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            ListTile(
                              title: Text(
                                value.localWordPairs[index],
                                style: TextStyle(fontSize: 18),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete_outline_outlined,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  value.deletewordpair(
                                      wordPair: value.localWordPairs[index]);
                                },
                              ),
                            ),
                            Divider(
                              height: 1,
                              thickness: 1,
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
        },
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController email;
  TextEditingController password;
  TextEditingController confirmpassword;

  @override
  void initState() {
    email = TextEditingController();
    password = TextEditingController();
    confirmpassword = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Welcome to Startup Names Generators, please log in below',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(
              height: 16,
            ),
            TextField(
              controller: email,
              decoration: InputDecoration(
                hintText: 'Email',
              ),
            ),
            SizedBox(
              height: 16,
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
              ),
            ),
            SizedBox(
              height: 16,
            ),
            Consumer<AuthProvider>(builder: (context, authProvider, child) {
              return MaterialButton(
                onPressed: () async {
                  await authProvider.login(
                      UserModel(email: email.text, password: password.text),
                      context);
                },
                minWidth: MediaQuery.of(context).size.width,
                color: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: authProvider.isLoading
                    ? SizedBox(
                        height: 10,
                        width: 10,
                        child: CircularProgressIndicator())
                    : Text(
                        'Log in',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
              );
            }),
            MaterialButton(
              onPressed: () async {
                showModalBottomSheet(
                  // isScrollControlled: true,
                  context: context,
                  builder: (context) => Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text('Please confirm your password below'),
                          TextField(
                            controller: confirmpassword,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Confirm Password',
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return TextButton(
                                onPressed: () {
                                  if (password.text != confirmpassword.text) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Passwords must match'),
                                      ),
                                    );
                                  } else {
                                    authProvider.signup(
                                      UserModel(
                                          email: email.text,
                                          password: password.text),
                                      context,
                                    );
                                  }
                                },
                                child: authProvider.isLoadingsignUp
                                    ? SizedBox(
                                        height: 10,
                                        width: 10,
                                        child: CircularProgressIndicator())
                                    : Text(
                                        'Confirm',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                style: TextButton.styleFrom(
                                    backgroundColor: Colors.green),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
              minWidth: MediaQuery.of(context).size.width,
              color: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'New user? Click to sign up',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
