import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:pingo_front/_core/utils/logger.dart';
import 'package:pingo_front/data/models/community_model/kakao_search.dart';

class KakaoMapScreen extends StatefulWidget {
  final KakaoSearch kakaoSearch;
  KakaoMapScreen(this.kakaoSearch, {super.key});

  @override
  State<KakaoMapScreen> createState() => _KakaoMapScreenState();
}

class _KakaoMapScreenState extends State<KakaoMapScreen> {
  KakaoMapController? mapController;
  LatLng? _latLng;
  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();

    // [수정 포인트] ! (강제) 대신 ?? (기본값) 사용
    // 데이터가 null이면 0.0으로 처리하거나, 특정 기본 좌표(예: 서울)를 넣습니다.
    // 만약 kakaoSearch.latitude가 String 타입이라면 double.parse가 필요할 수 있습니다.
    // 아래 코드는 latitude가 double? 타입이라고 가정했을 때의 수정입니다.

    double lat = widget.kakaoSearch.latitude ?? 37.5665; // 값이 없으면 서울 위도
    double lng = widget.kakaoSearch.longitude ?? 126.9780; // 값이 없으면 서울 경도

    _latLng = LatLng(lat, lng);

    logger.i('검색한 위도: $lat, 경도: $lng');
  }

  @override
  Widget build(BuildContext context) {
    // 안전 장치: _latLng가 혹시라도 생성되지 않았다면 로딩 표시
    if (_latLng == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return KakaoMap(
      center: _latLng!, // 위에서 기본값을 넣었으므로 여기는 ! 써도 안전함
      onMapCreated: (controller) async {
        mapController = controller;

        markers = [
          Marker(
            markerId: 'search_marker',
            latLng: _latLng!,
          ),
        ];

        await mapController?.setCenter(_latLng!);
        await mapController?.addMarker(markers: markers);

        logger.i('setCenter 및 setMarkers 적용 완료');
      },
      markers: markers,
      currentLevel: 3,
    );
  }
}