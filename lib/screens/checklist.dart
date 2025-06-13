import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChecklistItem {
  String id;
  String content;
  bool isChecked;
  late TextEditingController controller;

  ChecklistItem({
    required this.id,
    required this.content,
    this.isChecked = false,
  }) {
    controller = TextEditingController(text: content);
  }
}

class ContainerData {
  String id;
  String date;
  List<ChecklistItem> items;
  late TextEditingController controller;

  ContainerData({
    required this.id,
    required this.date,
    required this.items,
  }) {
    controller = TextEditingController(text: date);
  }
}

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({Key? key}) : super(key: key);

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  List<ContainerData> _containers = [];

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _addContainer() async {
    final newContainer = ContainerData(
      id: DateTime.now().toString(),
      date: '',
      items: [
        ChecklistItem(
          id: DateTime.now().toString(),
          content: '',
        )
      ],
    );

    setState(() {
      _containers.add(newContainer);
    });

    await _saveChecklist();
  }

  Future<void> _deleteContainer(String containerId) async {
    setState(() {
      _containers.removeWhere((container) => container.id == containerId);
    });

    await _saveChecklist();
  }

  Future<void> _addItem(ContainerData container) async {
    final newItem = ChecklistItem(
      id: DateTime.now().toString(),
      content: '',
    );

    setState(() {
      container.items.add(newItem);
    });

    await _saveChecklist();
  }

  Future<void> _deleteItem(ContainerData container, String itemId) async {
    setState(() {
      container.items.removeWhere((item) => item.id == itemId);
    });

    await _saveChecklist();
  }

  Future<void> _saveChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    final checklistData = _containers.map((container) => {
          'id': container.id,
          'date': container.date,
          'items': container.items.map((item) => {
                'id': item.id,
                'content': item.content,
                'isChecked': item.isChecked,
              }).toList(),
        }).toList();

    prefs.setString('checklist', jsonEncode(checklistData));
    print('Checklist saved: $checklistData');
  }

  Future<void> _loadChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    final String? checklistString = prefs.getString('checklist');

    if (checklistString != null) {
      final List<dynamic> checklistData = jsonDecode(checklistString);
      setState(() {
        _containers = checklistData.map((data) => ContainerData(
              id: data['id'],
              date: data['date'],
              items: (data['items'] as List<dynamic>).map((item) => ChecklistItem(
                    id: item['id'],
                    content: item['content'],
                    isChecked: item['isChecked'],
                  )).toList(),
            )).toList();
      });
      print('Checklist loaded: $checklistData');
    }
  }

  @override
  void dispose() {
    for (var container in _containers) {
      container.controller.dispose();
      for (var item in container.items) {
        item.controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'TICK CHART',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            color: Colors.black,
            height: 2.0,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFFFBF5),
      body: ListView.builder(
        itemCount: _containers.length + 1,
        itemBuilder: (context, index) {
          if (index == _containers.length) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton(
                onPressed: _addContainer,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey.withOpacity(0.1),
                ),
                child: const Text(
                  '+ 새로운 체크리스트 추가',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          final container = _containers[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: container.controller,
                          decoration: const InputDecoration(
                            hintText: '제목을 입력하세요',
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (value) {
                            setState(() {
                              container.date = value;
                            });
                            _saveChecklist();
                          },
                        ),
                      ),
                      IconButton(
                        icon: Opacity(
                          opacity: 0.5, // 반투명 적용
                          child: const Icon(Icons.delete_outline),
                        ),
                        onPressed: () => _deleteContainer(container.id),
                      ),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: container.items.length,
                  itemBuilder: (context, itemIndex) {
                    final item = container.items[itemIndex];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 2.0, // 간격 줄임
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: item.isChecked,
                            onChanged: (value) {
                              setState(() {
                                item.isChecked = value ?? false;
                              });
                              _saveChecklist();
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: item.controller,
                              decoration: const InputDecoration(
                                hintText: '내용을 입력하세요',
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  item.content = value;
                                });
                                _saveChecklist();
                              },
                            ),
                          ),
                          IconButton(
                            icon: Opacity(
                              opacity: 0.5, // 반투명 적용
                              child: const Icon(Icons.delete, color: Colors.red),
                            ),
                            onPressed: () => _deleteItem(container, item.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: () => _addItem(container),
                    child: const Text('+ 항목 추가'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}