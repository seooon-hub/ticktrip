import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticktrip/screens/menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:ticktrip/screens/checklist.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? _selectedChecklistId;
  List<ChecklistItem>? _selectedChecklistItems;

  @override
  void initState() {
    super.initState();
    _loadSelectedChecklist();
  }

  Future<void> _loadSelectedChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedId = prefs.getString('selected_checklist_id');
    if (selectedId != null) {
      setState(() {
        _selectedChecklistId = selectedId;
      });
      _loadChecklistItems(selectedId);
    }
  }

  Future<void> _loadChecklistItems(String checklistId) async {
    final prefs = await SharedPreferences.getInstance();
    final checklistsJson = prefs.getString('checklist');
    if (checklistsJson != null) {
      final checklists = json.decode(checklistsJson) as List;
      final selectedChecklist = checklists.firstWhere(
        (checklist) => checklist['id'] == checklistId,
        orElse: () => null,
      );
      
      if (selectedChecklist != null) {
        setState(() {
          _selectedChecklistItems = (selectedChecklist['items'] as List)
              .map((item) => ChecklistItem(
                    id: item['id'],
                    content: item['content'],
                    isChecked: item['isChecked'],
                  ))
              .toList();
        });
      }
    }
  }

  Future<void> _showChecklistSelector() async {
    final prefs = await SharedPreferences.getInstance();
    final checklistsJson = prefs.getString('checklist');
    if (checklistsJson == null) return;

    final checklists = json.decode(checklistsJson) as List;
    
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('체크리스트 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: checklists.length,
            itemBuilder: (context, index) {
              final checklist = checklists[index];
              return ListTile(
                title: Text(checklist['date']),
                onTap: () async {
                  await prefs.setString('selected_checklist_id', checklist['id']);
                  setState(() {
                    _selectedChecklistId = checklist['id'];
                  });
                  _loadChecklistItems(checklist['id']);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'TICKTRIP',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MenuPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TICK CHART',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _showChecklistSelector,
                      child: const Text('체크리스트 선택'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_selectedChecklistItems == null || _selectedChecklistItems!.isEmpty)
                  const Center(
                    child: Text('선택된 체크리스트가 없습니다.'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedChecklistItems!.length,
                    itemBuilder: (context, index) {
                      final item = _selectedChecklistItems![index];
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.content),
                        value: item.isChecked,
                        onChanged: (value) async {
                          setState(() {
                            item.isChecked = value ?? false;
                          });
                          await _saveChecklistState();
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveChecklistState() async {
    if (_selectedChecklistId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final checklistsJson = prefs.getString('checklist');
    if (checklistsJson == null) return;

    final checklists = json.decode(checklistsJson) as List;
    final checklistIndex = checklists.indexWhere(
      (checklist) => checklist['id'] == _selectedChecklistId,
    );

    if (checklistIndex != -1) {
      checklists[checklistIndex]['items'] = _selectedChecklistItems!
          .map((item) => {
                'id': item.id,
                'content': item.content,
                'isChecked': item.isChecked,
              })
          .toList();

      await prefs.setString('checklist', json.encode(checklists));
    }
  }
}
