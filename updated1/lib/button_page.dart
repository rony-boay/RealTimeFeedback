import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:updated1/loading_screen.dart';

class ButtonPressData {
  final String label;
  final String date;
  final String time;

  ButtonPressData({
    required this.label,
    String? date,
    String? time,
  })  : date = date ?? 'N/A',
        time = time ?? 'N/A';

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'date': date,
      'time': time,
    };
  }
}

class ChartData {
  final String label;
  final double value;
  final Color color; // Add a Color property for each category

  ChartData(this.label, this.value, this.color);
}

class ButtonPage extends StatefulWidget {
  @override
  _ButtonPageState createState() => _ButtonPageState();
}

class _ButtonPageState extends State<ButtonPage> {
  List<ButtonPressData> buttonPresses = [];
  ScrollController _scrollController = ScrollController();
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    loadButtonPressesFromLocalStorage();
    fetchButtonPressData();
    _startAutoRefresh();
  }

  Future<void> loadButtonPressesFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString('buttonPresses');
    if (jsonData != null) {
      final List<dynamic> parsedData = jsonDecode(jsonData);
      final loadedData = parsedData
          .map((data) => ButtonPressData(
              label: data['label'], date: data['date'], time: data['time']))
          .toList();
      setState(() {
        buttonPresses = loadedData;
      });
    }
  }

  @override
  void dispose() {
    _stopAutoRefresh(); // Cancel the auto-refresh timer
    super.dispose();
  }

  Future<void> fetchButtonPressData() async {
    final url =
        'https://buttonflutterfirebase-default-rtdb.firebaseio.com/buttonPresses.json';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<ButtonPressData> loadedData = [];

      data.forEach((key, value) {
        if (value != null && value is Map<String, dynamic>) {
          final buttonPress = ButtonPressData(
            label: value['label'] ?? 'N/A',
            date: value['date'] ?? 'N/A',
            time: value['time'] ?? 'N/A',
          );
          loadedData.add(buttonPress);
        }
      });

      setState(() {
        buttonPresses = loadedData;
      });

      // Save the data to local storage
      saveButtonPressesToLocalStorage(buttonPresses);
    } else {
      print(
          'Failed to fetch button press data. Status code: ${response.statusCode}');
    }
  }

  Future<void> saveButtonPressesToLocalStorage(
      List<ButtonPressData> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = data.map((buttonPress) => buttonPress.toJson()).toList();
    prefs.setString('buttonPresses', jsonEncode(jsonData));
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToSummaryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ButtonSummaryPage(buttonPresses: buttonPresses),
      ),
    );
  }

  Future<void> _autoRefreshData() async {
    while (true) {
      await Future.delayed(
          Duration(milliseconds: 200)); // 10 milliseconds interval
      await fetchButtonPressData();
    }
  }

  void _startAutoRefresh() {
    // Start auto-refresh
    _refreshTimer = Timer.periodic(Duration(milliseconds: 200), (_) {
      fetchButtonPressData();
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (buttonPresses.isEmpty) {
      // Display the loading screen if the data is empty
      return LoadingScreen(); // Display the loading screen
    } else {
      // If data is available, display the normal content
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xffC69554),
          title: Center(
            child: Text(
              'Project Title: Real Time Feedback',
              style: TextStyle(
                fontSize: screenWidth < 600 ? 16 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        body: Container(
          color: Color.fromARGB(255, 250, 224, 200),
          padding: EdgeInsets.all(screenWidth < 600 ? 4.0 : 8.0),
          margin: EdgeInsets.all(0),
          child: Column(
            children: [
              Text(
                'Feedbacks',
                style: TextStyle(
                  fontSize: screenWidth < 600 ? 16 : 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: Scrollbar(
                  child: ListView(
                    controller: _scrollController,
                    children: buttonPresses
                        .map((buttonPress) => ListTile(
                              title: Text(buttonPress.label),
                              subtitle: Text(
                                  '${buttonPress.date} ${buttonPress.time}'),
                            ))
                        .toList(),
                  ),
                ),
              ),
              Row(
                children: [
                  SizedBox(
                    height: 10,
                    width: 10,
                  ),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Color(0xffC69554),
                      ),
                    ),
                    onPressed: _scrollToBottom,
                    child: Text(
                      'Scroll to Bottom',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                  ),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Color(0xffC69554),
                      ),
                    ),
                    onPressed: _scrollToTop,
                    child: Text(
                      'Scroll to Top',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    Color(0xffC69554),
                  ),
                ),
                onPressed: _navigateToSummaryPage,
                child: Text(
                  'Checkout Summary',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class ButtonSummaryPage extends StatelessWidget {
  final List<ButtonPressData> buttonPresses;

  const ButtonSummaryPage({Key? key, required this.buttonPresses})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, double> buttonCountMap = {};

    List<ChartData> generateChartData(Map<String, double> buttonCountMap) {
      List<ChartData> chartData = [];
      final List<Color> paletteColors = [
        Colors.blue,
        Colors.red,
        Colors.green,
        Colors.yellow,
        Colors.black,
        // Add more colors as needed
      ];

      // Iterate through the buttonCountMap and assign a color from the palette
      buttonCountMap.forEach((label, count) {
        final colorIndex =
            buttonCountMap.keys.toList().indexOf(label) % paletteColors.length;
        chartData
            .add(ChartData(label, count.toDouble(), paletteColors[colorIndex]));
      });
      return chartData;
    }

    // Count the number of each button press
    buttonPresses.forEach((buttonPress) {
      if (buttonCountMap.containsKey(buttonPress.label)) {
        buttonCountMap[buttonPress.label] =
            buttonCountMap[buttonPress.label]! + 1;
      } else {
        buttonCountMap[buttonPress.label] = 1;
      }
    });

    int calculateTotalButtonPresses(List<ButtonPressData> buttonPresses) {
      int total = 0;
      // ignore: unused_local_variable
      for (var buttonPress in buttonPresses) {
        total++;
      }
      return total;
    }

    final totalButtonPressed = calculateTotalButtonPresses(buttonPresses);

    int totalButtonPresses = buttonPresses.length;

    final screenWidth = MediaQuery.of(context).size.width;

    if (buttonPresses.isEmpty) {
      // Display the loading screen if the data is empty
      return LoadingScreen(); // Display the loading screen
    } else {
      // If data is available, display the normal content
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xffC69554),
          title: Center(
            child: Text(
              'Real Time Feedback',
              style: TextStyle(
                fontSize: screenWidth < 600 ? 18 : 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        body: Container(
          color: Color.fromARGB(255, 250, 224, 200),
          child: ListView(
            padding: EdgeInsets.all(screenWidth < 600 ? 4.0 : 8.0),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Users Feedback Summary',
                      style: TextStyle(
                        fontSize: screenWidth < 600 ? 16 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Number of Total Feedbacks Received: $totalButtonPresses',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15.0, 0.0, 0.0, 0.0),
                        child: Text(
                          'Feedback',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        'No. Of Feedback',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0.0, 0.0, 15.0, 0.0),
                        child: Text(
                          'Percentage',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: buttonCountMap.length,
                    itemBuilder: (context, index) {
                      final label = buttonCountMap.keys.elementAt(index);
                      final count = buttonCountMap[label];
                      final percentage = (count! / totalButtonPresses * 100)
                          .toStringAsFixed(2);

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(15.0, 0.0, 0.0, 0.0),
                              child: Text(label),
                            ),
                          ),
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                            child: Text(count.toString()),
                          )),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(0.0, 0.0, 15.0, 0.0),
                            child: Text('$percentage%'),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Feedback Distribution',
                      style: TextStyle(
                        fontSize: screenWidth < 600 ? 16 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Bar Chart
                  SfCartesianChart(
                    plotAreaBackgroundColor: Color(0xffC69554),
                    backgroundColor: Color.fromARGB(255, 250, 224, 200),
                    primaryXAxis: CategoryAxis(),
                    primaryYAxis: NumericAxis(
                      maximum: totalButtonPressed.toDouble(),
                      //   interval: totalButtonPressed / 20,
                      //    minorTicksPerInterval: 0,
                    ),
                    series: <ChartSeries<ChartData, String>>[
                      ColumnSeries<ChartData, String>(
                        dataSource: generateChartData(buttonCountMap),
                        xValueMapper: (ChartData data, _) => data.label,
                        yValueMapper: (ChartData data, _) => data.value,
                        dataLabelSettings: DataLabelSettings(isVisible: true),
                        // Use the color property for each data point.
                        pointColorMapper: (ChartData data, _) => data.color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(15.0, 0.0, 7.0, 0.0),
                    child: Text(
                      'Real-time feedback project designed in collaboration with Muslim Hands, empowering voices and fostering impactful change. Together, we strive to build a brighter future, and valuable insight at a time.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'Supervisor:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(0, 8, 55, 8),
                            child:
                                Text('Dr. Engr. Ahmad Khan Naqshbandi Shazli'),
                          ),
                          Text(
                            'Developers:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(0, 8, 20, 8),
                            child: Text(
                                '1. Muhammad Haroon Rafique (Team-Leader)\n2. Husnain Khalid\n3. Iqra Tariq\n4. Bakhtawar Shabbir'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }
}
