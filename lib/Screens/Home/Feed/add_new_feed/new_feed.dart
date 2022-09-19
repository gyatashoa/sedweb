import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sedweb/Screens/Home/homescreen.dart';
import 'package:sedweb/components/constraints.dart';
import 'package:sedweb/models/post_model.dart';
import 'package:sedweb/models/user_model.dart';
import 'package:sedweb/utils/utils.dart';
import 'package:path/path.dart';

class AddNewFeed extends StatefulWidget {
  const AddNewFeed({Key? key}) : super(key: key);

  @override
  State<AddNewFeed> createState() => _AddNewFeedState();
}

class _AddNewFeedState extends State<AddNewFeed> {
  TextEditingController controller = TextEditingController();
  List<File> chosenPictures = [];
  bool isLoading = false;
  User? user = FirebaseAuth.instance.currentUser;
  UserModel currentUSer = UserModel();

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get()
        .then((value) {
      currentUSer = UserModel.fromMap(value.data());
      print(currentUSer.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new feed'),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: kPrimaryColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(children: [
                TextFormField(
                  maxLines: 6,
                  controller: controller,
                  decoration: InputDecoration(
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5)),
                      fillColor: Colors.white,
                      hintText: 'Share your ideas'),
                ),
                chosenPictures.isNotEmpty
                    ? Container(
                        height: 140,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: chosenPictures.length,
                            itemBuilder: ((context, index) {
                              return pictureBox(
                                  file: chosenPictures[index],
                                  onPressed: () {
                                    setState(() {
                                      chosenPictures.removeAt(index);
                                    });
                                  });
                            })),
                      )
                    : Container(),
                Container(
                  decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: Color(0xFF666666), width: 0.5))),
                  child: ListTile(
                    onTap: () async {
                      try {
                        File picture = await pickImage(ImageSource.camera);
                        if (picture.path.isNotEmpty) {
                          chosenPictures.add(picture);
                        }

                        setState(() {});
                        print(picture.path);
                      } catch (e) {
                        showSnackBar(context, 'Error in picking image');
                      }
                    },
                    leading: const Icon(
                      Icons.camera,
                      color: Colors.grey,
                    ),
                    title: const Text('Camera'),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: Color(0xFF666666), width: 0.5))),
                  child: ListTile(
                    onTap: () async {
                      try {
                        File picture = await pickImage(ImageSource.gallery);
                        if (picture.path.isNotEmpty) {
                          chosenPictures.add(picture);
                        }

                        setState(() {});
                        print(picture.path);
                      } catch (e) {
                        showSnackBar(context, 'Error in picking image');
                      }
                    },
                    leading: const Icon(
                      Icons.image,
                      color: Colors.grey,
                    ),
                    title: const Text('Picture/Video'),
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 20),
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: kPrimaryColor,
                          ),
                        )
                      : TextButton(
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                            });
                            if (chosenPictures.isEmpty) {
                              uploadPostFeed(
                                context,
                                PostModel(
                                  sender: {
                                    'uid': user!.uid,
                                    'name': currentUSer.name,
                                    'profile': currentUSer.profile ?? ''
                                  },
                                  postDate: DateTime.now(),
                                  message: controller.text,
                                  image: '',
                                ),
                              );
                            } else {
                              uploadImage(context, chosenPictures[0])
                                  .then((value) {
                                uploadPostFeed(
                                  context,
                                  PostModel(
                                    sender: {
                                      'uid': user!.uid,
                                      'name': currentUSer.name,
                                      'profile': currentUSer.profile ?? ''
                                    },
                                    postDate: DateTime.now(),
                                    message: controller.text,
                                    image: value,
                                  ),
                                );
                              });
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.0),
                            child: Text(
                              'Post',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          style: TextButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              primary: Colors.white),
                        ),
                )
              ]),
            ),
          ],
        ),
      )),
    );
  }

  Widget pictureBox({required File file, required VoidCallback onPressed}) {
    return Card(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: Image.file(
              file,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
              right: -5,
              top: -5,
              child: SizedBox(
                height: 25,
                width: 25,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.red,
                    shape: const CircleBorder(),
                  ),
                  onPressed: onPressed,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  Future<void> uploadPostFeed(BuildContext context, PostModel _post) async {
    try {
      final ref = firebaseFirestore.collection('Posts').doc();
      _post.postID = ref.id;
      ref.set(_post.toMap()).then((value) {
        setState(() {
          isLoading = false;
        });

        showSnackBar(context, 'Post Successful');
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Homescreen()));
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showSnackBar(context, 'Post upload failed');
    }
  }

  Future<String> uploadImage(BuildContext context, File file) async {
    FirebaseStorage storage = FirebaseStorage.instance;

    final fileName = basename(file.path);
    final destination = 'files/$fileName';
    try {
      final ref = storage.ref(destination).child('posts/');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, 'Couldn\'t upload image');
      rethrow;
    }
  }
}
