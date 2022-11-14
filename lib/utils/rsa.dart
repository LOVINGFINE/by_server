import 'dart:io';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

class SecretRSA {
  /// @公钥
  RSAPublicKey get publicKey {
    return RSAKeyParser().parse(File('public.key').readAsStringSync())
        as RSAPublicKey;
  }

  /// @私钥
  RSAPrivateKey get privateKey {
    return RSAKeyParser().parse(File('private.key').readAsStringSync())
        as RSAPrivateKey;
  }

  String enCode(value) {
    return Encrypter(RSA(publicKey: publicKey, privateKey: privateKey))
        .encrypt(value)
        .base64;
  }

  String? deCode(String key) {
    try {
      return Encrypter(RSA(publicKey: publicKey, privateKey: privateKey))
          .decrypt64(key);
    } catch (e) {
      return null;
    }
  }
}
