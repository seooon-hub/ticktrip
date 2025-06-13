import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ticktrip/screens/add_expense_page.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

// 전역 변수로 currencies 정의
Map<String, Map<String, String>> currencies = {};

class ExchangeRate {
  final String currency; // 통화
  final String exchangeRate; // 환율
  final String country; // 국가명

  ExchangeRate({
    required this.currency,
    required this.exchangeRate,
    required this.country,
  });
}

class ExpensePage extends StatefulWidget {
  static Map<String, Map<String, String>> currencies = {}; // Make it static

  const ExpensePage({Key? key}) : super(key: key);

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

// 날짜별 지출 데이터 구조체
class DailyExpense {
  final DateTime date;
  final List<Map<String, dynamic>> expenses;
  double get totalAmount =>
      expenses.fold(0, (sum, expense) => sum + (expense['amount'] as num));

  DailyExpense({required this.date, required this.expenses});
}

class _ExpensePageState extends State<ExpensePage> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  Map<String, double> _exchangeRates = {};
  String? _selectedCurrency; // 초기값은 null로 설정

  // 통화 정보
  final Map<String, Map<String, String>> currencies = {};

  final _krwController = TextEditingController(text: '0');
  final _foreignController = TextEditingController(text: '0');
  bool _isUpdatingKRW = false; // 동시 업데이트 방지를 위한 플래그
  bool _isUpdatingForeign = false;

  // 선택된 항목을 저장할 Set 추가
  final Set<String> _selectedItems = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _krwController.addListener(_handleKRWChanged);
    _foreignController.addListener(_handleForeignChanged);
    _initializeCurrencies();
  }

  // currencies 초기화 함수 수정
  Future<void> _initializeCurrencies() async {
    print('=== 통화 초기화 시작 ===');

    // API 호출 시도
    try {
      print('API 호출 시작...');
      await fetchExchangeRates();

      // API 호출 후 currencies가 채워졌는지 확인
      if (currencies.isNotEmpty) {
        print('API 호출 성공: ${currencies.length}개 통화 로드됨');
        // 첫 번째로 사용 가능한 통화를 기본값으로 설정
        setState(() {
          _selectedCurrency = currencies.keys.first;
        });
        return; // API 호출이 성공하면 여기서 함수 종료
      }
    } catch (e) {
      print('API 호출 실패: $e');
    }

    // API 호출이 실패한 경우에만 기본값 설정
    print('기본 통화 정보 설정...');
    currencies['USD'] = {
      'name': '미국',
      'symbol': 'USD',
    };
    currencies['JPY'] = {
      'name': '일본',
      'symbol': 'JPY',
    };
    currencies['EUR'] = {
      'name': '유럽연합',
      'symbol': 'EUR',
    };

    setState(() {
      _selectedCurrency = 'USD';
    });

    print('최종 currencies 상태: $currencies');
    print('최종 환율 데이터: $_exchangeRates');
    print('=== 통화 초기화 완료 ===');
  }

  // 환율 데이터를 로드하는 함수 수정
  Future<void> _loadExchangeRates() async {
    print('--- 환율 데이터 로드 시작 ---');
    final prefs = await SharedPreferences.getInstance();
    final lastFetchTime = prefs.getString('lastFetchTime');
    final now = DateTime.now();

    if (lastFetchTime != null) {
      print('마지막 업데이트: $lastFetchTime');
      print(
          '경과 시간: ${now.difference(DateTime.parse(lastFetchTime)).inHours}시간');
    } else {
      print('첫 실행: 저장된 데이터 없음');
    }

    // 마지막 호출 시간이 없거나 하루가 지났다면 API 호출
    if (lastFetchTime == null ||
        now.difference(DateTime.parse(lastFetchTime)).inDays >= 1) {
      print('API 호출 필요: 새로운 환율 데이터 요청');
      await fetchExchangeRates();
    } else {
      print('저장된 환율 데이터 사용');
      final savedRates = prefs.getString('exchangeRates');
      if (savedRates != null) {
        final Map<String, dynamic> ratesMap = jsonDecode(savedRates);
        setState(() {
          _exchangeRates =
              ratesMap.map((key, value) => MapEntry(key, value.toDouble()));
        });
        print('저장된 환율 데이터 로드 완료: $_exchangeRates');
      } else {
        print('저장된 환율 데이터 없음');
      }
    }
    print('--- 환율 데이터 로드 완료 ---');
  }

  // HttpClient 생성 함수 추가
  HttpClient _createHttpClient() {
    final client = HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true; // 모든 인증서 허용
    return client;
  }

  // fetchExchangeRates 함수 수정
  Future<void> fetchExchangeRates() async {
    print('>>> API 호출 시작');
    try {
      final client = _createHttpClient(); // 수정된 HttpClient 사용

      String authKey = 'wGOD6vK3y6CUrPf9AHz5ZbwWAJ2yHuC5';
      String searchDate = DateTime.now().toIso8601String().split('T')[0];
      String dataType = 'AP01';

      final url = Uri.parse(
          'https://www.koreaexim.go.kr/site/program/financial/exchangeJSON');

      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');

      // 요청 본문 작성
      String body = 'authkey=$authKey&searchdate=$searchDate&data=$dataType';
      request.write(body);

      print('API 요청 전송...');
      final response = await request.close();

      // 리다이렉션 처리
      if (response.statusCode == 302) {
        final redirectedUrl = response.headers['location']?.first;
        if (redirectedUrl != null) {
          print('리다이렉션 발생: $redirectedUrl');
          final redirectedRequest = await client
              .postUrl(Uri.parse('https://www.koreaexim.go.kr$redirectedUrl'));
          redirectedRequest.headers
              .set('Content-Type', 'application/x-www-form-urlencoded');
          final redirectedResponse = await redirectedRequest.close();
          await _handleResponse(redirectedResponse);
        } else {
          throw Exception('리다이렉션 URL을 찾을 수 없습니다.');
        }
      } else if (response.statusCode == 200) {
        print('API 응답 성공: ${response.statusCode}');
        await _handleResponse(response);
      } else {
        print('API 호출 실패: ${response.statusCode}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('API 호출 오류: $e');
      rethrow;
    } finally {
      print('<<< API 호출 종료');
    }
  }

  // 응답 처리 함수
  Future<void> _handleResponse(HttpClientResponse response) async {
    final responseBody = await response.transform(utf8.decoder).join();
    List<dynamic> data = jsonDecode(responseBody);

    // 응답 결과 확인
    if (data.isNotEmpty && data[0]['result'] == 1) {
      // 필요한 데이터만 추출
      List<ExchangeRate> exchangeRates = data.map<ExchangeRate>((item) {
        return ExchangeRate(
          currency: item['cur_unit'] ?? 'N/A', // 통화코드
          exchangeRate: item['deal_bas_r']?.toString() ?? '0', // 매매 기준율
          country: item['cur_nm'] ?? '알 수 없음', // 국가/통화명
        );
      }).toList();

      // 결과 출력
      for (var rate in exchangeRates) {
        print(
            '통화: ${rate.currency}, 환율: ${rate.exchangeRate}, 국가명: ${rate.country}');

        // currencies 맵에 데이터 추가
        currencies[rate.currency] = {
          'name': rate.country,
          'symbol': rate.currency,
        };
      }

      // 디버깅 로그: currencies 맵 출력
      print('Updated currencies: $currencies');

      // 환율 데이터 업데이트
      Map<String, double> newRates = {};
      for (var rate in exchangeRates) {
        try {
          double rateValue =
              double.parse(rate.exchangeRate.replaceAll(',', ''));
          newRates[rate.currency] = rateValue;
        } catch (e) {
          print('환율 변환 오류: ${rate.currency} - ${rate.exchangeRate}');
        }
      }

      setState(() {
        _exchangeRates = newRates;
      });

      // 환율 데이터를 SharedPreferences에 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('exchangeRates', jsonEncode(_exchangeRates));
    } else {
      print('API 요청 실패: ${data.isNotEmpty ? data[0]['result'] : '응답 없음'}');
    }
  }

  void _handleKRWChanged() {
    if (_isUpdatingForeign) return;
    _isUpdatingKRW = true;
    try {
      String value = _krwController.text.replaceAll(',', '');
      if (value.isEmpty) value = '0';

      final krw = double.parse(value);
      final rateString = _exchangeRates[_selectedCurrency]?.toString() ??
          '1.0'; // 선택된 통화의 환율 가져오기
      final rate =
          double.parse(rateString.replaceAll(',', '')); // 문자열을 double로 변환
      final foreign = (krw / rate).toDouble();

      // 디버깅 로그
      print('KRW: $krw, Rate: $rate, Foreign: $foreign');

      // 소수점 둘째자리까지 표시
      _foreignController.text = foreign.toStringAsFixed(2);
    } catch (e) {
      print('KRW 변환 오류: $e');
      _foreignController.text = '0.00';
    }
    _isUpdatingKRW = false;
  }

  void _handleForeignChanged() {
    if (_isUpdatingKRW) return;
    _isUpdatingForeign = true;
    try {
      String value = _foreignController.text.replaceAll(',', '');
      if (value.isEmpty) value = '0';

      final foreign = double.parse(value);
      final rateString = _exchangeRates[_selectedCurrency]?.toString() ??
          '1.0'; // 선택된 통화의 환율 가져오기
      final rate =
          double.parse(rateString.replaceAll(',', '')); // 문자열을 double로 변환
      final krw = (foreign * rate).toDouble();

      // 디버깅 로그
      print('Foreign: $foreign, Rate: $rate, KRW: $krw');

      // 정수로 표시
      _krwController.text = krw.round().toString();
    } catch (e) {
      print('Foreign 변환 오류: $e');
      _krwController.text = '0';
    }
    _isUpdatingForeign = false;
  }

  // 통화 선택 다이얼로그
  Future<void> _showCurrencyPicker() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('통화 선택'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.entries.map((entry) {
              return ListTile(
                title: Text('${entry.value['name']} (${entry.key})'),
                onTap: () {
                  setState(() {
                    _selectedCurrency = entry.key;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // 지출 목록을 날짜별로 그룹화하는 함수
  List<DailyExpense> _groupExpensesByDate(
      List<QueryDocumentSnapshot> expenses) {
    final groupedExpenses = <String, List<Map<String, dynamic>>>{};

    for (var doc in expenses) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      if (!groupedExpenses.containsKey(dateStr)) {
        groupedExpenses[dateStr] = [];
      }
      groupedExpenses[dateStr]!.add({...data, 'id': doc.id});
    }

    return groupedExpenses.entries.map((entry) {
      return DailyExpense(
        date: DateFormat('yyyy-MM-dd').parse(entry.key),
        expenses: entry.value,
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // 선택 모드 토글 함수
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedItems.clear();
    });
  }

  // 항목 선택/해제 함수
  void _toggleItemSelection(String id) {
    setState(() {
      if (_selectedItems.contains(id)) {
        _selectedItems.remove(id);
      } else {
        _selectedItems.add(id);
      }

      if (_selectedItems.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  // 선택된 항목 삭제 함수
  Future<void> _deleteSelectedItems() async {
    try {
      for (String id in _selectedItems) {
        await FirebaseFirestore.instance
            .collection('expenses')
            .doc(id)
            .delete();
      }

      setState(() {
        _isSelectionMode = false;
        _selectedItems.clear();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 항목이 삭제되었습니다')),
      );
    } catch (e) {
      print('삭제 오류: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제 중 오류가 발생했습니다')),
      );
    }
  }

  // 날짜별 모든 항목 삭제 함수
  Future<void> _deleteDailyExpenses(List<Map<String, dynamic>> expenses) async {
    try {
      for (var expense in expenses) {
        await FirebaseFirestore.instance
            .collection('expenses')
            .doc(expense['id'])
            .delete();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('해당 날짜의 모든 지출이 삭제되었습니다')),
      );
    } catch (e) {
      print('날짜별 삭제 오류: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제 중 오류가 발생했습니다')),
      );
    }
  }

  // 지출 목록 UI 수정
  Widget _buildExpenseList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('오류가 발생했습니다'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = snapshot.data?.docs ?? [];
        final groupedExpenses = _groupExpensesByDate(expenses);

        if (groupedExpenses.isEmpty) {
          return const Center(child: Text('지출 내역이 없습니다'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedExpenses.length,
          itemBuilder: (context, index) {
            final dailyExpense = groupedExpenses[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              DateFormat('MM/dd').format(dailyExpense.date),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '총 ${NumberFormat('#,###').format(dailyExpense.totalAmount)}원',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (_isSelectionMode)
                              TextButton(
                                onPressed: _deleteSelectedItems,
                                child: Text(
                                  '삭제 (${_selectedItems.length})',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => _showDeleteConfirmDialog(
                                    dailyExpense.expenses),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ...dailyExpense.expenses
                      .map((expense) => InkWell(
                            onLongPress: () {
                              if (!_isSelectionMode) {
                                _toggleSelectionMode();
                                _toggleItemSelection(expense['id']);
                              }
                            },
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleItemSelection(expense['id']);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _selectedItems.contains(expense['id'])
                                    ? Colors.blue.shade50
                                    : null,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (_isSelectionMode)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Icon(
                                        _selectedItems.contains(expense['id'])
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          expense['title'] as String,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (expense['memo']?.isNotEmpty ??
                                            false)
                                          Text(
                                            expense['memo'] as String,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '-${NumberFormat('#,###').format(expense['amount'])}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        expense['currency'],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 삭제 확인 다이얼로그
  Future<void> _showDeleteConfirmDialog(
      List<Map<String, dynamic>> expenses) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('해당 날짜의 모든 지출을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDailyExpenses(expenses);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 도움말 다이얼로그 표시
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 기능 안내'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('1. 개별 항목 선택 삭제',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• 항목을 길게 누르면 선택 모드가 활성화됩니다'),
            Text('• 여러 항목을 선택할 수 있습니다'),
            Text('• 선택된 항목은 파란색으로 표시됩니다'),
            Text('• 상단의 삭제 버튼으로 선택한 항목을 삭제합니다'),
            SizedBox(height: 16),
            Text('2. 날짜별 전체 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• 날짜 옆의 삭제 아이콘을 누릅니다'),
            Text('• 해당 날짜의 모든 지출이 삭제됩니다'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 현재 선택된 통화의 환율
    final currentRate = _exchangeRates[_selectedCurrency] ?? 0.0;
    final currencyInfo = currencies[_selectedCurrency];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'PAY',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '한국(KRW)',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,##0.00').format(currentRate)}원',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    '=',
                    style: TextStyle(fontSize: 24),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _showCurrencyPicker,
                        child: Row(
                          children: [
                            Text(
                              '${currencyInfo?['name']}($_selectedCurrency)',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                      Text(
                        '1 ${currencyInfo?['symbol']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 환율 계산기 추가
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        'KRW',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _krwController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: false),
                          textAlign: TextAlign.end,
                          decoration: const InputDecoration(
                            hintText: '0',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          style: const TextStyle(fontSize: 18),
                          onChanged: (value) {
                            if (!_isUpdatingKRW) {
                              _handleKRWChanged();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('원'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedCurrency ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _foreignController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.end,
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          style: const TextStyle(fontSize: 18),
                          onChanged: (value) {
                            if (!_isUpdatingForeign) {
                              _handleForeignChanged();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(currencies[_selectedCurrency]?['symbol'] ?? ''),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 지출 목록
            Expanded(
              child: _buildExpenseList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpensePage()),
          );
          if (result == true) {
            // 지출이 추가되면 스낵바 표시
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('지출이 추가되었습니다')),
            );
          }
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _krwController.dispose();
    _foreignController.dispose();
    super.dispose();
  }
}
