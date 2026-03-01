import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pingo_front/data/models/community_model/place_review.dart';
import 'package:pingo_front/data/models/community_model/place_review_search.dart';
import 'package:pingo_front/data/models/community_model/review_search_result.dart';
import 'package:pingo_front/data/view_models/community_view_model/place_review_search_view_model.dart';
import 'package:pingo_front/data/view_models/sign_view_model/signin_view_model.dart';
import 'package:pingo_front/ui/pages/community_page/components/place_box.dart';
import 'package:pingo_front/ui/pages/community_page/components/place_write_page.dart';
import 'package:pingo_front/ui/widgets/kakao_map_screen.dart';

const Map<String, IconData> kakaoCategory = {
  "맛집": Icons.restaurant,
  "카페": Icons.local_cafe,
  "문화": Icons.movie,
  "명소": Icons.camera_alt,
};

class PlaceList extends ConsumerStatefulWidget {
  final PlaceReviewSearch searchReviewState;
  final PlaceReviewSearchViewModel searchReviewProvider;
  final Function changePlaceShared;
  final Function _onSearchCleared;

  const PlaceList(
      this.searchReviewState,
      this.searchReviewProvider,
      this.changePlaceShared,
      this._onSearchCleared, {
        super.key,
      });

  @override
  ConsumerState<PlaceList> createState() => _PlaceListState();
}

class _PlaceListState extends ConsumerState<PlaceList> {
  @override
  Widget build(BuildContext context) {
    ReviewSearchResult searchResult = widget.searchReviewState.reviewSearchResult;
    List<PlaceReview> searchList = searchResult.placeReviewList;

    // 세션 정보 안전하게 가져오기
    final session = ref.watch(sessionProvider);
    final String userNo = session.userNo ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      // [개선 1] 플로팅 버튼의 데이터 전달 로직 강화
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 현재 검색된 장소 정보를 명확히 가져옴
          final lastSearch = widget.searchReviewProvider.lastSearch;

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaceWritePage(
                widget.searchReviewProvider,
                userNo,
              ),
            ),
          );
          // 작성 후 돌아왔을 때 검색 상태 초기화 또는 갱신
          widget._onSearchCleared();
        },
        backgroundColor: const Color(0xFF906FB7),
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text("리뷰 작성",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // 카테고리 선택 영역 (검색 결과 유무와 상관없이 항상 노출)
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: kakaoCategory.length,
              itemBuilder: (ctx, index) {
                var key = kakaoCategory.keys.toList()[index];
                var value = kakaoCategory[key];
                return _placeCateBox(context, key, value, searchResult.cateSort);
              },
            ),
          ),

          // 정렬 버튼 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                _placeSortBtn(context, '인기순', 'popular', searchResult.searchSort),
                _placeSortBtn(context, '최신순', 'newest', searchResult.searchSort),
                _placeSortBtn(context, '거리순', 'location', searchResult.searchSort),
              ],
            ),
          ),

          // 메인 리스트 영역
          Expanded(
            child: searchList.isEmpty
                ? _buildEmptyView(context, userNo)
                : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: searchList.length,
              itemBuilder: (context, index) {
                final item = searchList[index];
                // prNo가 null일 경우를 대비한 방어 코드 및 고유 키 부여
                if (item.prNo == null) return const SizedBox.shrink();

                return PlaceBox(
                  item,
                  widget.changePlaceShared,
                  key: ValueKey("place_${item.prNo}_$index"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 리뷰 데이터가 없을 때 표시할 화면 (지도 및 안내문구)
  Widget _buildEmptyView(BuildContext context, String userNo) {
    final lastSearch = widget.searchReviewProvider.lastSearch;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // 지도가 표시될 영역 (데이터가 있을 때만)
          if (lastSearch.placeName != null)
            SizedBox(
              height: 220,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: KakaoMapScreen(lastSearch),
                ),
              ),
            ),
          const SizedBox(height: 32),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Text(
                    '${lastSearch.placeName ?? '선택한 장소'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF906FB7)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '아직 등록된 리뷰가 없습니다.\n첫 번째 리뷰의 주인공이 되어보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // 카테고리 아이템 위젯
  Widget _placeCateBox(BuildContext context, String text, IconData? icon, String? cateIndex) {
    bool isSelected = cateIndex == text;
    return GestureDetector(
      onTap: () async {
        await widget.searchReviewProvider.changeCateSort(text);
        if (mounted) setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? const Color(0xFF906FB7) : const Color(0xFF4A4A4A),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF906FB7) : const Color(0xFF4A4A4A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 정렬 버튼 위젯
  Widget _placeSortBtn(BuildContext context, String title, String index, String? sortIndex) {
    bool isSelected = sortIndex == index;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(0, 32),
          backgroundColor: isSelected ? const Color(0xFF906FB7) : Colors.transparent,
          side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () async {
          await widget.searchReviewProvider.changeSearchSort(index);
          if (mounted) setState(() {});
        },
        child: Text(
          title,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontSize: 12),
        ),
      ),
    );
  }
}