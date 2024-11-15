import 'package:flutter/material.dart';
import 'package:gardenmate/Pages/Scheduled_Activity.dart.dart';
import 'package:gardenmate/Pages/activity_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:gardenmate/Pages/BottomNav_Bar.dart';
import 'package:intl/intl.dart'; // Import for DateFormat

class GC3ProgramPage extends StatefulWidget {
  @override
  _GC3ProgramPageState createState() => _GC3ProgramPageState();
}

class _GC3ProgramPageState extends State<GC3ProgramPage> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _duration = 1;
  int _iterations = 1;
  int _gap = 1;
  List<String> _selectedDays = [];
  List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  int _selectedChannel = 1; // Track the selected channel
  String _selectedHowOften = 'Daily'; // Track the selected "How Often" option
  bool _selectDaysOptionVisible =
      false; // Track visibility of "Select Days" option

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[200],
        title: Text('Program Settings'),
      ),
      bottomNavigationBar: buildBottomBar(context, 0, (index) {}),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChannelSelection(),
              SizedBox(height: 20),
              _buildChannelOptions(
                  _selectedChannel), // Pass selected channel to show its options
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Channel:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            for (int i = 1; i <= 3; i++)
              Row(
                children: [
                  Radio(
                    value: i,
                    groupValue: _selectedChannel,
                    onChanged: (value) {
                      setState(() {
                        _selectedChannel = value as int;
                      });
                    },
                  ),
                  Text('Channel $i'),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildChannelOptions(int channelNumber) {
    return ExpansionTile(
      title: Text(
        'Channel $channelNumber Options:',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      children: [
        SizedBox(height: 10),
        Text(
          'Start Time:',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _selectTime(context),
              child: Text(
                'Select Time',
                style: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Selected Time: ${_selectedTime.format(context)}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        SizedBox(height: 20),
        Text(
          'Duration (minutes):',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        TextFormField(
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              _duration = int.tryParse(value) ?? 1;
            });
          },
          decoration: InputDecoration(
            hintText: 'Enter duration',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'How Often:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        DropdownButtonFormField(
          value: _selectedHowOften,
          items: [
            DropdownMenuItem(
              child: Text('Daily'),
              value: 'Daily',
            ),
            DropdownMenuItem(
              child: Text('Alternative Days'),
              value: 'Alternative Days',
            ),
            DropdownMenuItem(
              child: Text('Weekly'),
              value: 'Weekly',
            ),
            DropdownMenuItem(
              child: Text('Select Days'),
              value: 'Select Days',
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedHowOften = value as String;
              if (_selectedHowOften == 'Select Days') {
                _selectDaysOptionVisible = true;
              } else {
                _selectDaysOptionVisible = false;
              }
            });
          },
        ),
        if (_selectDaysOptionVisible) ...[
          SizedBox(height: 20),
          Text(
            'Select Days:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Wrap(
            children: _buildDayButtons(),
          ),
        ],
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            _saveChannelOptions(channelNumber);
          },
          child: Text('Save Channel $channelNumber'),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  List<Widget> _buildDayButtons() {
    List<Widget> buttons = [];
    for (String day in _daysOfWeek) {
      buttons.add(
        FilterChip(
          label: Text(day),
          selected: _selectedDays.contains(day),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(day);
              } else {
                _selectedDays.remove(day);
              }
            });
          },
        ),
      );
      buttons.add(SizedBox(width: 10));
    }
    return buttons;
  }

  void _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveChannelOptions(int channelNumber) async {
    // Validate duration
    if (_duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid duration.'),
        ),
      );
      return;
    }

    // Validate frequency
    if (_selectedHowOften.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a frequency.'),
        ),
      );
      return;
    }

    // Validate selected days if frequency is Select Days
    if (_selectedHowOften == 'Select Days' && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one day.'),
        ),
      );
      return;
    }

    // If all validations pass, proceed to save preferences
    String formattedTime = _formatTimeOfDay(_selectedTime);
    ScheduledActivity newActivity = ScheduledActivity(
      selectedTime: formattedTime,
      duration: _duration,
      frequency: Frequency.values
          .indexWhere((e) => e.toString().split('.').last == _selectedHowOften),
      selectedDays: _selectedDays,
      channel: channelNumber,
    );

    // Save to SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? scheduledActivityStrings =
        prefs.getStringList('scheduledActivities');
    List<ScheduledActivity> scheduledActivities =
        scheduledActivityStrings != null
            ? scheduledActivityStrings
                .map((jsonString) =>
                    ScheduledActivity.fromJson(json.decode(jsonString)))
                .toList()
            : [];
    scheduledActivities.add(newActivity);

    await prefs.setStringList(
      'scheduledActivities',
      scheduledActivities
          .map((activity) => json.encode(activity.toJson()))
          .toList(),
    );

    // Navigate to ActivityPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityPage(
          scheduledActivities: scheduledActivities,
          onScheduleSuccess: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Schedule successful'),
              ),
            );
          },
          selectedTime: '',
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm(); // or add optional locale
    return format.format(dt);
  }
}

// Enum for frequency options
enum Frequency {
  Daily,
  AlternativeDays,
  Weekly,
  SelectDays,
}
