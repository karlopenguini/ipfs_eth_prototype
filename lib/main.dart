// ignore_for_file: unused_import

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prototype/document_controller.dart';
import 'package:ipfs_client_flutter/ipfs_client_flutter.dart';
import 'dart:convert' as convert;

import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? imageToUpload;

  String? ipfsURL;

  String status = "Waiting";

  Future pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final imageTemp = File(image.path);

      setState(() => imageToUpload = imageTemp);
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future pickImageC() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);

      if (image == null) return;

      final imageTemp = File(image.path);

      setState(() => imageToUpload = imageTemp);

      print(imageTemp.path);
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  void sendDocument() async {
    DocumentController documentController = DocumentController();
    await documentController.init();
    // upload hash to eth
    //Make Directory
    await CreateDirectory("/documents");

    String hash = await WriteFile(
        "/documents/${imageToUpload!.path.split('/').last}",
        imageToUpload!.path,
        imageToUpload!.path.split('/').last);

    String? generatedHashCode = convert.jsonDecode(hash)["Hash"];

    setState(() {
      status = generatedHashCode!;
    });
    await documentController.addDocument(generatedHashCode!);
    setState(() => imageToUpload = null); // resets image container
  }

  Future<String> WriteFile(
      String dirName, String filePath, String fileName) async {
    Uri writeURI = Uri(
      port: 5001,
      scheme: "http",
      path: "api/v0/add",
      host: "10.0.2.2",
      queryParameters: {
        'arg': dirName,
      },
    );

    print("WRITE URL: $writeURI");
    var request = http.MultipartRequest('POST', writeURI);

    var stream = http.ByteStream(imageToUpload!.openRead());
    stream.cast();
    var length = await imageToUpload!.length();

    var multiport = http.MultipartFile('image', stream, length);

    request.files.add(multiport);

    var response = await request.send();

    var reqResponse = await http.Response.fromStream(response);

    print(response.reasonPhrase);
    return reqResponse.body;
  }

  Future<void> CreateDirectory(String dirName) async {
    Uri mkDirURI = Uri(
      port: 5001,
      scheme: "http",
      path: "api/v0/files/mkdir",
      host: "10.0.2.2",
      queryParameters: {'arg': dirName, "parents": "true"},
    );
    var url = mkDirURI;

    print("MKDIR URL: $url");
    var response = await http.post(mkDirURI);
    print(response.reasonPhrase);
  }

  void getDocument() async {
    String? ipfsHASH;

    // transact eth network
    // get hash from eth network
    // get image from IPFS using hash
    DocumentController documentController = DocumentController();
    await documentController.init();
    final retrievedDocument = await documentController.getDocument();

    ipfsHASH = retrievedDocument.hash;

    setState(
        () => ipfsURL = "http://10.0.2.2:8080/ipfs/$ipfsHASH"); // set image url
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Image Picker Example"),
        ),
        body: Center(
          child: Column(
            children: [
              MaterialButton(
                  color: Colors.blue,
                  child: const Text("Pick Image from Gallery",
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    pickImage();
                  }),
              MaterialButton(
                  color: Colors.blue,
                  child: const Text("Pick Image from Camera",
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    pickImageC();
                  }),
              Expanded(
                  child: imageToUpload != null
                      ? Image.file(imageToUpload!)
                      : const Text("No image selected")),
              Expanded(
                  child:
                      ipfsURL != null ? Image.network(ipfsURL!) : Text(status)),
              Center(
                  child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MaterialButton(
                    color: Colors.orange,
                    child: const Text("SEND"),
                    onPressed: () {
                      sendDocument();
                    },
                  ),
                  MaterialButton(
                    color: Colors.orange,
                    child: const Text("GET"),
                    onPressed: () {
                      getDocument();
                    },
                  ),
                ],
              )),
            ],
          ),
        ));
  }
}
