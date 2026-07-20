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
  // Input Controllers
  final _depDateController = TextEditingController(text: "2026-07-25");
  final _depHourController = TextEditingController(text: "15");
  final _depMinController = TextEditingController(text: "00");
  final _zdDepController = TextEditingController(text: "8");
  final _zdArrController = TextEditingController(text: "-3");
  final _distController = TextEditingController(text: "9101.83");
  final _baseSpdController = TextEditingController(text: "11.5");

  // Optional Required Speed Inputs
  final _targetDateController = TextEditingController();
  final _targetHourController = TextEditingController();
  final _targetMinController = TextEditingController();

  // Output State
  String _outputDepLT = "";
  String _outputDepUTC = "";
  List<Map<String, dynamic>> _speedTable = [];
  String? _reqSpeedOutput;

  void _calculate() {
    setState(() {
      try {
        // Parse Inputs
        DateTime depDate = DateTime.parse(_depDateController.text);
        int depHour = int.parse(_depHourController.text);
        int depMin = int.parse(_depMinController.text);
        double zdDep = double.parse(_zdDepController.text);
        double zdArr = double.parse(_zdArrController.text);
        double distance = double.parse(_distController.text);
        double baseSpeed = double.parse(_baseSpdController.text);

        // Departure Local Time
        DateTime depLT = DateTime(
          depDate.year,
          depDate.month,
          depDate.day,
          depHour,
          depMin,
        );

        // Departure UTC Time = LT - ZD
        int zdDepMinutes = (zdDep * 60).round();
        DateTime depUTC = depLT.subtract(Duration(minutes: zdDepMinutes));

        DateFormat dateFmt = DateFormat("dd-MMM HH:mm");
        _outputDepLT =
            "DEP (LT) : ${dateFmt.format(depLT)} (ZD ${zdDep > 0 ? '+$zdDep' : zdDep})";
        _outputDepUTC = "DEP (UTC): ${dateFmt.format(depUTC)}";

        // Generate Table for base speed to +5 knots
        _speedTable.clear();
        int zdArrMinutes = (zdArr * 60).round();

        for (int i = 0; i <= 5; i++) {
          double speed = baseSpeed + i;
          double hours = distance / speed;

          // Arrival UTC = Dep UTC + Hours
          int totalMinutes = (hours * 60).round();
          DateTime arrUTC = depUTC.add(Duration(minutes: totalMinutes));

          // Arrival LT = Arr UTC + ZD (Arr)
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
        _speedTable.clear();
      }
    });
  }

  void _clear() {
    setState(() {
      _depDateController.clear();
      _depHourController.clear();
      _depMinController.clear();
      _zdDepController.clear();
      _zdArrController.clear();
      _distController.clear();
      _baseSpdController.clear();
      _targetDateController.clear();
      _targetHourController.clear();
      _targetMinController.clear();

      _outputDepLT = "";
      _outputDepUTC = "";
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
            "1. Enter Departure Date in YYYY-MM-DD format.\n"
            "2. Fill Departure Time (HH MM) in 24-hour format.\n"
            "3. Specify Departure & Arrival Zone Description (ZD).\n"
            "   (e.g., +8 for Manila/Singapore, -3 for Brazil/Atlantic).\n"
            "4. Input total Distance in Nautical Miles (NM).\n"
            "5. Provide Base Speed in Knots (Kts).\n"
            "6. Tap 'CALC' to generate ETA Matrix across multiple speed increments.",
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

  Widget _buildFieldBox(Widget child, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF1C273E),
          borderRadius: BorderRadius.circular(4),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAlignment.stretch,
            children: [
              // Header Title
              const Text(
                "NAVMASTER ETA PRO",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1E88E5),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "DEV: RENANTE FULLO",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Inputs Area
              Expanded(
                child: ListView(
                  children: [
                    const Text("Departure Date (YYYY-MM-DD):", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    _buildFieldBox(
                      TextField(
                        controller: _depDateController,
                        style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: const [
                        Expanded(child: Text("DEP Time (HH:MM)", style: TextStyle(color: Colors.white70))),
                        SizedBox(width: 10),
                        Expanded(child: Text("ZD (DEP / ARR)", style: TextStyle(color: Colors.white70))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildFieldBox(TextField(
                          controller: _depHourController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(border: InputBorder.none),
                        )),
                        const SizedBox(width: 6),
                        _buildFieldBox(TextField(
                          controller: _depMinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(border: InputBorder.none),
                        )),
                        const SizedBox(width: 10),
                        _buildFieldBox(TextField(
                          controller: _zdDepController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(border: InputBorder.none),
                        )),
                        const SizedBox(width: 6),
                        _buildFieldBox(TextField(
                          controller: _zdArrController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(border: InputBorder.none),
                        )),
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
                        _buildFieldBox(TextField(
                          controller: _distController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(border: InputBorder.none),
                        )),
                        const SizedBox(width: 10),
                        _buildFieldBox(TextField(
                          controller: _baseSpdController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(border: InputBorder.none),
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),

                    const Text("Target ETA (Optional - for Required Speed):",
                        style: TextStyle(color: Color(0xFFFFD54F))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildFieldBox(TextField(
                          controller: _targetDateController,
                          decoration: const InputDecoration(hintText: "YYYY-MM-DD", border: InputBorder.none),
                        ), flex: 2),
                        const SizedBox(width: 6),
                        _buildFieldBox(TextField(
                          controller: _targetHourController,
                          decoration: const InputDecoration(hintText: "HH", border: InputBorder.none),
                        )),
                        const SizedBox(width: 6),
                        _buildFieldBox(TextField(
                          controller: _targetMinController,
                          decoration: const InputDecoration(hintText: "MM", border: InputBorder.none),
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _calculate,
                            child: const Text("CALC", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5D1010),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _clear,
                            child: const Text("CLEAR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF424242),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _showGuide,
                            child: const Text("GUIDE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Terminal Matrix Output Section
                    if (_outputDepLT.isNotEmpty) ...[
                      Text(_outputDepLT, style: const TextStyle(color: Color(0xFF00E676), fontFamily: 'monospace')),
                      Text(_outputDepUTC, style: const TextStyle(color: Color(0xFF00E676), fontFamily: 'monospace')),
                      const Text("=============================",
                          style: TextStyle(color: Color(0xFF00E676), fontFamily: 'monospace')),
                      Text("SPD   HRS   ETA (LT) @ZD ${_zdArrController.text}",
                          style: const TextStyle(color: Color(0xFF00E676), fontFamily: 'monospace', fontWeight: FontWeight.bold)),
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
