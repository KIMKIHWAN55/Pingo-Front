import 'package:pingo_front/data/models/community_model/kakao_search_result.dart';
import 'package:pingo_front/data/models/community_model/review_search_result.dart';
import 'package:flutter/material.dart';

class PlaceReviewSearch {
  // [수정] final 키워드 추가 (권장사항)
  final KakaoSearchResult kakaoSearchResult;
  final ReviewSearchResult reviewSearchResult;

  PlaceReviewSearch(this.kakaoSearchResult, this.reviewSearchResult);

  PlaceReviewSearch copyWith({
    KakaoSearchResult? kakaoSearchResult,
    ReviewSearchResult? reviewSearchResult,
  }) {
    return PlaceReviewSearch(
      kakaoSearchResult ?? this.kakaoSearchResult,
      reviewSearchResult ?? this.reviewSearchResult,
    );
  }

  // [수정] toString이 클래스 내부에 있어야 합니다.
  @override
  String toString() {
    return 'PlaceReviewSearch{kakaoSearchResult: $kakaoSearchResult, reviewSearchResult: $reviewSearchResult}';
  }
} // [수정] 클래스는 여기서 끝나야 합니다.

// [참고] 이 맵은 클래스 외부에 있어도 상관없습니다.
Map<String, dynamic> kakaoCategory = {
  "음식점": Icons.restaurant,
  "카페": Icons.local_cafe,
  "관광명소": Icons.camera_alt,
  "숙박": Icons.hotel,
  "문화시설": Icons.theater_comedy,
  "대형마트": Icons.store_mall_directory,
  "편의점": Icons.local_convenience_store,
  "공공기관": Icons.apartment,
  "주차장": Icons.local_parking,
};