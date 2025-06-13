import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class LocalStorage {
  static const _expiryDays = 7;
  static const _userDataFileName = 'user_data.enc';
  static final _key = encrypt.Key.fromLength(32);
  static final _iv = encrypt.IV.fromLength(16);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  // 파일 경로 생성 유틸리티
  static Future<String> _getFilePath(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/$fileName';
    } catch (e) {
      print('문서 디렉토리 접근 실패: $e');
      // 임시 디렉토리로 폴백
      final tempDir = await getTemporaryDirectory();
      return '${tempDir.path}/$fileName';
    }
  }

  // 파일 암호화
  static String _encryptData(String data) {
    return _encrypter.encrypt(data, iv: _iv).base64;
  }

  // 파일 복호화
  static String _decryptData(String encryptedData) {
    return _encrypter.decrypt64(encryptedData, iv: _iv);
  }

  // 파일 저장
  static Future<void> saveFile(String fileName, String data) async {
    try {
      final file = File(await _getFilePath(fileName));
      final timestamp = DateTime.now().toIso8601String();
      final dataWithTimestamp = {
        'timestamp': timestamp,
        'data': data,
      };
      final encryptedData = _encryptData(jsonEncode(dataWithTimestamp));
      await file.writeAsString(encryptedData);
      print('파일 저장 성공: ${file.path}');
    } catch (e) {
      print('파일 저장 실패: $e');
      rethrow;
    }
  }

  // 파일 읽기
  static Future<String?> readFile(String fileName) async {
    try {
      final file = File(await _getFilePath(fileName));
      if (!await file.exists()) {
        print('파일이 존재하지 않음: $fileName');
        return null;
      }

      final encryptedContent = await file.readAsString();
      final decryptedContent = _decryptData(encryptedContent);
      final contentMap = jsonDecode(decryptedContent) as Map<String, dynamic>;

      final timestamp = DateTime.parse(contentMap['timestamp'] as String);
      if (DateTime.now().difference(timestamp).inDays > _expiryDays) {
        print('파일 만료됨: $fileName');
        await deleteFile(fileName);
        return null;
      }

      return contentMap['data'] as String;
    } catch (e) {
      print('파일 읽기 오류: $e');
      return null;
    }
  }

  // 파일 삭제
  static Future<void> deleteFile(String fileName) async {
    final file = File(await _getFilePath(fileName));
    if (await file.exists()) {
      await file.delete();
    }
  }

  // 만료된 파일 정리
  static Future<void> cleanExpiredFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();

      for (var fileEntity in files) {
        if (fileEntity is File) {
          try {
            final content = await fileEntity.readAsString();
            final decryptedContent = _decryptData(content);
            final timestamp = DateTime.parse(decryptedContent.split('|')[0]);

            if (DateTime.now().difference(timestamp).inDays > _expiryDays) {
              await fileEntity.delete();
              print('만료된 파일 삭제됨: ${fileEntity.path}');
            }
          } catch (e) {
            // 복호화 실패한 파일은 삭제
            await fileEntity.delete();
            print('잘못된 형식의 파일 삭제됨: ${fileEntity.path}');
          }
        }
      }
    } catch (e) {
      print('파일 정리 중 오류 발생: $e');
    }
  }

  // 파일 해시 생성
  static String _createFileHash(String content) {
    final bytes = utf8.encode(content);
    return sha256.convert(bytes).toString();
  }

  // 파일 무결성 검증
  static bool _verifyFileIntegrity(String content, String storedHash) {
    final currentHash = _createFileHash(content);
    return currentHash == storedHash;
  }

  // 사용자 데이터 저장
  static Future<void> saveUserData(String email, String password) async {
    try {
      final userData = {
        'email': email,
        'password': password,
      };
      await saveFile(_userDataFileName, jsonEncode(userData));
      print('사용자 데이터 저장 완료');
    } catch (e) {
      print('사용자 데이터 저장 실패: $e');
      rethrow;
    }
  }

  // 오프라인 로그인 검증
  static Future<bool> verifyOfflineLogin(String email, String password) async {
    try {
      final data = await readFile(_userDataFileName);
      if (data == null) {
        print('저장된 사용자 데이터 없음');
        return false;
      }

      final userData = jsonDecode(data) as Map<String, dynamic>;
      final savedEmail = userData['email'] as String;
      final savedPassword = userData['password'] as String;

      print('오프라인 로그인 검증: ${savedEmail == email}');
      return savedEmail == email && savedPassword == password;
    } catch (e) {
      print('오프라인 로그인 검증 실패: $e');
      return false;
    }
  }

  // 네트워크 연결 확인
  static Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
