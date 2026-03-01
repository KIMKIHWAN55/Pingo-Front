import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pingo_front/_core/utils/logger.dart';
import 'package:pingo_front/data/models/community_model/kakao_search.dart';
import 'package:pingo_front/data/models/community_model/kakao_search_result.dart';
import 'package:pingo_front/data/models/community_model/place_review.dart';
import 'package:pingo_front/data/models/community_model/place_review_search.dart';
import 'package:pingo_front/data/models/community_model/review_search_result.dart';
import 'package:pingo_front/data/models/global_model/session_user.dart';
import 'package:pingo_front/data/repository/community_repository/place_review_search_repository.dart';
import 'package:pingo_front/data/view_models/sign_view_model/signin_view_model.dart';

class PlaceReviewSearchViewModel extends Notifier<PlaceReviewSearch> {
  final PlaceReviewSearchRepository _repository;
  KakaoSearch lastSearch = KakaoSearch();

  PlaceReviewSearchViewModel(this._repository);

  @override
  PlaceReviewSearch build() {
    // 1. 비동기 초기화 (렌더링 충돌 방지)
    Future.microtask(() => placeReviewInit());

    // [수정 포인트 1] ReviewSearchResult()로 호출 (기본값 빈 리스트가 자동으로 들어감)
    // KakaoSearchResult는 기존 모델을 유지한다고 가정하여 리스트를 넣습니다.
    return PlaceReviewSearch(
        KakaoSearchResult([]),
        ReviewSearchResult() // 기존 오류 해결: [] 제거 -> 내부에서 기본값 빈리스트 처리됨
    );
  }

  // init
  Future<void> placeReviewInit() async {
    try {
      final currentCate = state.reviewSearchResult.cateSort;
      final currentSort = state.reviewSearchResult.searchSort;

      dynamic response = await _repository.fetchSearchPlaceReview(
          cateSort: currentCate,
          searchSort: currentSort);

      logger.i("초기화 데이터 로드 완료: ${response.length}개");

      // [수정 포인트 2] copyWith 사용
      state = PlaceReviewSearch(
        state.kakaoSearchResult,
        state.reviewSearchResult.copyWith(placeReviewList: response),
      );
    } catch (e) {
      logger.e("placeReviewInit 에러", error: e);
    }
  }

  // 게시글 좋아요
  Future<String> clickThumbUp(String userNo, String prNo) async {
    return await _repository.fetchClickThumbUp(userNo, prNo);
  }

  // 검색 정렬 기준 변경
  Future<void> changeSearchSort(String newSort) async {
    List<PlaceReview> response = [];

    try {
      if (newSort == 'location') {
        SessionUser sessionUser = ref.read(sessionProvider);
        Position? position = sessionUser.currentLocation;

        if (position == null) {
          logger.w("위치 정보를 가져올 수 없습니다.");
          return;
        }

        response = await _repository.fetchSearchPlaceReviewWithLocation(
            cateSort: state.reviewSearchResult.cateSort,
            latitude: position.latitude,
            longitude: position.longitude);
      } else {
        response = await _repository.fetchSearchPlaceReview(
            cateSort: state.reviewSearchResult.cateSort,
            searchSort: newSort);
      }

      // [수정 포인트 3] 상태 업데이트
      state = PlaceReviewSearch(
        state.kakaoSearchResult,
        state.reviewSearchResult.copyWith(
          placeReviewList: response,
          searchSort: newSort,
        ),
      );

      logger.i("정렬 변경 완료: $newSort, 개수: ${response.length}");

    } catch (e) {
      logger.e("정렬 변경 에러", error:e);
    }
  }

  // 검색 카테고리 기준 변경
  Future<void> changeCateSort(String newSort) async {
    try {
      List<PlaceReview> response = await _repository.fetchSearchPlaceReview(
          cateSort: newSort, searchSort: 'popular');

      state = PlaceReviewSearch(
        state.kakaoSearchResult,
        state.reviewSearchResult.copyWith(
          cateSort: newSort,
          searchSort: 'popular',
          placeReviewList: response,
        ),
      );
    } catch (e) {
      logger.e("카테고리 변경 에러", error:e);
    }
  }

  // 검색창이 비었을 때 마지막 검색 기록으로 돌리기
  Future<void> searchLastPlaceReview() async {
    try {
      List<PlaceReview> response = await _repository.fetchSearchPlaceReview(
          cateSort: state.reviewSearchResult.cateSort,
          searchSort: state.reviewSearchResult.searchSort);

      state = PlaceReviewSearch(
        state.kakaoSearchResult,
        state.reviewSearchResult.copyWith(placeReviewList: response),
      );
    } catch (e) {
      logger.e("마지막 검색 기록 복원 에러", error:e);
    }
  }

  // 검색으로 리뷰 조회
  Future<void> searchPlaceReviewWithKeyword(KakaoSearch kakaoSearch) async {
    try {
      List<PlaceReview> response = await _repository.fetchSearchPlaceReview(
          cateSort: state.reviewSearchResult.cateSort,
          searchSort: state.reviewSearchResult.searchSort,
          keyword: kakaoSearch.addressName);

      if (response.isEmpty) {
        lastSearch = kakaoSearch;
      }

      state = PlaceReviewSearch(
        state.kakaoSearchResult,
        state.reviewSearchResult.copyWith(placeReviewList: response),
      );
    } catch (e) {
      logger.e("키워드 검색 에러", error:e);
    }
  }

  // placeReview 작성
  Future<bool> insertPlaceReview(Map<String, dynamic> data) async {
    return await _repository.fetchInsertPlaceReview(data);
  }
  // [추가] 로컬 상태의 좋아요 수 변경 (UI 즉시 반영용)
  void updateHeartCount(String prNo, int addCount) {
    // 1. 기존 리스트를 순회하며 수정할 아이템을 찾음
    List<PlaceReview> newList = state.reviewSearchResult.placeReviewList.map((item) {
      if (item.prNo == prNo) {
        // 2. 해당 아이템의 좋아요 수를 변경한 '새로운 객체' 생성
        // (PlaceReview 모델에 copyWith가 없다면 아래 3단계 참고)
        return item.copyWith(heart: (item.heart ?? 0) + addCount);
      }
      return item;
    }).toList();

    // 3. 변경된 리스트를 담은 새로운 상태로 업데이트
    state = state.copyWith(
      reviewSearchResult: state.reviewSearchResult.copyWith(
        placeReviewList: newList,
      ),
    );
  }

  /// 검색 ///
  // kakao search - 카카오 API 주소 검색
  Future<void> kakaoPlaceSearchApi(String keyword, int page) async {
    try {
      Map<String, dynamic> result =
      await _repository.fetchSearchKaKaoLocation(keyword, page: page);

      List<KakaoSearch> newList = (result['documents'] as List<dynamic>)
          .map((json) => KakaoSearch.fromJson(json))
          .toList();

      replaceKakaoSearchResultList(newList);
    } catch (e) {
      logger.e("카카오 주소 검색 에러", error:e);
    }
  }

  // 카카오 주소 검색 갱신
  void replaceKakaoSearchResultList(List<KakaoSearch> newList) {
    state = PlaceReviewSearch(
        KakaoSearchResult(newList),
        state.reviewSearchResult
    );
  }

  // 카카오 주소 기반 장소 이미지 크롤링
  Future<dynamic> crawlingPlaceImage(String placeUrl) async {
    return await _repository.fetchCrawlingPlaceImage(placeUrl);
  }

  // 장소 공유 채팅 조회
  Future<PlaceReview> searchPlaceForChat(
      String placeName, String placeAddress) async {
    return await _repository.fetchSearchPlaceForChat(placeName, placeAddress);
  }
}

final placeReviewSearchViewModelProvider =
NotifierProvider<PlaceReviewSearchViewModel, PlaceReviewSearch>(
      () => PlaceReviewSearchViewModel(PlaceReviewSearchRepository()),
);