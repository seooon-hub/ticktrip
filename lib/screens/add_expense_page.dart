import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({Key? key}) : super(key: key);

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'KRW';
  bool _isLoading = false;
  Map<String, Map<String, String>> _currencies = {};

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currenciesJson = prefs.getString('currencies');
      final exchangeRatesJson = prefs.getString('exchangeRates');
      final savedCurrency = prefs.getString('selected_currency');
      
      if (currenciesJson != null) {
        final Map<String, dynamic> decoded = json.decode(currenciesJson);
        setState(() {
          _currencies = decoded.map((key, value) => 
            MapEntry(key, Map<String, String>.from(value)));
        });
        
        // 환율 데이터가 있는 통화만 필터링
        if (exchangeRatesJson != null) {
          final Map<String, dynamic> rates = json.decode(exchangeRatesJson);
          _currencies = Map.fromEntries(
            _currencies.entries.where((entry) => rates.containsKey(entry.key))
          );
        }
      }

      // 데이터가 없거나 비어있는 경우 기본값 설정
      if (_currencies.isEmpty) {
        setState(() {
          _currencies = {
            'KRW': {'name': '한국', 'symbol': 'KRW'},
            'USD': {'name': '미국', 'symbol': 'USD'},
            'JPY': {'name': '일본', 'symbol': 'JPY'},
            'EUR': {'name': '유럽연합', 'symbol': 'EUR'},
          };
        });
      }

      // 저장된 통화가 있으면 그것을 사용
      if (savedCurrency != null && _currencies.containsKey(savedCurrency)) {
        setState(() {
          _selectedCurrency = savedCurrency;
        });
      } else if (_currencies.containsKey('KRW')) {
        setState(() {
          _selectedCurrency = 'KRW';
        });
      } else if (_currencies.isNotEmpty) {
        setState(() {
          _selectedCurrency = _currencies.keys.first;
        });
      }
    } catch (e) {
      print('통화 정보 로드 오류: $e');
      setState(() {
        _currencies = {
          'KRW': {'name': '한국', 'symbol': 'KRW'},
        };
        _selectedCurrency = 'KRW';
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_titleController.text.trim().isEmpty || _amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 금액을 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다');

      await FirebaseFirestore.instance.collection('expenses').add({
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'memo': _memoController.text.trim(),
        'amount': double.parse(_amountController.text.replaceAll(',', '')),
        'currency': _selectedCurrency,
        'date': Timestamp.fromDate(_selectedDate),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      print('지출 저장 오류: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지출 저장에 실패했습니다')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          '지출 추가',
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
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveExpense,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                '',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: '사용처',
                filled: true,
                fillColor: const Color(0xFFE8E6E1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _memoController,
              decoration: InputDecoration(
                hintText: '내용',
                filled: true,
                fillColor: const Color(0xFFE8E6E1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E6E1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '날짜',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('yyyy. MM. dd').format(_selectedDate),
                          ),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '금액',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCurrency,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          items: _currencies.entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.key,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            if (value != null) {
                              setState(() => _selectedCurrency = value);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('selected_currency', value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _amountController.dispose();
    super.dispose();
  }
} 