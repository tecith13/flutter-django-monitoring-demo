import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 1. http 패키지 임포트
import 'dart:convert'; // JSON 파싱을 위한 패키지

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(), // 첫 화면으로 HomeScreen을 지정
    );
  }
}

// 화면이 바뀌어야 하므로 StatefulWidget을 사용합니다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 데이터를 담을 변수 (처음엔 비어있음)
  List<dynamic> stockData = [];
  bool isLoading = true; // 로딩 상태 표시용

  // 컴포넌트가 처음 켜질 떄 실행되는 함수 (Django의 ready나 웹의 useEffect 같은 것)
  @override
  void initState(){
    super.initState();
    fetchDataFromDjango(); // 화면이 켜지자마자 Django에 데이터 요청
  }

  // 2. Django API와 통신하는 비동기 함수
  Future<void> fetchDataFromDjango() async {
    try {
      final url = Uri.parse('http://10.0.2.2:8000/api/test/stocks/');

      final response = await http.get(url);

      if (response.statusCode == 200){
        // response.body(JSON 문자열)를 Dart의 List/Map 객체로 복호화
        final List<dynamic> decodeData = jsonDecode(response.body);

        // 중요 : setState를 호출해야 화면이 새로고침되면서 데이터가 변경됨.
        setState(() {
          stockData = decodeData;
          isLoading = false;
        });
      }else{
        print('서버 에러 : ${response.statusCode}');
      }
    }catch(e) {
      print('통신 실패 에러: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HaLoHaLo 모니터링')),
      // 삼항 연산자로 로딩 중일 때와 데이터가 나왔을 때의 화면을 스위칭
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // 로딩 중이면 스피너 표시
          : RefreshIndicator(onRefresh: fetchDataFromDjango, 
              child:Padding(
                padding: const EdgeInsets.all(16.0),
                child:  ListView.builder(
                  itemCount: stockData.length,
                  itemBuilder: (context, index) {
                    // Django에서 넘겨준 JSON 구조가 {'name': '삼성전자', 'status': '완료'} 라고 가정
                    final item = stockData[index]; 
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2, // 은은한 입체감(그림자) 추가
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 모서리 둥글게
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16), // 내부 여백 넉넉하게
                        leading: const Icon(Icons.analytics, color: Colors.blue, size: 28),
                        title: Text(
                          item['name'] ?? '이름 없음',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('Django 백엔드 실시간 연동 데이터'),
                        ),
                        // 🌟 우측에 텍스트 대신 '정규화 완료' 알약 모양 칩 배치
                        trailing: Chip(
                          label: Text(
                            item['status'] ?? '상태 없음',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          backgroundColor: item['status'] == '정규화 완료' 
                              ? Colors.blueAccent 
                              : Colors.orangeAccent, // 상태에 따라 색상 자동 변경
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onTap: () {
                          // 상세 화면으로 안전하게 JSON 데이터 전달하며 이동
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(stockInfo: item), // stockData[index] 대신 현재 매칭된 item을 그대로 전달
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              )
            ),
    );
  }
}

// 새로운 상세 화면 위젯
class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> stockInfo; // 이전 화면에서 넘겨받을 주식 데이터

  const DetailScreen({super.key, required this.stockInfo});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('${stockInfo['name']} 상세 분석'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: // 상세 화면(DetailScreen)의 점수 표시 부분 밑에 추가해보세요.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('분석 신뢰도 점수: ${stockInfo['score']}점'),
              const SizedBox(height: 8),
              // 💡 간이 막대 그래프 구현
              Container(
                height: 24,
                width: double.infinity, // 전체 너비
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      // score가 "85"라면 부모 너비의 85%만큼 게이지가 채워짐!
                      width: MediaQuery.of(context).size.width * (double.parse(stockInfo['score']) / 100) * 0.8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.blue, Colors.cyan]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
      ),
    );
  }
}
