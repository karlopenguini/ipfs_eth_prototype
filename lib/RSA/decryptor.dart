import 'dart:typed_data';
import 'common.dart';
import "package:pointycastle/export.dart";

bool rsaVerify(
    RSAPublicKey publicKey, Uint8List signedData, Uint8List signature) {
  //final signer = Signer('SHA-256/RSA'); // Get using registry
  final sig = RSASignature(signature);

  final verifier = RSASigner(SHA256Digest(), '0609608648016503040201');

  // initialize with false, which means verify
  verifier.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

  try {
    return verifier.verifySignature(signedData, sig);
  } on ArgumentError {
    return false; // for Pointy Castle 1.0.2 when signature has been modified
  }
}

Uint8List rsaDecrypt(RSAPrivateKey myPrivate, Uint8List cipherText) {
  final decryptor = OAEPEncoding(RSAEngine())
    ..init(
        false, PrivateKeyParameter<RSAPrivateKey>(myPrivate)); // false=decrypt

  return processInBlocks(decryptor, cipherText);
}
