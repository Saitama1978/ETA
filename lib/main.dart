import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const NavMasterApp());
}

class NavMasterApp extends StatelessWidget {
  const NavMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NAVMASTER ETA PRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050811),
        primaryColor: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Departure Date & Time Values
  DateTime _depDate = DateTime.now();
  TimeOfDay _depTime = const TimeOfDay(hour: 15, minute: 0);

  // Target Date & Time Values (Optional)
  DateTime? _targetDate;
  TimeOfDay? _targetTime;

  // Controllers
  final _zdDepController = TextEditingController(text: "8");
  final _zdArrController = TextEditingController(text: "-3");
  final _distController = TextEditingController(text: "9101.83");
  final _baseSpdController = TextEditingController(text: "11.5");

  // Output State
  String _outputDepLT = "";
  String _outputDepUTC = "";
  String _reqSpeedText = "";
  List<Map<String, dynamic>> _speedTable = [];

  // Calendar Pickers
  Future<void> _selectDepDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _depDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _depDate = picked);
  }

  Future<void> _selectDepTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _depTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _depTime = picked);
  }

  Future<void> _selectTargetDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _selectTargetTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _targetTime ?? const TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _targetTime = picked);
  }

  void _calculate() {
    setState(() {
      try {
        double zdDep = double.parse(_zdDepController.text);
        double zdArr = double.parse(_zdArrController.text);
        double distance = double.parse(_distController.text);
        double baseSpeed = double.parse(_baseSpdController.text);

        // Departure Local Time & UTC
        DateTime depLT = DateTime(
          _depDate.year,
          _depDate.month,
          _depDate.day,
          _depTime.hour,
          _depTime.minute,
        );

        int zdDepMinutes = (zdDep * 60).round();
        DateTime depUTC = depLT.subtract(Duration(minutes: zdDepMinutes));

        DateFormat dateFmt = DateFormat("dd-MMM HH:mm");
        _outputDepLT = "DEP (LT) : ${dateFmt.format(depLT)} (ZD ${zdDep > 0 ? '+$zdDep' : zdDep})";
        _outputDepUTC = "DEP (UTC): ${dateFmt.format(depUTC)}";

        // Required Speed Calculation (If Target ETA is set)
        _reqSpeedText = "";
        if (_targetDate != null && _targetTime != null) {
          DateTime targetLT = DateTime(
            _targetDate!.year,
            _targetDate!.month,
            _targetDate!.day,
            _targetTime!.hour,
            _targetTime!.minute,
          );

          int zdArrMinutes = (zdArr * 60).round();
          DateTime targetUTC = targetLT.subtract(Duration(minutes: zdArrMinutes));

          double totalHours = targetUTC.difference(depUTC).inMinutes / 60.0;

          if (totalHours > 0) {
            double reqSpeed = distance / totalHours;
            _reqSpeedText = "REQ SPD FOR TARGET ETA: ${reqSpeed.toStringAsFixed(2)} KTS (${totalHours.toStringAsFixed(1)} HRS)";
          } else {
            _reqSpeedText = "REQ SPD: Target ETA must be after Departure!";
          }
        }

        // Generate Speed Matrix Table
        _speedTable.clear();
        int zdArrMinutes = (zdArr * 60).round();

        for (int i = 0; i <= 5; i++) {
          double speed = baseSpeed + i;
          double hours = distance / speed;

          int totalMinutes = (hours * 60).round();
          DateTime arrUTC = depUTC.add(Duration(minutes: totalMinutes));
          DateTime arrLT = arrUTC.add(Duration(minutes: zdArrMinutes));

          _speedTable.add({
            'spd': speed.toStringAsFixed(1),
            'hrs': hours.toStringAsFixed(1),
            'eta': dateFmt.format(arrLT),
          });
        }
      } catch (e) {
        _outputDepLT = "Error: Invalid Input Format";
        _outputDepUTC = "";
        _reqSpeedText = "";
        _speedTable.clear();
      }
    });
  }

  void _clear() {
    setState(() {
      _depDate = DateTime.now();
      _depTime = const TimeOfDay(hour: 0, minute: 0);
      _targetDate = null;
      _targetTime = null;
      _zdDepController.clear();
      _zdArrController.clear();
      _distController.clear();
      _baseSpdController.clear();

      _outputDepLT = "";
      _outputDepUTC = "";
      _reqSpeedText = "";
      _speedTable.clear();
    });
  }

  void _showGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("NavMaster User Guide", style: TextStyle(color: Color(0xFF00E676))),
        content: const SingleChildScrollView(
          child: Text(
            "1. Tap Departure Date & Time to pick via calendar/clock.\n"
            "2. Fill Zone Description (ZD) for Departure and Arrival.\n"
            "3. Input Distance (NM) and Base Speed (Kts).\n"
            "4. (Optional) Set Target ETA to calculate REQ SPEED.\n"
            "5. Press CALC to generate ETA matrix.",
            style: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
    );
  }

  Widget _buildClickableBox({required Widget child, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C273E),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        ),
        child: child,
      ),
    );
  }

  Widget _buildInputBox(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1C273E),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDepDate = DateFormat("yyyy-MM-dd").format(_depDate);
    String formattedDepHour = _depTime.hour.toString().padLeft(2, '0');
    String formattedDepMin = _depTime.minute.toString().padLeft(2, '0');

    String formattedTargetDate = _targetDate != null ? DateFormat("yyyy-MM-dd").format(_targetDate!) : "YYYY-MM-DD";
    String formattedTargetHour = _targetTime != null ? _targetTime!.hour.toString().padLeft(2, '0') : "HH";
    String formattedTargetMin = _targetTime != null ? _targetTime!.minute.toString().padLeft(2, '0') : "MM";

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "NAVMASTER ETA PRO",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF1E88E5), fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "DEV: RENANTE FULLO",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF00E676), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  children: [
                    const Text("Departure Date (Tap to Pick Calendar):", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    _buildClickableBox(
                      onTap: () => _selectDepDate(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formattedDepDate, style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 16)),
                          const Icon(Icons.calendar_month, color: Colors.blue),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: const [
                        Expanded(child: Text("DEP Time (Tap)", style: TextStyle(color: Colors.white70))),
                        SizedBox(width: 10),
                        Expanded(child: Text("ZD (DEP / ARR)", style: TextStyle(color: Colors.white70))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildClickableBox(
                            onTap: () => _selectDepTime(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("$formattedDepHour:$formattedDepMin", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const Icon(Icons.access_time, color: Colors.blue, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInputBox(
                            TextField(
                              controller: _zdDepController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(border: InputBorder.none, hintText: "DEP ZD"),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildInputBox(
                            TextField(
                              controller: _zdArrController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(border: InputBorder.none, hintText: "ARR ZD"),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: const [
                        Expanded(child: Text("Dist (NM)", style: TextStyle(color: Colors.white70))),
                        SizedBox(width: 10),
                        Expanded(child: Text("Base Spd (Kts)", style: TextStyle(color: Colors.white70))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputBox(
                            TextField(
                              controller: _distController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(border: InputBorder.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInputBox(
                            TextField(
                              controller: _baseSpdController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(border: InputBorder.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // TARGET ETA SECTION
                    const Text("Target ETA (Optional - for Required Speed):", style: TextStyle(color: Color(0xFFFFD54F))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildClickableBox(
                            onTap: () => _selectTargetDate(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(formattedTargetDate, style: TextStyle(color: _targetDate != null ? Colors.white : Colors.white38)),
                                const Icon(Icons.calendar_today, color: Colors.amber, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildClickableBox(
                            onTap: () => _selectTargetTime(context),
                            child: Text("$formattedTargetHour:$formattedTargetMin", style: TextStyle(color: _targetTime != null ? Colors.white : Colors.white38)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), padding: const EdgeInsets.symmetric(vertical: 14)),
                            onPressed: _calculate,
                            child: const Text("CALC", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D1010), padding: const EdgeInsets.symmetric(vertical: 14)),
                            onPressed: _clear,
                            child: const Text("CLEAR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF424242), padding: const EdgeInsets.symmetric(vertical: 14)),
                            onPressed: _showGuide,
                            child: const Text("GUIDE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Terminal Output
                    if (_outputDepLT.isNotEmpty) ...[
                      Text(_outputDepLT, style: const TextStyle(color: Color(0xFF00E676), fontFamily: 'monospace')),
                      Text(_outputDepUTC, style: const TextStyle(color: Color(0xFF00E676), fontFamily: 'monospace')),
                      if (_reqSpeedText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(_reqSpeedText, style: const TextStyle(color: Color(0xFFFFD54F), fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                      ],
                      const Text("=============================", style: TextStyle(color: Color(0xFF00E676), fontFamily: 'monospace')),
                      Text("SPD   HRS   ETA (LT) @ZD ${_zdArrController.text}", style: const TextStyle(color: Color(0xFF00E676), fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                      ..._speedTable.map((row) => Text(
                            "${row['spd'].padRight(5)} ${row['hrs'].padRight(5)} ${row['eta']}",
                            style: const TextStyle(color: Color(0xFF00E676), fontFamily: 'monospace'),
                          )),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
