import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class WeatherWidget extends StatefulWidget {
  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  String _temperature = '-';
  String _weatherDescription = '로딩 중';
  String _weatherIcon = '☀️';

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      // 위치 권한 확인 및 요청
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high
        );

        final response = await http.get(Uri.parse(
            'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=c2cb1b4c5a2722de1dc28439212da41c&units=metric'
        ));

        if (response.statusCode == 200) {
          final weatherData = json.decode(response.body);
          setState(() {
            _temperature = '${weatherData['main']['temp'].round()}°C';
            _weatherDescription = weatherData['weather'][0]['description'];
            _weatherIcon = _getWeatherIcon(weatherData['weather'][0]['main']);
          });
        }
      }
    } catch (e) {
      setState(() {
        _temperature = '-';
        _weatherDescription = '날씨 정보 불러오기 실패';
      });
    }
  }

  String _getWeatherIcon(String weatherMain) {
    switch (weatherMain) {
      case 'Thunderstorm': return '⛈️';
      case 'Drizzle': return '🌦️';
      case 'Rain': return '🌧️';
      case 'Snow': return '❄️';
      case 'Clear': return '☀️';
      case 'Clouds': return '☁️';
      case 'Mist':
      case 'Smoke':
      case 'Haze':
      case 'Dust':
      case 'Fog':
      case 'Sand':
      case 'Ash':
      case 'Squall':
      case 'Tornado':
        return '🌫️';
      default: return '🌈';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            _weatherIcon,
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _temperature,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _weatherDescription,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}