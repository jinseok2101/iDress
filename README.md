#  iDress – 우리아이옷장

유아·아동 의류를 **옷장**을 통해 한눈에 관리하고, **가상 피팅**을 통해 아이에게 어울리는 스타일을 직관적으로 확인할 수 있는 모바일 애플리케이션입니다.  
부모는 자녀별 옷장을 따로 생성·구분할 수 있으며, 옷 이미지 업로드 시 **AI 분석을 통해 자동으로 카테고리가 분류되는 기능**을 제공합니다.

---

## 👥 Team Members

| 이름 | 포지션 | 주요 기여 |
|------|--------|-----------|
| 이진석 | Frontend / Backend | 앱 전체 UI 구현, 서버 및 데이터 구조 설계 |
| 홍길동 | Backend | FastAPI 기반 API 및 AI 로직 개발 |
| 김철수 | Designer | 사용자 흐름 기반 UI/UX 설계 |



##  주요 기능

| 기능 | 설명 |
|------|------|
|  자녀별 옷장 분리 관리 | Child1, Child2 등 자녀별로 옷 데이터를 독립적으로 관리 |
|  카테고리 필터링 | 상의·하의·원피스·외투 등 카테고리 기반 필터링 |
|  가상 피팅룸 UI | 선택한 옷을 아동 이미지 위에 배치하여 착용 미리보기 |
|  AI 자동 이미지 분석 | 옷 이미지 업로드 시 AI가 자동으로 카테고리 분류 |
|  옷 검색 기능 | 이름 및 태그 기반 실시간 검색 |
|  옷 추가/삭제/수정/즐겨찾기 | Firebase Realtime Database 기반 실시간 동기화 |
|  클라우드 저장 | Firebase Storage로 이미지 저장 |
|  날씨에 따른 옷 추천 | Geolocator 기반 위치 정보를 활용해 현재 날씨에 맞는 의류 카테고리를 추천 |

##  시스템 아키텍처

<p align="center">
  <a href="./assets/images/architecture.png">
    <img src="./assets/images/architecture.png" alt="System Architecture" width="700"/>
    <img src="./assets/images/architecture2.png" alt="System Architecture" width="700"/>
  </a>
</p>


##  기술 스택

| 분야 | 기술 |
|------|------|
| **언어** | Dart |
| **프레임워크** | Flutter + FastAPI |
| **프론트엔드** | Flutter (Mobile UI/UX – REST API 통신) |
| **백엔드** | Python |
| **데이터베이스 & 인증** | Firebase |
| **AI 서비스** | Gemini API + Hugging Face |
| **검색 엔진** | Qdrant |
| **클라우드 플랫폼** | Google Cloud Platform(GCP) |
| **협업 도구** | Git, Google Cloud, Figma |


##  UI/UX Design (Figma) 
👉 [디자인 시안 확인하기](https://www.figma.com/design/9PPMqKro2PIpiOZuxsXlmZ/%EC%B5%9C%EC%A2%85%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8-UI?node-id=0-1&p=f)



##  시연 영상

[![Demo Video](https://img.youtube.com/vi/8ebOLxhSA3Y/0.jpg)](https://www.youtube.com/watch?v=8ebOLxhSA3Y)
