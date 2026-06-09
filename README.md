# flutter-django-monitoring-demo

Django REST API와 Flutter 앱 간의 데이터 연동 흐름을 학습하기 위해 제작한 포트폴리오용 샘플 프로젝트입니다.

Flutter 앱에서 Django 로컬 서버의 JSON 응답을 비동기로 받아오고, 종목 리스트 및 상세 화면에 반영하는 구조를 구현했습니다.

본 프로젝트는 포트폴리오용 샘플이며, 실제 업무 코드나 내부 데이터는 포함하지 않습니다.

## 주요 기능

- Flutter 기반 종목 리스트 화면 구현
- Django 로컬 REST API에서 JSON 데이터 수신
- Dart async/await 기반 비동기 요청 처리
- API 응답 데이터를 리스트 UI에 반영
- 종목별 처리 상태 뱃지 표시
- Navigator 기반 상세 화면 이동
- 상세 화면에서 분석 신뢰도 점수 시각화
