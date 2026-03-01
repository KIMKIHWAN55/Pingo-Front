import 'package:pingo_front/data/models/community_model/place_review.dart';

class ReviewSearchResult {
  // [수정 1] 불변성을 위해 모든 필드를 final로 선언
  final String searchSort;
  final String cateSort;
  final List<PlaceReview> placeReviewList;

  // [수정 2] 생성자 최적화 (Named Parameters 사용, 기본값 설정)
  ReviewSearchResult({
    this.searchSort = 'popular',
    this.cateSort = '음식점',
    this.placeReviewList = const [], // null 대신 빈 리스트를 기본값으로 설정하여 안전성 확보
  });

  // [수정 3] 핵심: 값을 변경한 '새로운 객체'를 반환하는 copyWith 메서드 구현
  ReviewSearchResult copyWith({
    String? searchSort,
    String? cateSort,
    List<PlaceReview>? placeReviewList,
  }) {
    return ReviewSearchResult(
      searchSort: searchSort ?? this.searchSort,
      cateSort: cateSort ?? this.cateSort,
      placeReviewList: placeReviewList ?? this.placeReviewList,
    );
  }

  @override
  String toString() {
    return 'ReviewSearchResult{searchSort: $searchSort, cateSort: $cateSort, placeReviewList: ${placeReviewList.length}개}';
  }
}