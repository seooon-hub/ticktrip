import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmergencyContactsPage extends StatefulWidget {
  final String countryCode;

  const EmergencyContactsPage({required this.countryCode});

  @override
  _EmergencyContactsPageState createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  dynamic _selectedCountryData;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchEmergencyContacts(widget.countryCode);
    // 빌드 완료 후 경고창 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOfflineWarning();
    });
  }

  Future<void> _showOfflineWarning() async {
    await showDialog(
      context: context,
      barrierDismissible: false,  // 배경 탭으로 닫기 방지
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '알림',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '오프라인 환경에서도 비상연락처를\n확인할 수 있도록 화면을 캡처하여\n저장하시기 바랍니다.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '확인',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchEmergencyContacts(String countryCode) async {
    final String apiKey = "iIMYvrawp6wVusc2zNGvUumDfoEldY6BWgft9eGYVvM7okEeabkqDpCvlUHYxnjBuUlUFVQAfYYccvmZjnXsjQ=="; // 실제 API 키로 교체하세요.
    final String baseUrl = "http://apis.data.go.kr/1262000/LocalContactService2/getLocalContactList2";

    // URL 쿼리 파라미터 구성
    Map<String, String> queryParameters = {
      "ServiceKey": apiKey,
      "pageNo": "1",
      "numOfRows": "10",
      "cond[country_iso_alp2::EQ]": countryCode,
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedCountryData = null;
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['response']?['body']?['items']?['item'];

        print('Decoded response data: $data');

        if (items != null && items.isNotEmpty) {
          setState(() {
            _selectedCountryData = items[0]; // 첫 번째 아이템을 선택
          });
        } else {
          setState(() {
            _errorMessage = "선택된 국가에 대한 데이터가 없습니다.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "데이터를 불러오지 못했습니다. 오류 코드: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "오류가 발생했습니다: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("비상 연락처"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            if (_selectedCountryData != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Card(
                        elevation: 4.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${_selectedCountryData['country_nm']} (${_selectedCountryData['country_eng_nm']})",
                                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              if (_selectedCountryData['flag_download_url'] != null)
                                Image.network(_selectedCountryData['flag_download_url'], height: 60, width: 100),
                              SizedBox(height: 10),
                              if (_selectedCountryData['contact_remark'] != null)
                                Text(
                                  _selectedCountryData['contact_remark']
                                      .toString()
                                      .replaceAll(RegExp(r'<[^>]*>'), ''), // HTML 태그 제거
                                  style: TextStyle(fontSize: 18),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
