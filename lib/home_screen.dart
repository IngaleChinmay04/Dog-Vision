import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image/image.dart' as img;
import 'package:tflite_v2/tflite_v2.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker imagePicker = ImagePicker();
  XFile? _image;
  String _result = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadModel().then((_) => print("Model loaded"));
  }

  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: "assets/dog_breed_classifier.tflite",
      labels: "assets/labels.txt",
    );
  }

  // Future<String> processImage(File image) async {
  //   const IMG_SIZE = 224;
  //
  //   // Read the image file
  //   final bytes = await image.readAsBytes();
  //   final bytesImage = img.decodeImage(bytes);
  //
  //   if (bytesImage == null) {
  //     throw Exception("Unable to decode the image!!");
  //   }
  //   // Convert image to grayscale
  //   final grayScaleImage = img.grayscale(bytesImage);
  //
  //   // Resize the image
  //   final resizedImage = img.copyResize(grayScaleImage, width: IMG_SIZE, height: IMG_SIZE);
  //
  //   // Save the processed image to a temporary file
  //   final tempDir = await getTemporaryDirectory();
  //   final tempPath = path.join(tempDir.path, 'processed_image.png');
  //   final processedFile = File(tempPath)..writeAsBytesSync(img.encodePng(resizedImage));
  //
  //   return processedFile.path;
  // }

  Future<void> classifyImage(File image) async {
    setState(() {
      _isLoading = true;
    });
    try {
      var recognitions = await Tflite.runModelOnImage(
        path: image.path,
        imageMean: 127.5,
        imageStd: 127.5,
        numResults: 1,
        threshold: 0.5,
      );
      setState(() {
        _result = recognitions!.isNotEmpty ? recognitions.first['label'] : "Could not classify the image";
      });
    } catch (e) {
      setState(() {
        _result = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> getImageFromGallery() async {
    try {
      final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
      setState(() {
        _image = pickedFile;
      });
      if (_image != null) {
        await classifyImage(File(_image!.path));
      }
    } catch (e) {
      setState(() {
        _result = "Error picking image: $e";
      });
    }
  }

  Future<void> getImageFromCamera() async {
    try {
      final pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
      setState(() {
        _image = pickedFile;
      });
      if (_image != null) {
        await classifyImage(File(_image!.path));
      }
    } catch (e) {
      setState(() {
        _result = "Error capturing image: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF343434),
      appBar: AppBar(
        backgroundColor: Colors.tealAccent,
        title: const Text('Dog Vision',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 25),),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Dog Vision',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Use your camera or upload a photo to identify your dog\'s breed!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            _image == null
                ? Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey),
              ),
              child:  Center(
                child: Image.asset("assets/img.png",fit: BoxFit.cover,),
              ),
            )
                : Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.file(File(_image!.path), fit: BoxFit.cover),
              )
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: getImageFromGallery,
              icon: const Icon(Icons.photo,color: Colors.black,),
              label: const Text('Upload a Photo',style: TextStyle(color: Colors.black),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                textStyle: const TextStyle(fontSize: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: getImageFromCamera,
              icon: const Icon(Icons.camera_alt,color: Colors.black,),
              label: const Text('Take a Picture',style: TextStyle(color: Colors.black),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                textStyle: const TextStyle(fontSize: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Center(
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        borderRadius:  BorderRadius.circular(25),
                        color: Colors.tealAccent
                    ),
                    child: Text(
                  "The Breed Of Your Dog is: $_result",
                  style: const TextStyle(fontSize: 20,fontWeight: FontWeight.bold),
                    ),
                  ),
                )
          ],
        ),
      ),
    );
  }
}
