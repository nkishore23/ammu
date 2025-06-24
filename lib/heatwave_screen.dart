import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart' as gauges;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

// Weather Service with proper API integration
class WeatherService {
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
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
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
            'Failed to load current weather: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

class HeatwavesIndicatorScreen extends StatefulWidget {
  @override
  _HeatwavesIndicatorScreenState createState() =>
      _HeatwavesIndicatorScreenState();
}

class _HeatwavesIndicatorScreenState extends State<HeatwavesIndicatorScreen> {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _locationController = TextEditingController();

  bool _isLoading = false;
  String _currentLocation = 'Your Location';
  double _currentHeatIndex = 150; // Default value matching mockup
  List<ChartData> _hourlyData = [];
  List<WeatherData> _weeklyWeather = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeDefaultData();
  }

  void _initializeDefaultData() {
    // Show default data matching the mockup
    _hourlyData = [
      ChartData('03', 75, _getHeatIndexColor(75)),
      ChartData('06', 90, _getHeatIndexColor(90)),
      ChartData('09', 95, _getHeatIndexColor(95)),
      ChartData('12', 135, _getHeatIndexColor(135)), // Peak hour
      ChartData('15', 115, _getHeatIndexColor(115)),
      ChartData('18', 85, _getHeatIndexColor(85)),
      ChartData('21', 70, _getHeatIndexColor(70)),
      ChartData('00', 65, _getHeatIndexColor(65)),
      ChartData('03', 70, _getHeatIndexColor(70)),
      ChartData('06', 80, _getHeatIndexColor(80)),
      ChartData('09', 90, _getHeatIndexColor(90)),
      ChartData('12', 85, _getHeatIndexColor(85)),
    ];

    _weeklyWeather = [
      WeatherData('Today', 22, Colors.green, Icons.wb_sunny),
      WeatherData('Mon', 24, Colors.yellow, Icons.cloud),
      WeatherData('Tue', 22, Colors.green, Icons.grain),
      WeatherData('Wed', 23, Colors.green, Icons.wb_sunny_outlined),
      WeatherData('Thu', 21, Colors.yellow, Icons.cloud),
      WeatherData('Fri', 26, Colors.red, Icons.wb_sunny),
      WeatherData('Sat', 22, Colors.green, Icons.wb_sunny),
    ];
  }

  Color _getHeatIndexColor(double heatIndex) {
    if (heatIndex < 80) return Colors.green;
    if (heatIndex < 90) return Colors.lightGreen;
    if (heatIndex < 105) return Colors.yellow[700]!;
    if (heatIndex < 130) return Colors.orange;
    return Colors.red;
  }

  String _getHeatIndexStatus(double heatIndex) {
    if (heatIndex < 80) return 'GOOD';
    if (heatIndex < 90) return 'CAUTION';
    if (heatIndex < 105) return 'EXTREME CAUTION';
    if (heatIndex < 130) return 'DANGER';
    return 'NOT GOOD'; // Changed to match mockup
  }

  IconData _getWeatherIcon(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'drizzle':
        return Icons.grain;
      case 'mist':
      case 'fog':
        return Icons.cloud;
      default:
        return Icons.wb_sunny;
    }
  }

  double _calculateHeatIndex(double tempCelsius, double humidity) {
    // Convert Celsius to Fahrenheit
    double tempF = (tempCelsius * 9 / 5) + 32;

    // Simplified heat index calculation
    if (tempF < 80) {
      return tempF; // Return Fahrenheit value for consistency
    }

    // Rothfusz regression equation
    double hi = -42.379 +
        2.04901523 * tempF +
        10.14333127 * humidity -
        0.22475541 * tempF * humidity -
        0.00683783 * tempF * tempF -
        0.05481717 * humidity * humidity +
        0.00122874 * tempF * tempF * humidity +
        0.00085282 * tempF * humidity * humidity -
        0.00000199 * tempF * tempF * humidity * humidity;

    // Adjustments for low humidity
    if (humidity < 13 && tempF >= 80 && tempF <= 112) {
      hi -= ((13 - humidity) / 4) * math.sqrt((17 - (tempF - 95).abs()) / 17);
    }

    // Adjustments for high humidity
    if (humidity > 85 && tempF >= 80 && tempF <= 87) {
      hi += ((humidity - 85) / 10) * ((87 - tempF) / 5);
    }

    return hi;
  }

  Future<void> _fetchWeatherData(String location) async {
    if (location.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch both current weather and forecast
      final forecastData = await _weatherService.fetchWeatherForecast(location);
      final currentData = await _weatherService.fetchCurrentWeather(location);

      _processWeatherData(forecastData, currentData);

      setState(() {
        _currentLocation = forecastData['city']['name'] ?? location;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Failed to fetch weather data for "$location". Please check the city name and try again.';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Unable to fetch weather data'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
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

      // Process hourly data (next 24 hours - extended for better chart view)
      List<ChartData> newHourlyData = [];
      for (int i = 0; i < math.min(12, forecastList.length); i++) {
        final forecast = forecastList[i];
        final DateTime dateTime =
            DateTime.fromMillisecondsSinceEpoch((forecast['dt'] ?? 0) * 1000);
        final double temp = (forecast['main']['temp'] ?? 20.0).toDouble();
        final double humidity =
            (forecast['main']['humidity'] ?? 50.0).toDouble();
        final double heatIndex = _calculateHeatIndex(temp, humidity);

        final hour = dateTime.hour.toString().padLeft(2, '0');
        newHourlyData
            .add(ChartData(hour, heatIndex, _getHeatIndexColor(heatIndex)));
      }

      // Process weekly data (group by day)
      List<WeatherData> newWeeklyData = [];
      Map<String, List<dynamic>> dailyForecasts = {};

      // Group forecasts by day
      for (int i = 0; i < forecastList.length; i++) {
        final forecast = forecastList[i];
        final DateTime dateTime =
            DateTime.fromMillisecondsSinceEpoch((forecast['dt'] ?? 0) * 1000);
        final dayKey = '${dateTime.year}-${dateTime.month}-${dateTime.day}';

        if (!dailyForecasts.containsKey(dayKey)) {
          dailyForecasts[dayKey] = [];
        }
        dailyForecasts[dayKey]!.add(forecast);
      }

      // Process daily forecasts
      List<String> dayNames = [
        'Today',
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat'
      ];
      int dayIndex = 0;

      dailyForecasts.forEach((dayKey, dayForecasts) {
        if (dayIndex < 7 && dayForecasts.isNotEmpty) {
          // Calculate average temperature for the day
          double totalTemp = 0;
          double totalHumidity = 0;
          String dominantWeather =
              dayForecasts[0]['weather'][0]['main'] ?? 'Clear';

          for (var forecast in dayForecasts) {
            totalTemp += (forecast['main']['temp'] ?? 20.0).toDouble();
            totalHumidity += (forecast['main']['humidity'] ?? 50.0).toDouble();
          }

          double avgTemp = totalTemp / dayForecasts.length;
          double avgHumidity = totalHumidity / dayForecasts.length;
          double avgHeatIndex = _calculateHeatIndex(avgTemp, avgHumidity);

          newWeeklyData.add(WeatherData(
            dayNames[dayIndex],
            avgTemp.round(),
            _getHeatIndexColor(avgHeatIndex),
            _getWeatherIcon(dominantWeather),
          ));
          dayIndex++;
        }
      });

      setState(() {
        _hourlyData = newHourlyData;
        _weeklyWeather = newWeeklyData;
      });
    } catch (e) {
      print('Error processing weather data: $e');
      setState(() {
        _errorMessage = 'Error processing weather data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xFF003366), // Matching the blue from mockup
        title: Text(
          'Heatwaves Indicator',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Location Search Bar - Matching mockup style
            Container(
              margin: EdgeInsets.only(bottom: 24),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[400], size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: _currentLocation,
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _fetchWeatherData(value);
                        }
                      },
                    ),
                  ),
                  if (_isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

            // Main Gauge Card - Redesigned to match mockup exactly
            Container(
              margin: EdgeInsets.only(bottom: 24),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 15,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 280,
                    child: gauges.SfRadialGauge(
                      axes: <gauges.RadialAxis>[
                        gauges.RadialAxis(
                          minimum: 50,
                          maximum: 200,
                          startAngle: 180,
                          endAngle: 0,
                          showLabels: true,
                          showTicks: true,
                          interval: 50,
                          labelOffset: 15,
                          tickOffset: -2,
                          minorTicksPerInterval: 0,
                          axisLineStyle: gauges.AxisLineStyle(
                            thickness: 1,
                            color: Colors.grey[300],
                          ),
                          majorTickStyle: gauges.MajorTickStyle(
                            length: 8,
                            thickness: 1,
                            color: Colors.grey[400],
                          ),
                          ranges: <gauges.GaugeRange>[
                            // Green range (Good) - 50 to 100
                            gauges.GaugeRange(
                              startValue: 50,
                              endValue: 100,
                              color: Colors.green,
                              startWidth: 20,
                              endWidth: 20,
                            ),
                            // Yellow range - 100 to 150
                            gauges.GaugeRange(
                              startValue: 100,
                              endValue: 150,
                              color: Colors.yellow[700]!,
                              startWidth: 20,
                              endWidth: 20,
                            ),
                            // Orange/Red range - 150 to 200
                            gauges.GaugeRange(
                              startValue: 150,
                              endValue: 200,
                              color: Colors.deepOrange,
                              startWidth: 20,
                              endWidth: 20,
                            ),
                          ],
                          pointers: <gauges.GaugePointer>[
                            gauges.NeedlePointer(
                              value: _currentHeatIndex,
                              enableAnimation: true,
                              animationDuration: 1500,
                              animationType: gauges.AnimationType.easeOutBack,
                              needleColor: Colors.black,
                              needleStartWidth: 1,
                              needleEndWidth: 4,
                              needleLength: 0.8,
                              knobStyle: gauges.KnobStyle(
                                color: Colors.black,
                                borderColor: Colors.black,
                                borderWidth: 0.5,
                                knobRadius: 8,
                              ),
                            )
                          ],
                          annotations: <gauges.GaugeAnnotation>[
                            gauges.GaugeAnnotation(
                              widget: Container(
                                padding: EdgeInsets.only(top: 40),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _currentHeatIndex.round().toString(),
                                      style: TextStyle(
                                        fontSize: 72,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                        height: 1.0,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _getHeatIndexStatus(_currentHeatIndex),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Heat Ratio',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              angle: 90,
                              positionFactor: 0.5,
                            )
                          ],
                          axisLabelStyle: gauges.GaugeTextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Low',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'High',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Next Hours Chart Card - Redesigned to match mockup
            Container(
              margin: EdgeInsets.only(bottom: 24),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 15,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Next hours',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _isLoading ? 'Updating...' : 'Updated 4 min ago',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: 180,
                    child: SfCartesianChart(
                      plotAreaBorderWidth: 0,
                      margin: EdgeInsets.zero,
                      primaryXAxis: CategoryAxis(
                        axisLine: AxisLine(width: 0),
                        majorTickLines: MajorTickLines(size: 0),
                        majorGridLines: MajorGridLines(width: 0),
                        labelStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      primaryYAxis: NumericAxis(
                        isVisible: false,
                        minimum: 30,
                        maximum: 150,
                      ),
                      series: <CartesianSeries<ChartData, String>>[
                        ColumnSeries<ChartData, String>(
                          dataSource: _hourlyData,
                          xValueMapper: (ChartData data, _) => data.time,
                          yValueMapper: (ChartData data, _) => data.value,
                          pointColorMapper: (ChartData data, _) => data.color,
                          borderRadius: BorderRadius.circular(3),
                          width: 0.7,
                          spacing: 0.1,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Weather Forecast Card - Redesigned to match mockup
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 15,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weather',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'This week',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _weeklyWeather.map((weather) {
                      return Expanded(
                        child: Column(
                          children: [
                            Text(
                              weather.day,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: 30,
                              height: 4,
                              decoration: BoxDecoration(
                                color: weather.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '${weather.temperature}°',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Icon(
                              weather.icon,
                              size: 24,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
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
  final Color color;
  final IconData icon;

  WeatherData(this.day, this.temperature, this.color, this.icon);
}
