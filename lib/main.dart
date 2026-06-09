import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 1. http 패키지 임포트
import 'dart:convert'; // JSON 파싱을 위한 패키지

void main() {
  runApp(const MyApp());
}

// Django에서 받아온 JSON 데이터를 Flutter 안에서 다루기 쉽게 정리하는 모델 클래스
class StockItem {
  final String name;
  final String status;
  final double score;

  StockItem({
    required this.name,
    required this.status,
    required this.score,
  });

  // JSON(Map) 데이터를 StockItem 객체로 변환
  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      name: json['name']?.toString() ?? '이름 없음',
      status: json['status']?.toString() ?? '상태 없음',
      // score가 문자열이든 숫자든 최대한 안전하게 double로 변환
      score: double.tryParse(json['score']?.toString() ?? '0') ?? 0,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HaLoHaLo Monitor Demo',
      debugShowCheckedModeBanner: false, // 우측 상단 DEBUG 배너 제거
      home: const HomeScreen(), // 첫 화면으로 HomeScreen을 지정
    );
  }
}

// 화면이 바뀌어야 하므로 StatefulWidget을 사용
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 데이터를 담을 변수 (처음엔 비어있음)
  List<StockItem> stockData = [];

  bool isLoading = true; // 로딩 상태 표시용
  String? errorMessage; // 서버 통신 실패나 에러 메시지를 담는 변수

  // 컴포넌트가 처음 켜질 떄 실행되는 함수 (Django의 ready나 웹의 useEffect 같은 것)
  @override
  void initState() {
    super.initState();
    fetchDataFromDjango(); // 화면이 켜지자마자 Django에 데이터 요청
  }

  // 2. Django API와 통신하는 비동기 함수
  Future<void> fetchDataFromDjango() async {
    // 새로고침을 할 때마다 로딩 상태와 에러 메시지를 초기화
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Android Emulator에서 PC의 localhost에 접근할 때는 127.0.0.1 대신 10.0.2.2 사용
      final url = Uri.parse('http://10.0.2.2:8000/api/test/stocks/');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        // response.body(JSON 문자열)를 Dart의 List/Map 객체로 복호화
        final List<dynamic> decodedData = jsonDecode(response.body);

        // 중요 : setState를 호출해야 화면이 새로고침되면서 데이터가 변경됨.
        setState(() {
          stockData = decodedData
              .map((item) => StockItem.fromJson(item as Map<String, dynamic>))
              .toList();
          isLoading = false;
        });
      } else {
        print('서버 에러 : ${response.statusCode}');

        // 서버가 응답은 했지만 200이 아닐 때도 로딩을 끝내고 에러 화면으로 전환
        setState(() {
          errorMessage = '서버 응답 오류: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('통신 실패 에러: $e');

      // 통신 자체가 실패했을 때도 로딩을 끝내고 에러 화면으로 전환
      setState(() {
        errorMessage = '데이터를 불러오지 못했습니다.';
        isLoading = false;
      });
    }
  }

  // 상태값에 따라 Chip 색상을 결정하는 함수
  Color getStatusColor(String status) {
    return status == '정규화 완료' ? Colors.blueAccent : Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HaLoHaLo 모니터링'),
      ),
      // 삼항 연산자 대신 상태별 화면을 따로 분리해서 가독성 개선
      body: buildBody(),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(), // 로딩 중이면 스피너 표시
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: fetchDataFromDjango,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchDataFromDjango,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: stockData.length,
          itemBuilder: (context, index) {
            // Django에서 넘겨준 JSON 구조가 {'name': '삼성전자', 'status': '완료'} 라고 가정
            final item = stockData[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2, // 은은한 입체감(그림자) 추가
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // 모서리 둥글게
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16), // 내부 여백 넉넉하게
                leading: const Icon(
                  Icons.analytics,
                  color: Colors.blue,
                  size: 28,
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Django 백엔드 실시간 연동 데이터'),
                ),
                // 🌟 우측에 텍스트 대신 '정규화 완료' 알약 모양 칩 배치
                trailing: Chip(
                  label: Text(
                    item.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: getStatusColor(item.status), // 상태에 따라 색상 자동 변경
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onTap: () {
                  // 상세 화면으로 안전하게 StockItem 데이터 전달하며 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(stockInfo: item),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// 새로운 상세 화면 위젯
class DetailScreen extends StatelessWidget {
  final StockItem stockInfo; // 이전 화면에서 넘겨받을 주식 데이터

  const DetailScreen({super.key, required this.stockInfo});

  @override
  Widget build(BuildContext context) {
    // 점수를 0~1 사이 값으로 변환해서 진행률 바에 사용
    final scoreRate = (stockInfo.score / 100).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('${stockInfo.name} 상세 분석'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: // 상세 화면(DetailScreen)의 점수 표시 부분 밑에 추가해보세요.
            Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('분석 신뢰도 점수: ${stockInfo.score.toInt()}점'),
            const SizedBox(height: 8),
            // 💡 간이 막대 그래프 구현
            Container(
              height: 24,
              width: double.infinity, // 전체 너비
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                // score가 85라면 부모 너비의 85%만큼 게이지가 채워짐!
                widthFactor: scoreRate,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.cyan],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
