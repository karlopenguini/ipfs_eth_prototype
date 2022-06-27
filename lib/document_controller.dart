// ignore_for_file: unused_import

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';
import 'document_model.dart';

class DocumentController extends ChangeNotifier {
  final String _rpcUrl = "http://10.0.2.2:7545";
  final String _wsUrl = "ws://10.0.2.2:7545/";

  final String _privateKey =
      "adf9bd4c3263a5f73faf55af6c05382f84c585c274e9099e32c58f939e3b3dc4";

  Web3Client? _client;
  String? _abiCode;

  Credentials? _credentials;
  EthereumAddress? _contractAddress;
  DeployedContract? _contract;

  ContractFunction? _sendHash;
  ContractFunction? _getHash;

  bool isLoading = true;

  init() async {
    _client = Web3Client(_rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(_wsUrl).cast<String>();
    });

    await getAbi();
    await getDeployedContract();
  }

  Future<void> getAbi() async {
    String abiStringFile =
        await rootBundle.loadString("contracts/build/contracts/IPFS.json");

    print(abiStringFile);
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi['abi']);
    _contractAddress =
        EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);
  }

  Future<void> getDeployedContract() async {
    _contract = DeployedContract(
        ContractAbi.fromJson(_abiCode!, "NotesContract"), _contractAddress!);
    _sendHash = _contract?.function("sendHash");
    _getHash = _contract?.function("getHash");
  }

  Future<Document> getDocument() async {
    var temp = await _client
        ?.call(contract: _contract!, function: _getHash!, params: []);

    isLoading = false;
    notifyListeners();
    return Document(hash: temp![0]);
  }

  addDocument(String hash) async {
    isLoading = true;
    notifyListeners();
    await _client?.sendTransaction(
        EthPrivateKey.fromHex(_privateKey),
        Transaction.callContract(
            contract: _contract!, function: _sendHash!, parameters: [hash]));

    isLoading = false;
    notifyListeners();
  }
}
