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
  DateTime? _lastUpdate;
  final _cacheTimeout = Duration(minutes: 30);


  double _latitude = 36.7923; // 서울시청 위도
  double _longitude = 127.0039; // 서울시청 경도
  bool _useManualLocation = true; // 수동 위치 사용 여부

  // 서울
// _latitude = 37.5665;
// _longitude = 126.9780;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  String _getClothingRecommendation(double temp, String weatherMain) {
    if (weatherMain == 'Rain' || weatherMain == 'Drizzle' || weatherMain == 'Thunderstorm') {
      return '우산을 챙기세요! 🌂';
    }
    if (temp <= -5) {
      return '패딩(코트), 목도리, 장갑 착용 필수!';
    } else if (temp <= 0) {
      return '두꺼운 코트, 목도리 추천';
    } else if (temp <= 5) {
      return '코트, 가죽자켓, 히트텍 추천';
    } else if (temp <= 9) {
      return '자켓, 트렌치코트, 니트 추천';
    } else if (temp <= 12) {
      return '자켓, 가디건, 청자켓 추천';
    } else if (temp <= 17) {
      return '얇은 니트, 맨투맨, 가디건 추천';
    } else if (temp <= 20) {
      return '긴팔, 얇은 가디건 추천';
    } else if (temp <= 23) {
      return '반팔, 얇은 셔츠 추천';
    } else if (temp <= 27) {
      return '반팔, 반바지 추천';
    } else {
      return '민소매, 반바지, 선크림 필수!';
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




  Future<void> _fetchWeather() async {
    try {
      late Position position;

      if (_useManualLocation) {
        // 수동으로 설정한 위치 사용
        position = Position(
          latitude: _latitude,
          longitude: _longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      } else {
        // 실제 위치 가져오기 시도
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 10),
          );
        }
      }

      print('사용 중인 위치: 위도=${position.latitude}, 경도=${position.longitude}');

      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=d5c14019c3cf59a500dd2164f0b250db&units=metric&lang=kr'
      ));

      if (response.statusCode == 200) {
        final weatherData = json.decode(response.body);
        print('날씨 데이터: $weatherData');

        final temp = weatherData['main']['temp'].round();
        final weatherMain = weatherData['weather'][0]['main'];
        final weatherDesc = weatherData['weather'][0]['description'];
        final cityName = weatherData['name'];
        final humidity = weatherData['main']['humidity'];
        final feelsLike = weatherData['main']['feels_like'].round();

        if (temp < -50 || temp > 50) {
          throw Exception('비정상적인 온도 값: $temp°C');
        }

        print('계산된 온도: $temp°C');
        print('체감 온도: $feelsLike°C');
        print('습도: $humidity%');
        print('도시: $cityName');

        setState(() {
          _temperature = '${temp}°C';
          _weatherDescription = '${_getKoreanWeatherDescription(weatherMain, weatherDesc)} / 체감 ${feelsLike}°C';
          _weatherIcon = _getWeatherIcon(weatherMain);
          _clothingRecommendation = _getClothingRecommendation(temp.toDouble(), weatherMain);
          _lastUpdate = DateTime.now();
        });
      } else {
        print('API 오류: ${response.statusCode}');
        throw Exception('날씨 데이터를 가져오는데 실패했습니다.');
      }
    } catch (e) {
      print('에러 발생: $e');
      setState(() {
        _temperature = '-';
        _weatherDescription = '날씨 정보 불러오기 실패';
        _clothingRecommendation = '';
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
                    SizedBox(height: 4),
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

        ],
      ),
    );
  }
}
