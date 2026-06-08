import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const FloodDashboard(),
    );
  }
}

class FloodDashboard extends StatefulWidget {
  const FloodDashboard({super.key});

  @override
  State<FloodDashboard> createState() => _FloodDashboardState();
}

class _FloodDashboardState extends State<FloodDashboard> {
  // ---------------- LIVE DATA ----------------
  double level = 0;
  String risk = "WAITING";

  double temp = 0;
  int humidity = 0;
  double wind = 0;
  int pressure = 0;
  String condition = "Loading...";

  bool isError = false;

  String baseUrl =
      "https://attentive-shale-defiance.ngrok-free.dev";

  // ---------------- HISTORY ----------------
  List<double> levelHistory = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
    fetchLiveData();
  }

  // ---------------- LOAD HISTORY ----------------
  Future<void> loadHistory() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/history"));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          levelHistory = data
              .map<double>((e) => (e["level"] as num).toDouble())
              .toList();
        });
      }
    } catch (e) {
      print("History error: $e");
    }
  }

  // ---------------- LIVE DATA ----------------
  Future<void> fetchLiveData() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/data"));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final weather = data["weather"] ?? {};

        setState(() {
          level = (data["level"] ?? 0).toDouble();
          risk = data["risk"] ?? "UNKNOWN";

          temp = (weather["temp"] ?? 0).toDouble();
          humidity = weather["humidity"] ?? 0;
          wind = (weather["wind"] ?? 0).toDouble();
          pressure = weather["pressure"] ?? 0;
          condition = weather["condition"] ?? "N/A";

          // ADD LIVE DATA TO GRAPH
          levelHistory.add(level);

          if (levelHistory.length > 50) {
            levelHistory.removeAt(0);
          }

          isError = false;
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
      });
    }

    Future.delayed(const Duration(seconds: 2), fetchLiveData);
  }

  // ---------------- UI HELPERS ----------------
  Color riskColor() {
    switch (risk) {
      case "LOW":
        return Colors.green;
      case "MEDIUM":
        return Colors.orange;
      case "HIGH":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ---------------- WEATHER CARD ----------------
  Widget weatherCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "Weather Overview",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            "$temp°C",
            style: const TextStyle(
              fontSize: 34,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(condition,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              info("Humidity", "$humidity%"),
              info("Wind", "${wind.toStringAsFixed(1)}"),
              info("Pressure", "$pressure"),
            ],
          )
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget info(String t, String v) {
    return Column(
      children: [
        Text(v,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        Text(t, style: const TextStyle(color: Colors.white54)),
      ],
    );
  }

  // ---------------- GRAPH ----------------
  Widget graph() {
    if (levelHistory.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          "No data yet",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                levelHistory.length,
                (i) => FlSpot(i.toDouble(), levelHistory[i]),
              ),
              isCurved: true,
              color: Colors.cyan,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.cyan.withOpacity(0.2),
              ),
              dotData: const FlDotData(show: false),
            )
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        title: const Text("Flood Monitoring System"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),

      // 🔥 FIXED OVERFLOW HERE
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              weatherCard(),
              const SizedBox(height: 15),

              graph(),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.cyan],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                child: Column(
                  children: [
                    const Text("WATER LEVEL",
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    Text(
                      "${level.toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontSize: 44,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: riskColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "RISK: $risk",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}