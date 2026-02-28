import 'package:alumnex/alumn_global.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class ProgressPage extends StatefulWidget {
  final String studentId;

  var roll;
  ProgressPage({required this.studentId, required this.roll});

  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? progressData;
  List<dynamic> overallProgress = [];
  bool isLoading = true;

  // Theme colors
  final Color primaryColor4 = const Color(0xFF004d52);
  final Color accentColor1 = const Color(0xFFe27c43);
  final Color secondaryColor2 = const Color(0xFF224146);
  final Color primaryColor3 = const Color(0xFF1565C0);
  final Color accentColor5 = const Color(0xFFFF7043);
  final Color secondaryColor6 = const Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    fetchTodayProgress();
    fetchOverallProgress();
  }

  Future<void> fetchTodayProgress() async {
    try {
      if (widget.roll == "Student") {
        final response = await http.get(
          Uri.parse('$urI/api/student/${widget.studentId}/progress/today'),
        );

        if (response.statusCode == 200) {
          setState(() {
            progressData = json.decode(response.body);
            isLoading = false;
          });
        } else {
          print("Failed to fetch today progress: ${response.statusCode}");
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      print("Error fetching today progress: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchOverallProgress() async {
    try {
      if (widget.roll == "Student") {
        final response = await http.get(
          Uri.parse('$urI/api/student/${widget.studentId}/progress/overall'),
        );

        if (response.statusCode == 200) {
          setState(() {
            overallProgress = json.decode(response.body); // List of daily docs
          });
        } else {
          print("Failed to fetch overall progress: ${response.statusCode}");
        }
      }
    } catch (e) {
      print("Error fetching overall progress: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Progress",
            style: TextStyle(color: Colors.white), // ✅ Title text color white
          ),
          backgroundColor: primaryColor4,
          bottom: TabBar(
            labelColor: Colors.white,
            indicatorColor: accentColor1,
            unselectedLabelColor: accentColor1,
            tabs: [Tab(text: "Today"), Tab(text: "Overall")],
          ),
        ),
        body: TabBarView(children: [_buildTodayTab(), _buildOverallTab()]),
      ),
    );
  }

  // ---------------- TODAY TAB ----------------
  Widget _buildTodayTab() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor3));
    }

    if (progressData == null) {
      return Center(child: Text("No progress data available"));
    }

    double taskCompletion =
        (progressData!['task_completion']?['progress_percent'] ?? 0).toDouble();

    double avgScore =
        (progressData!['average_score']?['progress_percent'] ?? 0).toDouble();

    int engagementScore = progressData!['engagement_score'] ?? 0;

    // Prepare engagement graph data
    List<FlSpot> engagementSpots = [];
    List<String> dates = [];

    for (int i = 0; i < overallProgress.length; i++) {
      final entry = overallProgress[i];
      dates.add(entry["date"] ?? "");
      engagementSpots.add(
        FlSpot(i.toDouble(), (entry["engagement_score"] ?? 0).toDouble()),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Completion
          Text(
            "Task Completion",
            style: TextStyle(fontSize: 18, color: secondaryColor2),
          ),
          SizedBox(height: 5),
          LinearProgressIndicator(
            value: taskCompletion / 100,
            minHeight: 15,
            color: accentColor1,
            backgroundColor: secondaryColor6,
          ),
          SizedBox(height: 5),
          Text(
            "${taskCompletion.toStringAsFixed(2)}%",
            style: TextStyle(fontSize: 16, color: secondaryColor2),
          ),
          SizedBox(height: 20),

          // Average Score
          Text(
            "Average Score",
            style: TextStyle(fontSize: 18, color: secondaryColor2),
          ),
          SizedBox(height: 5),
          LinearProgressIndicator(
            value: avgScore / 100,
            minHeight: 15,
            color: primaryColor3,
            backgroundColor: secondaryColor6,
          ),
          SizedBox(height: 5),
          Text(
            "${avgScore.toStringAsFixed(2)}%",
            style: TextStyle(fontSize: 16, color: secondaryColor2),
          ),
          SizedBox(height: 20),

          // Engagement Score with graph
          Text(
            "Engagement Score (with history)",
            style: TextStyle(fontSize: 18, color: secondaryColor2),
          ),
          SizedBox(
            height: 200, // Chart height
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < dates.length) {
                          return Text(
                            dates[value.toInt()].substring(5),
                            style: TextStyle(fontSize: 10),
                          );
                        }
                        return Container();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, interval: 5),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: engagementSpots,
                    isCurved: true,
                    color: accentColor5,
                    barWidth: 3,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          Center(
            child: Text(
              "Today: $engagementScore",
              style: TextStyle(fontSize: 16, color: secondaryColor2),
            ),
          ),

          SizedBox(height: 30),

          // Circular Indicator for Task Completion
          Center(
            child: Column(
              children: [
                Text(
                  "Overall Task Completion",
                  style: TextStyle(fontSize: 18, color: secondaryColor2),
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  width: 140,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: taskCompletion / 100,
                        strokeWidth: 12,
                        color: accentColor1,
                        backgroundColor: secondaryColor6,
                      ),
                      Center(
                        child: Text(
                          "${taskCompletion.toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: secondaryColor2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- OVERALL TAB ----------------
  Widget _buildOverallTab() {
    if (overallProgress.isEmpty) {
      return Center(child: Text("No overall data available"));
    }

    List<String> dates = [];
    List<FlSpot> taskSpots = [];
    List<FlSpot> scoreSpots = [];
    List<FlSpot> engagementSpots = [];

    for (int i = 0; i < overallProgress.length; i++) {
      final entry = overallProgress[i];
      dates.add(entry["date"] ?? "");
      taskSpots.add(
        FlSpot(i.toDouble(), (entry["task_completion"] ?? 0).toDouble()),
      );
      scoreSpots.add(
        FlSpot(i.toDouble(), (entry["average_score"] ?? 0).toDouble()),
      );
      engagementSpots.add(
        FlSpot(i.toDouble(), (entry["engagement_score"] ?? 0).toDouble()),
      );
    }

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildLineChart(
          "Task Completion Over Time",
          taskSpots,
          accentColor1,
          dates,
        ),
        SizedBox(height: 30),
        _buildLineChart(
          "Average Score Over Time",
          scoreSpots,
          primaryColor3,
          dates,
        ),
        SizedBox(height: 30),
        _buildLineChart(
          "Engagement Over Time",
          engagementSpots,
          accentColor5,
          dates,
        ),
      ],
    );
  }

  // Reusable chart builder
  Widget _buildLineChart(
    String title,
    List<FlSpot> spots,
    Color color,
    List<String> dates,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 18, color: secondaryColor2)),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < dates.length) {
                        return Text(
                          dates[value.toInt()].substring(5),
                          style: TextStyle(fontSize: 10),
                        );
                      }
                      return Container();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, interval: 20),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  barWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
