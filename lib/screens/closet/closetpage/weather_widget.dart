import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class WeatherWidget extends StatefulWidget {
  @override
  WeatherWidgetState createState() => WeatherWidgetState();
}

class WeatherWidgetState extends State<WeatherWidget> {
  String _temperature = '-';
  String _weatherDescription = '로딩 중';
  String _weatherIcon = '☀️';
  String _clothingRecommendation = '';

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  String _getKoreanWeatherDescription(String weatherMain, String description) {
    final Map<String, String> weatherTranslations = {
      'Thunderstorm': '천둥번개',
      'Drizzle': '이슬비',
      'Rain': '비',
      'Snow': '눈',
      'Clear': '맑음',
      'Clouds': '구름',
      'Mist': '안개',
      'Smoke': '연기',
      'Haze': '실안개',
      'Dust': '먼지',
      'Fog': '안개',
      'Sand': '황사',
      'Ash': '화산재',
      'Squall': '돌풍',
      'Tornado': '토네이도',
      // 세부 날씨 상태 번역
      'scattered clouds': '구름 조금',
      'broken clouds': '구름 많음',
      'overcast clouds': '흐림',
      'few clouds': '구름 적음',
      'light rain': '약한 비',
      'moderate rain': '비',
      'heavy rain': '강한 비',
      'clear sky': '맑음',
    };

    return weatherTranslations[description] ??
        weatherTranslations[weatherMain] ??
        '날씨 정보 없음';
  }

  String _getClothingRecommendation(double temp, String weatherMain) {
    if (weatherMain == 'Rain' || weatherMain == 'Drizzle') {
      return '우산을 챙기세요!';
    }
    if (temp <= 0) {
      return '온 세상이 얼었어요!';
    } else if (temp <= 3) {
      return '감기조심 하세요!';
    } else if (temp <= 9) {
      return '쌀쌀해요';
    } else if (temp <= 16) {
      return '가벼운 겉옷 입세요!';
    } else if (temp <= 22) {
      return '따듯해요'!;
    } else if (temp <= 27) {
      return '매우 더워요!';
    } else {
      return '시원하게 입으세요!';
    }
  }

  Future<void> _fetchWeather() async {
    try {
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
          final temp = weatherData['main']['temp'].round();
          final weatherMain = weatherData['weather'][0]['main'];
          final weatherDesc = weatherData['weather'][0]['description'];

          setState(() {
            _temperature = '${temp}°C';
            _weatherDescription = _getKoreanWeatherDescription(weatherMain, weatherDesc);
            _weatherIcon = _getWeatherIcon(weatherMain);
            _clothingRecommendation = _getClothingRecommendation(temp.toDouble(), weatherMain);
          });
        }
      }
    } catch (e) {
      setState(() {
        _temperature = '-';
        _weatherDescription = '날씨 정보 불러오기 실패';
        _clothingRecommendation = '';
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _temperature,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _weatherDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 4),
                Text(
                  _clothingRecommendation,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}