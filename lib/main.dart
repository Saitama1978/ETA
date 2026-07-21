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
  // Date & Time Picker Values
  DateTime _depDate = DateTime.now();
  TimeOfDay _depTime = const TimeOfDay(hour: 15, minute: 0);

  // Controllers for Numeric Inputs
  final _zdDepController = TextEditingController(text: "8");
  final _zdArrController = TextEditingController(text: "-3");
  final _distController = TextEditingController(text: "9101.83");
  final _baseSpdController = TextEditingController(text: "11.5");

  // Output State
  String _outputDepLT = "";
  String _outputDepUTC = "";
  List<Map<String, dynamic>> _speedTable = [];

  // Calendar Picker for Departure Date
  Future<void> _selectDepDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _depDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && picked != _depDate) {
      setState(() {
        _depDate = picked;
      });
    }
  }

  // Time Picker for Departure Time
  Future<void> _selectDepTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _depTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _depTime) {
      setState(() {
        _depTime = picked;
      });
    }
  }

  void _calculate() {
    setState(() {
      try {
        double zdDep = double.parse(_zdDepController.text);
        double zdArr = double.parse(_zdArrController.text);
        double distance = double.parse(_distController.text);
        double baseSpeed = double.parse(_baseSpdController.text);

        // Combine Date & Time
        DateTime depLT = DateTime(
          _depDate.year,
          _depDate.month,
          _depDate.day,
          _depTime.hour,
          _depTime.minute,
        );

        // Departure UTC = LT - ZD
        int zdDepMinutes = (zdDep * 60).round();
        DateTime depUTC = depLT.subtract(Duration(minutes: zdDepMinutes));

        DateFormat dateFmt = DateFormat("dd-MMM HH:mm");
        _outputDepLT =
            "DEP (LT) : ${dateFmt.format(depLT)} (ZD ${zdDep > 0 ? '+$zdDep' : zdDep})";
        _outputDepUTC = "DEP (UTC): ${dateFmt.format(depUTC)}";

        // Generate Speed Matrix Table (+0 to +5 knots)
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
        _speedTable.clear();
      }
    });
  }

  void _clear() {
    setState(() {
      _depDate = DateTime.now();
      _depTime = const TimeOfDay(hour: 0, minute: 0);
      _zdDepController.clear();
      _zdArrController.clear();
      _distController.clear();
      _baseSpdController.clear();

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
        title: const Text("NavMaster User Guide",
            style: TextStyle(color: Color(0xFF00E676))),
        content: const SingleChildScrollView(
          child: Text(
            "1. Tap Departure Date box to open CALENDAR picker.\n"
            "2. Tap DEP Time box to open CLOCK picker.\n"
            "3. Fill Zone Description (ZD) for Departure and Arrival.\n"
            "4. Input Distance (NM) and Base Speed (Kts).\n"
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    String formattedDate = DateFormat("yyyy-MM-dd").format(_depDate);
    String formattedHour = _depTime.hour.toString().padLeft(2, '0');
    String formattedMin = _depTime.minute.toString().padLeft(2, '0');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Inayos ang typo dito
            children: [
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

              Expanded(
                child: ListView(
                  children: [
                    const Text("Departure Date (Tap to Pick Calendar):",
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    _buildClickableBox(
                      onTap: () => _selectDepDate(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                                color: Color(0xFF00E676),
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          const Icon(Icons.calendar_month, color: Colors.blue),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: const [
                        Expanded(
                            child: Text("DEP Time (Tap to Pick)",
                                style: TextStyle(color: Colors.white70))),
                        SizedBox(width: 10),
                        Expanded(
                            child: Text("ZD (DEP / ARR)",
                                style: TextStyle(color: Colors.white70))),
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
                                Text(
                                  "$formattedHour:$formattedMin",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Icon(Icons.access_time,
                                    color: Colors.blue, size: 18),
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
                              decoration: const InputDecoration(
                                  border: InputBorder.none, hintText: "DEP ZD"),
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
                              decoration: const InputDecoration(
                                  border: InputBorder.none, hintText: "ARR ZD"),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: const [
                        Expanded(
                            child: Text("Dist (NM)",
                                style: TextStyle(color: Colors.white70))),
                        SizedBox(width: 10),
                        Expanded(
                            child: Text("Base Spd (Kts)",
                                style: TextStyle(color: Colors.white70))),
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
                              decoration:
                                  const InputDecoration(border: InputBorder.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInputBox(
                            TextField(
                              controller: _baseSpdController,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(border: InputBorder.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

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
                            child: const Text("CALC",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
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
                            child: const Text("CLEAR",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
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
                            child: const Text("GUIDE",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Terminal Matrix Output
                    if (_outputDepLT.isNotEmpty) ...[
                      Text(_outputDepLT,
                          style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontFamily: 'monospace')),
                      Text(_outputDepUTC,
                          style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontFamily: 'monospace')),
                      const Text("=============================",
                          style: TextStyle(
                              color: Color(0xFF00E676),
                              fontFamily: 'monospace')),
                      Text("SPD   HRS   ETA (LT) @ZD ${_zdArrController.text}",
                          style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold)),
                      ..._speedTable.map((row) => Text(
                            "${row['spd'].padRight(5)} ${row['hrs'].padRight(5)} ${row['eta']}",
                            style: const TextStyle(
                                color: Color(0xFF00E676),
                                fontFamily: 'monospace'),
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
