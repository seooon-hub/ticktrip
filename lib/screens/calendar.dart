import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'calendar_page.dart';

class CalendarTravelPage extends StatefulWidget {
  const CalendarTravelPage({Key? key}) : super(key: key);

  @override
  _CalendarTravelPageState createState() => _CalendarTravelPageState();
}

class _CalendarTravelPageState extends State<CalendarTravelPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('userId', isEqualTo: user.uid)
          .get();

      final newEvents = <DateTime, List<dynamic>>{};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final startDate = (data['startDate'] as Timestamp).toDate();
        final endDate = (data['endDate'] as Timestamp).toDate();
        
        for (DateTime date = DateTime(startDate.year, startDate.month, startDate.day);
             date.isBefore(endDate.add(const Duration(days: 1)));
             date = date.add(const Duration(days: 1))) {
          
          final key = DateTime(date.year, date.month, date.day);
          
          if (!newEvents.containsKey(key)) {
            newEvents[key] = [];
          }
          newEvents[key]!.add({
            'id': doc.id,
            'title': data['title'],
            'memo': data['memo'],
            'startDate': startDate,
            'endDate': endDate,
            'detailMemo': data['detailMemo'],
            'color': data['color'] ?? Colors.red.value,
          });
        }
      }

      setState(() {
        _events = newEvents;
      });
    } catch (e) {
      print('일정 로드 오류: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정 로드에 실패했습니다')),
      );
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  List<BoxDecoration> _getEventMarkersForDay(DateTime day) {
    final events = _getEventsForDay(day);
    return events.map((event) => BoxDecoration(
      color: Color(event['color'] ?? Colors.red.value),
      shape: BoxShape.circle,
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'CALENDAR',
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
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return _selectedDay != null && 
                     day.year == _selectedDay!.year &&
                     day.month == _selectedDay!.month &&
                     day.day == _selectedDay!.day;
            },
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              markerSize: 8.0,
              markerMargin: const EdgeInsets.symmetric(horizontal: 0.3),
              markersMaxCount: 4,
              markersAnchor: 0.7,
              markersAlignment: Alignment.bottomCenter,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox();
                
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: events.map((event) {
                    final eventData = event as Map<String, dynamic>;
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 0.3),
                      decoration: BoxDecoration(
                        color: Color(eventData['color'] as int? ?? Colors.red.value),
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildScheduleList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CalendarPage()),
          );
        },
        child: const Icon(Icons.calendar_today),
      ),
    );
  }

  Widget _buildScheduleList() {
    final events = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    if (events.isEmpty) {
      return const Center(
        child: Text('선택한 날짜의 일정이 없습니다.'),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final eventColor = Color(event['color'] ?? Colors.red.value);
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(event['title']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['memo']),
                Text(
                  '${DateFormat('yyyy.MM.dd HH:mm').format(event['startDate'])} - '
                  '${DateFormat('yyyy.MM.dd HH:mm').format(event['endDate'])}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: eventColor,
                    shape: BoxShape.circle,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteSchedule(event['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteSchedule(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('schedules')
          .doc(id)
          .delete();
      
      _loadEvents(); // 일정 삭제 후 이벤트 다시 로드
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정이 삭제되었습니다')),
      );
    } catch (e) {
      print('일정 삭제 오류: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정 삭제에 실패했습니다')),
      );
    }
  }
}
