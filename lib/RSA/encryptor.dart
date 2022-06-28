import 'dart:typed_data';
import "package:pointycastle/export.dart";
import 'common.dart';

Uint8List rsaSign(RSAPrivateKey privateKey, Uint8List dataToSign) {
  //final signer = Signer('SHA-256/RSA'); // Get using registry
  final signer = RSASigner(SHA256Digest(), '0609608648016503040201');

  // initialize with true, which means sign
  signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

  final sig = signer.generateSignature(dataToSign);

  return sig.bytes;
}

Uint8List rsaEncrypt(RSAPublicKey myPublic, Uint8List dataToEncrypt) {
  final encryptor = OAEPEncoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(myPublic)); // true=encrypt

  return processInBlocks(encryptor, dataToEncrypt);
}
