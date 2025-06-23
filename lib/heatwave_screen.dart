// lib/heatwave_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'service/weather_service.dart'; // Ensure correct import path

class HeatwaveScreen extends StatefulWidget {
  const HeatwaveScreen({Key? key}) : super(key: key);

  @override
  State<HeatwaveScreen> createState() => _HeatwaveScreenState();
}

class _HeatwaveScreenState extends State<HeatwaveScreen>
    with TickerProviderStateMixin {
  late AnimationController _meterController;
  late Animation<double> _meterAnimation;

  int currentHeatIndex = 0;
  String heatStatus = "LOADING...";
  String _currentCity = "Loading...";

  List<double> hourlyData = [];
  List<Map<String, dynamic>> weeklyWeather = [];

  final TextEditingController _searchController = TextEditingController();
  final WeatherService _weatherService =
      WeatherService(); // Instantiate your service

  @override
  void initState() {
    super.initState();
    _meterController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _setupAnimation();
    _fetchWeatherData('Chennai'); // Initial fetch for Chennai
  }

  void _setupAnimation() {
    // Ensure animation end value is not negative if currentHeatIndex is 0
    _meterAnimation = Tween<double>(
      begin: 0.0,
      end: currentHeatIndex.toDouble() / 200.0, // Cast to double
    ).animate(
      CurvedAnimation(parent: _meterController, curve: Curves.easeInOut),
    );
    if (!_meterController.isAnimating) {
      _meterController.forward(from: 0.0);
    }
  }

  Future<void> _fetchWeatherData(String cityName) async {
    setState(() {
      _currentCity = cityName;
      currentHeatIndex = 0;
      heatStatus = "Loading...";
      hourlyData = [];
      weeklyWeather = [];
    });

    try {
      // Call the service method which handles geocoding internally
      final data = await _weatherService.fetchWeatherForecast(cityName);

      // --- Start of Data Parsing ---
      if (data['list'] == null || !(data['list'] is List)) {
        throw Exception('API response "list" is missing or malformed.');
      }

      final List<dynamic> forecastList = data['list'];

      // Hourly Data (first 24 entries)
      List<double> fetchedHourlyData = [];
      for (int i = 0; i < math.min(forecastList.length, 24); i++) {
        final item = forecastList[i];
        if (item != null &&
            item.containsKey('main') &&
            item['main'] != null &&
            item['main'].containsKey('temp')) {
          final temp = (item['main']['temp'] as num).toDouble();
          fetchedHourlyData.add(temp * 4); // Multiplying by 4 as per your logic
        } else {
          fetchedHourlyData.add(0.0); // Add default if data is missing
          print('Warning: Missing temperature data for hourly item $i');
        }
      }

      // Weekly Weather (unique days)
      List<Map<String, dynamic>> fetchedWeeklyWeather = [];
      final uniqueDates = <String>{};

      for (var item in forecastList) {
        if (item == null || !item.containsKey('dt')) continue;

        final dateTime =
            DateTime.fromMillisecondsSinceEpoch((item['dt'] as int) * 1000);
        final dateKey =
            DateFormat('EEE').format(dateTime); // e.g., 'Mon', 'Tue'

        // Only add if this is the first entry for this day
        if (uniqueDates.add(dateKey)) {
          if (item.containsKey('main') &&
              item['main'] != null &&
              item['main'].containsKey('temp')) {
            Color tempColor;
            final temp = (item['main']['temp'] as num).toDouble();
            if (temp <= 22) {
              tempColor = Colors.green;
            } else if (temp <= 28) {
              tempColor = Colors.amber;
            } else if (temp <= 34) {
              tempColor = Colors.orange;
            } else {
              tempColor = Colors.red;
            }

            IconData weatherIcon = Icons.help_outline; // Default icon
            if (item.containsKey('weather') &&
                item['weather'] is List &&
                item['weather'].isNotEmpty) {
              final weatherMain = item['weather'][0]['main'];
              if (weatherMain == 'Clouds') {
                weatherIcon = Icons.cloud;
              } else if (weatherMain == 'Rain') {
                weatherIcon = Icons.grain;
              } else if (weatherMain == 'Clear') {
                weatherIcon = Icons.wb_sunny;
              } else if (weatherMain == 'Thunderstorm') {
                weatherIcon = Icons.flash_on;
              } else if (weatherMain == 'Drizzle') {
                weatherIcon = Icons.grain;
              } else if (weatherMain == 'Snow') {
                weatherIcon = Icons.ac_unit;
              } else if (weatherMain == 'Mist' ||
                  weatherMain == 'Smoke' ||
                  weatherMain == 'Haze' ||
                  weatherMain == 'Dust' ||
                  weatherMain == 'Fog' ||
                  weatherMain == 'Sand' ||
                  weatherMain == 'Ash' ||
                  weatherMain == 'Squall' ||
                  weatherMain == 'Tornado') {
                weatherIcon = Icons.cloud_queue; // General hazy/misty icon
              }
            }

            fetchedWeeklyWeather.add({
              'day': dateKey,
              'temp': '${temp.round()}°',
              'color': tempColor,
              'icon': weatherIcon,
            });
          }
          if (fetchedWeeklyWeather.length >= 7) {
            break; // Stop after collecting 7 unique days
          }
        }
      }
      // --- End of Data Parsing ---

      setState(() {
        hourlyData = fetchedHourlyData;
        weeklyWeather = fetchedWeeklyWeather;

        // Update currentHeatIndex and heatStatus based on the first hourly data point
        if (hourlyData.isNotEmpty) {
          currentHeatIndex = hourlyData[0].round();
          heatStatus = _getHeatStatus(currentHeatIndex.toDouble());
        } else {
          currentHeatIndex = 0;
          heatStatus = "No data available";
        }
        _setupAnimation(); // Re-run animation with new heat index
      });
    } catch (e) {
      print('Error fetching weather: $e'); // Log the actual error
      setState(() {
        _currentCity = "Error";
        heatStatus = "Error fetching data";
        currentHeatIndex = 0; // Reset heat index on error
        hourlyData = []; // Clear data on error
        weeklyWeather = []; // Clear data on error
        _setupAnimation(); // Reset animation
      });
      // Show snackbar for user feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load weather: ${e.toString()}')),
      );
    }
  }

  // Helper functions for UI logic
  Color _getHeatColor(double value) {
    if (value <= 80) return Colors.green;
    if (value <= 120) return Colors.yellow; // This is the 'amber' in the image
    if (value <= 150) return Colors.orange;
    return Colors.red; // This is the 'brown' in the image
  }

  String _getHeatStatus(double value) {
    if (value <= 80) return "GOOD";
    if (value <= 120) return "MODERATE";
    if (value <= 150) return "NOT GOOD";
    return "DANGEROUS";
  }

  @override
  void dispose() {
    _meterController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text(
          'Heatwaves Indicator',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Search
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey[400]),
                  hintText: 'Search Location',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[400]),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _currentCity = "Search a city...";
                              hourlyData = [];
                              weeklyWeather = [];
                              currentHeatIndex = 0; // Reset heat index
                              heatStatus = "Enter city"; // Reset status
                              _setupAnimation(); // Reset animation
                            });
                          },
                        )
                      : null,
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _fetchWeatherData(value);
                  }
                },
              ),
            ),

            const SizedBox(height: 40),

            // Heat Index Meter
            Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Meter Background

                    // Animated Meter Progress
                    AnimatedBuilder(
                      animation: _meterAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(280, 280),
                          painter: HeatMeterPainter(
                            currentHeatIndexValue: currentHeatIndex.toDouble() *
                                _meterAnimation.value, // Animate the value
                            strokeWidth: 20,
                          ),
                        );
                      },
                    ),
                    // Center Content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _meterAnimation,
                          builder: (context, child) {
                            int displayValue =
                                (_meterAnimation.value * currentHeatIndex)
                                    .round();
                            return Text(
                              displayValue.toString(),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            );
                          },
                        ),
                        Text(
                          heatStatus,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _getHeatColor(currentHeatIndex.toDouble()),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Heat Ratio',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    // Scale Labels
                    Positioned(
                      bottom: 40,
                      left: 40,
                      child: Text(
                        'Low',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      right: 40,
                      child: Text(
                        'High',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Scale Numbers
                    Positioned(
                      left: 20,
                      top: 120,
                      child: Text(
                        '50',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      left: 100,
                      child: Text(
                        '100',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 100,
                      child: Text(
                        '150',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                    Positioned(
                      right: 20,
                      top: 120,
                      child: Text(
                        '200',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Next Hours Chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Next hours',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Updated few min ago', // Dynamic text or remove if not real-time
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentCity,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 120,
                    child: hourlyData.isEmpty
                        ? const Center(child: Text('No hourly data available'))
                        : CustomPaint(
                            size: Size(
                                MediaQuery.of(context).size.width - 80, 120),
                            painter: HourlyChartPainter(hourlyData),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Weather Forecast
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Weather',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'This week',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  weeklyWeather.isEmpty
                      ? const Center(
                          child: Text('No weekly forecast available'))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: weeklyWeather.map((weather) {
                            return Column(
                              children: [
                                Text(
                                  weather['day'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: weather['color'],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  weather['temp'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Icon(
                                  weather['icon'],
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// HeatMeterPainter: CustomPainter for the circular heat index meter
class HeatMeterPainter extends CustomPainter {
  final double currentHeatIndexValue; // The actual heat index (e.g., 150)
  final double strokeWidth; // Thickness of the arc

  HeatMeterPainter({
    required this.currentHeatIndexValue,
    required this.strokeWidth,
  });

  // Helper to get color for a specific heat index value range
  Color _getColorForRange(double value) {
    if (value <= 80) return Colors.green; // Range 0-80
    if (value <= 120) return Colors.amber; // Range 81-120
    if (value <= 150) return Colors.orange; // Range 121-150
    return Colors.red.shade700; // Range 151-200 (darker red/brown)
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = math.pi; // Start from 180 degrees (left side)
    const totalSweepAngle = math.pi; // Total half-circle (180 degrees)

    // Define the ranges for colors (based on 0-200 scale mapped to 0-pi angle)
    // Values are based on the _getHeatColor logic in HeatwaveScreen
    final greenMax = 80.0;
    final amberMax = 120.0;
    final orangeMax = 150.0;
    final redMax = 200.0;

    // Draw the segmented background arcs (Green, Amber, Orange, Dark Red/Brown)
    // 1. Green Segment (0 to 80)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, // Start at 180 degrees
      (greenMax / redMax) * totalSweepAngle, // Sweep for green
      false,
      Paint()
        ..color = _getColorForRange(70) // Color for the green segment
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt, // Use butt for continuous segments
    );

    // 2. Amber Segment (81 to 120)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + (greenMax / redMax) * totalSweepAngle, // Start after green
      ((amberMax - greenMax) / redMax) * totalSweepAngle, // Sweep for amber
      false,
      Paint()
        ..color = _getColorForRange(100) // Color for the amber segment
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );

    // 3. Orange Segment (121 to 150)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + (amberMax / redMax) * totalSweepAngle, // Start after amber
      ((orangeMax - amberMax) / redMax) * totalSweepAngle, // Sweep for orange
      false,
      Paint()
        ..color = _getColorForRange(140) // Color for the orange segment
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );

    // 4. Dark Red/Brown Segment (151 to 200)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + (orangeMax / redMax) * totalSweepAngle, // Start after orange
      ((redMax - orangeMax) / redMax) * totalSweepAngle, // Sweep for dark red
      false,
      Paint()
        ..color = _getColorForRange(180) // Color for the dark red segment
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );

    // Draw the circular indicator (the "dragger")
    // Calculate the angle corresponding to the current heat index
    final indicatorAngle = (currentHeatIndexValue / redMax) * totalSweepAngle;

    // Calculate the position of the indicator circle
    final indicatorX =
        center.dx + radius * math.cos(startAngle + indicatorAngle);
    final indicatorY =
        center.dy + radius * math.sin(startAngle + indicatorAngle);

    // Draw the indicator circle
    canvas.drawCircle(
      Offset(indicatorX, indicatorY),
      strokeWidth / 2 +
          3, // Radius of the indicator circle (slightly larger than arc thickness)
      Paint()
        ..color =
            Colors.white, // Color of the indicator circle (white in image)
    );
    canvas.drawCircle(
      // Draw a small inner circle to make it look like a dot inside
      Offset(indicatorX, indicatorY),
      strokeWidth / 2 - 2, // Slightly smaller radius
      Paint()..color = Colors.green, // Color of the inner dot (green in image)
    );
  }

  @override
  bool shouldRepaint(covariant HeatMeterPainter oldDelegate) {
    return oldDelegate.currentHeatIndexValue != currentHeatIndexValue ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// HourlyChartPainter: CustomPainter for the bar chart showing hourly data
class HourlyChartPainter extends CustomPainter {
  final List<double> data; // List of heat index values for each hour

  HourlyChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return; // Don't draw if no data

    // Paint for drawing the bars
    final barPaint = Paint()
      ..strokeWidth = 3 // Not directly used for fill, but good to have
      ..style = PaintingStyle.fill; // Fill the rectangles

    // Calculate width for each bar
    final barWidth = size.width / data.length;

    // Determine min/max values for scaling the bar heights
    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final valueRange = maxValue - minValue;

    // Adjust scaling: If all values are the same, prevent division by zero.
    // Also, ensure there's some base height for bars even if values are low.
    final effectiveValueRange =
        valueRange == 0 ? (maxValue == 0 ? 1 : maxValue) : valueRange;
    final minChartHeight = 20.0; // Minimum height for a bar to be visible

    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      // Normalize value to a 0-1 range based on min/max of the data
      final normalizedValue = (value - minValue) / effectiveValueRange;

      // Calculate bar height. Scale to 80% of chart height, leaving space for labels.
      double barHeight =
          normalizedValue * (size.height * 0.8 - minChartHeight) +
              minChartHeight;
      if (barHeight > size.height * 0.8)
        barHeight = size.height * 0.8; // Cap height
      if (barHeight < minChartHeight)
        barHeight = minChartHeight; // Ensure minimum height

      // Determine bar color based on heat index value
      Color barColor;
      if (value <= 80) {
        barColor = Colors.green;
      } else if (value <= 120) {
        barColor = Colors.yellow;
      } else if (value <= 150) {
        barColor = Colors.orange;
      } else {
        barColor = Colors.red;
      }

      barPaint.color = barColor;

      // Define the rectangle for the current bar
      final rect = Rect.fromLTWH(
        i * barWidth + barWidth * 0.2, // X position + padding
        size.height -
            barHeight -
            20, // Y position (from bottom up) - 20 for time labels
        barWidth * 0.6, // Width of the bar
        barHeight,
      );

      // Draw rounded rectangle for the bar
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
      canvas.drawRRect(rrect, barPaint);

      // Draw hourly labels (e.g., "00:00", "03:00")
      if (i % 3 == 0) {
        // Label every 3 hours
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${i.toString().padLeft(2, '0')}:00',
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
          textDirection:
              ui.TextDirection.ltr, // CORRECTED: Removed `ui.` prefix
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(i * barWidth + barWidth * 0.1, size.height - 15),
        );
      }
    }

    // Paint for text labels (min/mid/max values on the left side)
    final valueTextPaint = TextPainter(
      textDirection: ui.TextDirection.ltr, // CORRECTED: Removed `ui.` prefix
      textAlign: TextAlign.right,
    );

    // Max Value Label
    valueTextPaint.text = TextSpan(
      text: maxValue.round().toString(),
      style: TextStyle(color: Colors.grey[600], fontSize: 10),
    );
    valueTextPaint.layout();
    valueTextPaint.paint(
        canvas, Offset(-valueTextPaint.width - 5, size.height * 0.1));

    // Mid Value Label
    final midValue = (minValue + maxValue) / 2;
    valueTextPaint.text = TextSpan(
      text: midValue.round().toString(),
      style: TextStyle(color: Colors.grey[600], fontSize: 10),
    );
    valueTextPaint.layout();
    valueTextPaint.paint(
        canvas,
        Offset(-valueTextPaint.width - 5,
            size.height * 0.5 - valueTextPaint.height / 2));

    // Min Value Label
    valueTextPaint.text = TextSpan(
      text: minValue.round().toString(),
      style: TextStyle(color: Colors.grey[600], fontSize: 10),
    );
    valueTextPaint.layout();
    valueTextPaint.paint(
        canvas,
        Offset(-valueTextPaint.width - 5,
            size.height * 0.8 - valueTextPaint.height));
  }

  @override
  // Repaint if the data changes
  bool shouldRepaint(covariant HourlyChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
