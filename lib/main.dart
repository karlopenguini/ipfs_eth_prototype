// ignore_for_file: unused_import
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prototype/RSA/decryptor.dart';
import 'package:prototype/RSA/encryptor.dart';
import 'package:prototype/RSA/generator.dart';
import 'package:prototype/ethereum/document_model.dart';
import 'ethereum/document_controller.dart';
import 'package:ipfs_client_flutter/ipfs_client_flutter.dart';
import 'dart:convert' as convert;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:uri_to_file/uri_to_file.dart';

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

  File? decryptedImage;

  String? ipfsURL;

  String status = "Waiting";

  Future<String> WriteFile(
      String dirName, Uint8List encryptedImage, String fileName) async {
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

    var stream =
        http.ByteStream(Stream.fromIterable(encryptedImage.map((e) => [e])));
    stream.cast();
    var length = encryptedImage.length;

    var multiport = http.MultipartFile('file', stream, length);

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

//#################################################################################################

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
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  User sender = User();
  User reciever = User();

  Uint8List? signatureOfSender;

  void sendDocument() async {
    DocumentController documentController = DocumentController();
    await documentController.init();
    await CreateDirectory("/documents");

    Uint8List encryptedImage =
        rsaEncrypt(reciever.publicKey!, await imageToUpload!.readAsBytes());

    setState(() {
      signatureOfSender = rsaSign(sender.privateKey!, encryptedImage);
    });

    String hash = await WriteFile(
        "/documents/${imageToUpload!.path.split('/').last.split('.').last}.txt",
        encryptedImage,
        imageToUpload!.path.split('/').last.split('.').last);

    String? generatedHashCode = convert.jsonDecode(hash)["Hash"];
    setState(() {
      status = generatedHashCode!;
    });
    await documentController.addDocument(generatedHashCode!);
  }

  void getDocument() async {
    String? ipfsHASH;
    DocumentController documentController = DocumentController();
    await documentController.init();
    final retrievedDocument = await documentController.getDocument();
    ipfsHASH = retrievedDocument.hash;
    setState(() => ipfsURL = "http://10.0.2.2:8080/ipfs/$ipfsHASH");

    Uri ipfsURI = Uri(
      port: 8080,
      scheme: "http",
      path: "ipfs/$ipfsHASH",
      host: "10.0.2.2",
    );

    final response = await http.get(
      ipfsURI,
      headers: {"Content-Type": "application/json"},
    );

    print(response.reasonPhrase);

    Uint8List imageInBytes = response.bodyBytes;
    Uint8List? decryptedImageBytes =
        rsaVerify(sender.publicKey!, imageInBytes, signatureOfSender!)
            ? rsaDecrypt(reciever.privateKey!, imageInBytes)
            : null;

    File imageFromIPFS =
        await imageToUpload!.writeAsBytes(decryptedImageBytes!);

    setState(() {
      decryptedImageBytes != null ? decryptedImage = imageFromIPFS : null;
    });
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
              const Text("THIS IS FROM IPFS"),
              Expanded(
                  child: decryptedImage != null
                      ? Image.file(decryptedImage!)
                      : Text(status)),
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

class User {
  User() {
    final pair = generateRSAkeyPair(exampleSecureRandom());
    publicKey = pair.publicKey;
    privateKey = pair.privateKey;
  }
  RSAPublicKey? publicKey;
  RSAPrivateKey? privateKey;
}
