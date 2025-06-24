import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math; // Used for math.min

// Extension to get day of year for easier daily aggregation
extension DateTimeExtension on DateTime {
  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays + 1;
  }
}

// Updated Gauge Painter combining the best from both implementations
class HeatIndexGaugePainter extends CustomPainter {
  final double value;
  final double maxValue = 250;

  HeatIndexGaugePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 1.5);
    final radius = size.width / 1.5;
    const startAngle = 135 * (math.pi / 180);
    const sweepAngle = 270 * (math.pi / 180);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gapRadians = 1 * (math.pi / 180);

    final sections = [
      {'color': const Color(0xFF006400), 'start': 0.0, 'end': 49.0},
      {'color': const Color(0xFF74B04C), 'start': 51.0, 'end': 99.0},
      {'color': const Color(0xFFFDE49C), 'start': 101.0, 'end': 149.0},
      {'color': const Color(0xFFE59A45), 'start': 151.0, 'end': 199.0},
      {'color': const Color(0xFFB5542E), 'start': 201.0, 'end': 250.0},
    ];

    for (var section in sections) {
      final color = section['color'] as Color;
      final startVal = section['start'] as double;
      final endVal = section['end'] as double;

      final sectionStart =
          startAngle + (startVal / maxValue) * sweepAngle + gapRadians / 2;
      final sectionSweep =
          ((endVal - startVal) / maxValue) * sweepAngle - gapRadians;

      final isPointerHere = value >= startVal && value <= endVal;

      if (isPointerHere) {
        final verticalOffset = 4.0;
        final shadowOpacity = 0.2;
        final shadowCenter = Offset(center.dx, center.dy + verticalOffset);
        final shadowRect =
            Rect.fromCircle(center: shadowCenter, radius: radius);

        final shadowPaint = Paint()
          ..color = Colors.black.withOpacity(shadowOpacity)
          ..strokeWidth = 26 + 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt;

        canvas.drawArc(
            shadowRect, sectionStart, sectionSweep, false, shadowPaint);
      }

      final paint = Paint()
        ..color = color
        ..strokeWidth = isPointerHere ? 26 : 18
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, sectionStart, sectionSweep, false, paint);

      // Drawing caps (circles) at the start and end of the gauge
      // Corrected to use startAngle and end of sweep for precise positioning
      if (startVal == 0.0) {
        final capX = center.dx + radius * math.cos(startAngle);
        final capY = center.dy + radius * math.sin(startAngle);
        final capOffset = Offset(capX, capY);
        canvas.drawCircle(capOffset, 9, Paint()..color = color);
      } else if (endVal == 250.0) {
        final endOfGaugeAngle =
            startAngle + sweepAngle; // Actual end of the entire arc
        final capX = center.dx + radius * math.cos(endOfGaugeAngle);
        final capY = center.dy + radius * math.sin(endOfGaugeAngle);
        final capOffset = Offset(capX, capY);
        canvas.drawCircle(capOffset, 9, Paint()..color = color);
      }
    }

    // Draw pointer
    final pointerAngle =
        startAngle + ((value.clamp(0, maxValue) / maxValue) * sweepAngle);
    final pointerPaint = Paint()..color = const Color(0xFF63A646);
    final pointerX = center.dx + radius * math.cos(pointerAngle);
    final pointerY = center.dy + radius * math.sin(pointerAngle);

    canvas.drawCircle(
      Offset(pointerX, pointerY),
      12,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawCircle(Offset(pointerX, pointerY), 10, pointerPaint);

    _drawLabels(canvas, size, center);
  }

  void _drawLabels(Canvas canvas, Size size, Offset center) {
    // These angles are relative to the canvas coordinate system,
    // where 0 is right, 90 is down, 180 is left, 270 is up.
    // The gauge starts at 135 degrees and sweeps 270 degrees.
    // The angles for labels need to be adjusted accordingly.
    // E.g., for 'Low' at the start of the arc (135 degrees):
    // 0 index (startAngle) in normalized gauge space = 135 actual angle
    // max value (sweepAngle) in normalized gauge space = 135 + 270 = 405 (or 45 degrees)
    final labels = {
      'Low': 135.0, // Corresponds to startAngle
      '50': 189.0, // Roughly (135 + (50/250)*270)
      '100': 243.0, // Roughly (135 + (100/250)*270)
      '150': 297.0, // Roughly (135 + (150/250)*270)
      '200': 351.0, // Roughly (135 + (200/250)*270)
      'High': 45.0, // Corresponds to endAngle
    };

    labels.forEach((text, angle) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 20,
            fontWeight: ['Low', 'High'].contains(text)
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Increased labelRadius to move labels further away from the arc
      final labelRadius = (size.width / 1.5) + 35; // Increased from 20 to 35
      // Directly calculate radian conversion in math.cos and math.sin
      final x = center.dx +
          labelRadius * math.cos(angle * (math.pi / 180)) -
          textPainter.width / 2;
      final y = center.dy +
          labelRadius * math.sin(angle * (math.pi / 180)) -
          textPainter.height / 2;

      textPainter.paint(canvas, Offset(x, y));
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is HeatIndexGaugePainter && oldDelegate.value != value;
  }
}

// Updated Gauge Widget with proper animation
class HeatIndexGauge extends StatefulWidget {
  final double value;
  final String status;

  const HeatIndexGauge({
    Key? key,
    required this.value,
    required this.status,
  }) : super(key: key);

  @override
  State<HeatIndexGauge> createState() => _HeatIndexGaugeState();
}

class _HeatIndexGaugeState extends State<HeatIndexGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(HeatIndexGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          width: 180,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: HeatIndexGaugePainter(value: _animation.value),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        _animation.value.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.status,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Heat Ratio',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Weather Service with proper API integration
class WeatherService {
  // IMPORTANT: Replace with your actual OpenWeatherMap API key
  final String apiKey = '0d7b64fc4a902365b77a69f85f8a1396';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<Map<String, dynamic>> fetchWeatherForecast(String cityName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/forecast?q=$cityName&appid=$apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to load weather forecast data: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error for forecast: $e');
    }
  }

  Future<Map<String, dynamic>> fetchCurrentWeather(String cityName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weather?q=$cityName&appid=$apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to load current weather: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error for current weather: $e');
    }
  }
}

class HeatwavesIndicatorScreen extends StatefulWidget {
  const HeatwavesIndicatorScreen({super.key}); // Added const

  @override
  _HeatwavesIndicatorScreenState createState() =>
      _HeatwavesIndicatorScreenState();
}

class _HeatwavesIndicatorScreenState extends State<HeatwavesIndicatorScreen> {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _locationController = TextEditingController();

  bool _isLoading = false;
  String _currentLocation = 'Chennai'; // Default to Chennai for initial load
  double _currentHeatIndex = 150; // Default value matching mockup
  List<ChartData> _hourlyData = [];
  List<WeatherData> _weeklyWeather = [];
  String? _errorMessage;
  DateTime? _lastUpdatedTime; // To store the last successful update time

  @override
  void initState() {
    super.initState();
    _initializeDefaultData(); // Initialize with mockup data first
    _fetchCurrentLocationAndWeatherData(); // Fetch and set current location, then weather
  }

  // Simulates fetching the current location and then fetching weather data for it.
  Future<void> _fetchCurrentLocationAndWeatherData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Simulate fetching current location (e.g., from a GPS service)
      // In a real app, you would use a package like geolocator here.
      String fetchedLocation = await _simulateCurrentLocationFetch();

      _locationController.text =
          fetchedLocation; // Set the text in the search bar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Fetched simulated current location: $fetchedLocation')),
      );
      await _fetchWeatherData(
          fetchedLocation); // Fetch weather for the fetched location
    } catch (e) {
      print('Error fetching current location: $e');
      setState(() {
        _errorMessage =
            'Could not fetch current location. Please enter manually.';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error fetching current location: $_errorMessage')),
      );
      // Fallback to default or let user type
      _locationController.text =
          _currentLocation; // Keeps the default hint/value
      _fetchWeatherData(
          _currentLocation); // Still try to load default location weather
    }
  }

  // A simulated function to mimic getting the current location.
  // In a real application, this would use a package like 'geolocator'.
  Future<String> _simulateCurrentLocationFetch() async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 1));
    // For demonstration, return the default city.
    return 'Chennai'; // Changed to return 'Chennai'
  }

  // Initializes with data directly from the mockup image
  void _initializeDefaultData() {
    _currentHeatIndex = 150; // Matching gauge value

    _hourlyData = [
      ChartData('03', 75, _getHeatIndexColor(75)),
      ChartData('06', 85, _getHeatIndexColor(85)),
      ChartData('09', 90, _getHeatIndexColor(90)),
      ChartData('12', 135, _getHeatIndexColor(135)), // Peak hour - red bar
      ChartData('15', 90, _getHeatIndexColor(90)),
      ChartData('18', 85, _getHeatIndexColor(85)),
      ChartData('21', 75, _getHeatIndexColor(75)),
      ChartData('00', 70, _getHeatIndexColor(70)),
      ChartData('03', 75, _getHeatIndexColor(75)),
      ChartData('06', 80, _getHeatIndexColor(80)),
      ChartData('09', 85, _getHeatIndexColor(85)),
      ChartData('12', 80, _getHeatIndexColor(80)),
    ];

    List<String> dynamicDayNames = _generateDynamicDayNames();
    _weeklyWeather = [
      // Mockup data for 7 days, adjusted icons/colors for better match
      WeatherData(dynamicDayNames[0], 23, _getHeatIndexColor(23 * 4.5),
          Icons.wb_sunny), // Today
      WeatherData(dynamicDayNames[1], 24, _getHeatIndexColor(24 * 4.5),
          Icons.cloud), // Day 1
      WeatherData(dynamicDayNames[2], 22, _getHeatIndexColor(22 * 4.5),
          Icons.grain), // Day 2 (Rain/drizzle)
      WeatherData(dynamicDayNames[3], 23, _getHeatIndexColor(23 * 4.5),
          Icons.wb_sunny_outlined), // Day 3 (Sunny)
      WeatherData(dynamicDayNames[4], 21, _getHeatIndexColor(21 * 4.5),
          Icons.cloud), // Day 4 (Cloudy)
      WeatherData(dynamicDayNames[5], 26, _getHeatIndexColor(26 * 4.5),
          Icons.wb_sunny), // Day 5 (Sunny)
      WeatherData(dynamicDayNames[6], 22, _getHeatIndexColor(22 * 4.5),
          Icons.wb_sunny), // Day 6 (Sunny)
    ];

    _lastUpdatedTime = DateTime.now().subtract(
        const Duration(minutes: 4)); // To match "Updated 4 min ago" initially
  }

  // Generates dynamic day names for the next 7 days, starting with 'Today'
  List<String> _generateDynamicDayNames() {
    List<String> dayNames = [];
    DateTime now = DateTime.now();
    List<String> weekdayNames = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ];

    for (int i = 0; i < 7; i++) {
      DateTime currentDay = now.add(Duration(days: i));
      if (i == 0) {
        dayNames.add('Today');
      } else {
        dayNames.add(weekdayNames[currentDay.weekday - 1]);
      }
    }
    return dayNames;
  }

  Color _getHeatIndexColor(double heatIndex) {
    if (heatIndex < 80)
      return const Color(0xFF006400); // Dark Green (e.g., for 75)
    if (heatIndex < 100)
      return const Color(0xFF74B04C); // Light Green (e.g., for 85, 90)
    if (heatIndex < 150)
      return const Color(0xFFFDE49C); // Light Yellow (e.g., for 135)
    if (heatIndex < 200)
      return const Color(0xFFE59A45); // Orange (for higher values)
    return const Color(0xFFB5542E); // Reddish-Brown (for very high values)
  }

  String _getHeatIndexStatus(double heatIndex) {
    if (heatIndex < 100) return 'GOOD';
    if (heatIndex < 175) return 'NOT GOOD';
    return 'DANGEROUS';
  }

  IconData _getWeatherIcon(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
        return Icons.grain;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.blur_on; // Changed to blur_on for mist/fog
      default:
        return Icons.help_outline; // Default for unknown
    }
  }

  // Simplified heat index calculation (as per previous context)
  double _calculateHeatIndex(double tempCelsius, double humidity) {
    // This is a placeholder for a more accurate formula.
    // The actual heat index calculation is complex.
    // For demonstration, a simple linear relation with temp is used.
    // You might want to use a more accurate formula based on the
    // Steadman (1984) or the NWS formulas if precision is critical.
    return tempCelsius * 4.5;
  }

  Future<void> _fetchWeatherData(String location) async {
    if (location.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a location to search.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final forecastData = await _weatherService.fetchWeatherForecast(location);
      final currentData = await _weatherService.fetchCurrentWeather(location);

      _processWeatherData(forecastData, currentData);

      setState(() {
        _currentLocation = forecastData['city']['name'] ?? location;
        _isLoading = false;
        _lastUpdatedTime = DateTime
            .now(); // Set the update time to current time on successful fetch
      });
    } catch (e) {
      print('Error fetching data: $e'); // Log detailed error
      setState(() {
        _errorMessage =
            'Failed to fetch weather data for "$location". Please check the city name and internet connection.';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _processWeatherData(
      Map<String, dynamic> forecastData, Map<String, dynamic> currentData) {
    try {
      final List<dynamic> forecastList = forecastData['list'] ?? [];

      // Process current weather for heat index
      if (currentData['main'] != null) {
        final double currentTemp =
            (currentData['main']['temp'] ?? 20.0).toDouble();
        final double currentHumidity =
            (currentData['main']['humidity'] ?? 50.0).toDouble();
        _currentHeatIndex = _calculateHeatIndex(currentTemp, currentHumidity);
      }

      // Process hourly data for the next 24 hours (8 intervals of 3 hours) or up to 12 if available
      List<ChartData> newHourlyData = [];
      // Take up to 12 intervals if available, 3-hourly forecast gives 8 intervals per day
      for (int i = 0; i < math.min(12, forecastList.length); i++) {
        final forecast = forecastList[i];
        final DateTime dateTime =
            DateTime.fromMillisecondsSinceEpoch((forecast['dt'] ?? 0) * 1000);
        final double temp = (forecast['main']['temp'] ?? 20.0).toDouble();
        final double humidity =
            (forecast['main']['humidity'] ?? 50.0).toDouble();
        final double heatIndex = _calculateHeatIndex(temp, humidity);

        final hour =
            '${dateTime.hour.toString().padLeft(2, '0')}:00'; // Format as HH:00
        newHourlyData
            .add(ChartData(hour, heatIndex, _getHeatIndexColor(heatIndex)));
      }
      // If less than 12 hours are available from API, pad with placeholders
      while (newHourlyData.length < 12) {
        newHourlyData.add(ChartData(
            '${newHourlyData.length * 3}:00', 0, Colors.grey)); // Placeholder
      }

      // Process weekly data (for 7 days)
      List<WeatherData> newWeeklyData = [];
      Map<int, List<dynamic>> dailyForecastsAggregated = {}; // Key: day of year

      // Aggregate forecasts by day of year
      for (var forecast in forecastList) {
        final DateTime dateTime =
            DateTime.fromMillisecondsSinceEpoch((forecast['dt'] ?? 0) * 1000);
        final dayKey =
            DateTime(dateTime.year, dateTime.month, dateTime.day).dayOfYear;
        if (!dailyForecastsAggregated.containsKey(dayKey)) {
          dailyForecastsAggregated[dayKey] = [];
        }
        dailyForecastsAggregated[dayKey]!.add(forecast);
      }

      List<String> dayNames = _generateDynamicDayNames();
      DateTime now = DateTime.now();

      // Loop for 7 days to populate weekly weather
      for (int i = 0; i < 7; i++) {
        DateTime currentDayIterator = now.add(Duration(days: i));
        final dayKey = DateTime(currentDayIterator.year,
                currentDayIterator.month, currentDayIterator.day)
            .dayOfYear;

        if (dailyForecastsAggregated.containsKey(dayKey)) {
          List<dynamic> dayForecasts = dailyForecastsAggregated[dayKey]!;
          double totalTemp = 0;
          double totalHumidity = 0;
          String dominantWeather =
              'Clear'; // Default in case of no weather info

          // Find average temp/humidity and dominant weather for the day
          if (dayForecasts.isNotEmpty) {
            Map<String, int> weatherCounts = {};
            for (var forecast in dayForecasts) {
              totalTemp += (forecast['main']['temp'] ?? 20.0).toDouble();
              totalHumidity +=
                  (forecast['main']['humidity'] ?? 50.0).toDouble();
              String mainWeather =
                  forecast['weather'] != null && forecast['weather'].isNotEmpty
                      ? forecast['weather'][0]['main'] ?? 'Clear'
                      : 'Clear';
              weatherCounts[mainWeather] =
                  (weatherCounts[mainWeather] ?? 0) + 1;
            }
            // Determine dominant weather
            if (weatherCounts.isNotEmpty) {
              dominantWeather = weatherCounts.entries
                  .reduce((a, b) => a.value > b.value ? a : b)
                  .key;
            }
          }

          double avgTemp =
              dayForecasts.isEmpty ? 20 : totalTemp / dayForecasts.length;
          double avgHumidity =
              dayForecasts.isEmpty ? 50 : totalHumidity / dayForecasts.length;
          double avgHeatIndex = _calculateHeatIndex(avgTemp, avgHumidity);

          newWeeklyData.add(WeatherData(
            dayNames[i], // Use the generated day name
            avgTemp.round(),
            _getHeatIndexColor(avgHeatIndex),
            _getWeatherIcon(dominantWeather),
          ));
        } else {
          // No API data for this day (e.g., beyond 5 days forecast), use placeholder
          newWeeklyData.add(WeatherData(
            dayNames[i], // Use the generated day name
            20, // Default temperature
            Colors.grey, // Default color for unknown/no data
            Icons.help_outline, // Default icon
          ));
        }
      }

      setState(() {
        _hourlyData = newHourlyData;
        _weeklyWeather = newWeeklyData;
      });
    } catch (e) {
      print('Error processing weather data: $e');
      setState(() {
        _errorMessage = 'Error processing weather data internally.';
      });
    }
  }

  // Helper function to format the last updated time
  String _formatLastUpdatedTime() {
    if (_lastUpdatedTime == null) {
      return 'N/A';
    }
    final duration = DateTime.now().difference(_lastUpdatedTime!);
    if (duration.inMinutes < 1) {
      return 'just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hours ago';
    } else {
      // For longer than a day, show date
      return 'on ${_lastUpdatedTime!.day.toString().padLeft(2, '0')}/${_lastUpdatedTime!.month.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'Heatwaves Indicator - $_currentLocation', // Display current location in app bar
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0d47a1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Location Search Bar
                  TextField(
                    controller: _locationController,
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _fetchWeatherData(value);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Search for a location',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: IconButton(
                        // Added suffix icon for current location
                        icon: const Icon(Icons.my_location, color: Colors.grey),
                        onPressed: _fetchCurrentLocationAndWeatherData,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0d47a1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Main Gauge Display
                  HeatIndexGauge(
                    value: _currentHeatIndex,
                    status: _getHeatIndexStatus(_currentHeatIndex),
                  ),
                  const SizedBox(height: 60),

                  // Next Hours Chart Card
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Next hours',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _formatLastUpdatedTime(), // Dynamic update time
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 150,
                            child: SfCartesianChart(
                              plotAreaBorderWidth: 0,
                              margin: EdgeInsets.zero,
                              primaryXAxis: CategoryAxis(
                                axisLine: const AxisLine(width: 0),
                                majorTickLines: const MajorTickLines(size: 0),
                                majorGridLines: const MajorGridLines(width: 0),
                                labelStyle: const TextStyle(
                                  color: Color(0xFF616161),
                                  fontSize: 11,
                                ),
                              ),
                              primaryYAxis: const NumericAxis(
                                isVisible: true, // Made visible to show labels
                                minimum: 30, // Adjusted to match mockup
                                maximum: 150, // Adjusted to match mockup
                                interval:
                                    30, // Show labels at 30, 60, 90, 120, 150
                                labelStyle: TextStyle(
                                  color: Color(0xFF616161),
                                  fontSize: 11,
                                ),
                                axisLine:
                                    AxisLine(width: 0), // Remove Y-axis line
                                majorTickLines: MajorTickLines(
                                    size: 0), // Remove Y-axis ticks
                                majorGridLines: MajorGridLines(
                                    width: 0.5,
                                    color: Colors.grey,
                                    dashArray: <double>[
                                      5,
                                      5
                                    ]), // Thin dotted grid lines
                              ),
                              series: <CartesianSeries<ChartData, String>>[
                                ColumnSeries<ChartData, String>(
                                  dataSource: _hourlyData,
                                  xValueMapper: (ChartData data, _) =>
                                      data.time,
                                  yValueMapper: (ChartData data, _) =>
                                      data.value,
                                  pointColorMapper: (ChartData data, _) =>
                                      data.color,
                                  borderRadius: BorderRadius.circular(2),
                                  width: 0.4, // Made bars thinner
                                  spacing: 0.1,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Weather Forecast Card (This Week)
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Weather',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text('This week',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: _weeklyWeather.map((dayData) {
                              return Column(
                                children: [
                                  Text(
                                    dayData.day,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 84, 83, 83),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // ICON COLOR FIXED TO ORANGEACCENT FOR MOCKUP MATCH
                                  Icon(dayData.icon,
                                      color: Colors.orangeAccent, size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${dayData.temperature}°',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(
                                      height: 8), // Space for the bar
                                  // Tiny horizontal bar for heat index
                                  Container(
                                    height: 5,
                                    width: 25, // Adjusted width for the bar
                                    decoration: BoxDecoration(
                                      color: dayData
                                          .color, // Color based on heat index
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }
}

class ChartData {
  final String time;
  final double value;
  final Color color;

  ChartData(this.time, this.value, this.color);
}

class WeatherData {
  final String day;
  final int temperature;
  final Color
      color; // Color representing the heat index for the day (for the bar)
  final IconData icon;

  WeatherData(this.day, this.temperature, this.color, this.icon);
}
