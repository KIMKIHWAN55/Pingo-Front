import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pingo_front/data/models/community_model/place_review.dart';
import 'package:pingo_front/data/view_models/community_view_model/place_review_search_view_model.dart';
import 'package:pingo_front/data/view_models/sign_view_model/signin_view_model.dart';
import 'package:pingo_front/ui/widgets/custom_image.dart';

class PlaceBox extends ConsumerStatefulWidget {
  final PlaceReview placeReview;
  final Function changePlaceShared;

  const PlaceBox(this.placeReview, this.changePlaceShared, {super.key});
  @override
  ConsumerState<PlaceBox> createState() => _PlaceBoxState();
}

class _PlaceBoxState extends ConsumerState<PlaceBox> {
  bool isExpanded = false; // 크기 조절용
  bool showText = false; // 텍스트 표시 여부

  void _toggleExpanded() {
    if (isExpanded) {
      // 축소할 때는 동시에 처리
      setState(() {
        showText = false;
        isExpanded = false;
      });
    } else {
      // 확장할 때는 크기 변경 후 텍스트 표시
      setState(() {
        isExpanded = true;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) { // mounted 체크 추가 (비동기 에러 방지)
          setState(() {
            showText = true;
          });
        }
      });
    }
  }

  void _clickPlaceReviewHeart() async {
    String? userNo = ref.read(sessionProvider).userNo;
    String? prNo = widget.placeReview.prNo;

    if (userNo == null || prNo == null) return;

    // 1. 서버에 좋아요 요청
    String result = await ref
        .read(placeReviewSearchViewModelProvider.notifier)
        .clickThumbUp(userNo, prNo);

    // 2. 결과에 따라 로컬 상태 업데이트 (ViewModel 함수 호출)
    if (result == 'increase') {
      // [수정된 부분] 모델 직접 수정(x) -> 뷰모델에 요청(o)
      ref.read(placeReviewSearchViewModelProvider.notifier).updateHeartCount(prNo, 1);
    } else {
      // [수정된 부분]
      ref.read(placeReviewSearchViewModelProvider.notifier).updateHeartCount(prNo, -1);
    }

    // setState는 Riverpod이 상태를 바꾸면 알아서 화면이 갱신되므로 사실상 불필요하지만,
    // 애니메이션 등을 위해 남겨둬도 무방합니다.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double totalWidth = MediaQuery.of(context).size.width;

    // [안전 장치] 이미지가 없을 경우 대비
    final imageProvider = (widget.placeReview.thumb != null && widget.placeReview.thumb!.isNotEmpty)
        ? CustomImage().provider(widget.placeReview.thumb!)
        : const AssetImage('assets/images/placeholder.png'); // 기본 이미지(없으면 에러날 수 있음) 혹은 Colors.grey 처리

    return GestureDetector(
      onTap: _toggleExpanded,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 8.0),
        width: totalWidth * 0.9,
        height: isExpanded
            ? totalWidth * 0.9 / 16 * 11
            : totalWidth * 0.9 / 16 * 7,
        decoration: BoxDecoration(
          // 이미지가 있으면 이미지 표시, 없으면 회색 배경
          image: widget.placeReview.thumb != null
              ? DecorationImage(
            image: imageProvider as ImageProvider,
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {
              // 이미지 로드 실패 시 처리
            },
          )
              : null,
          color: widget.placeReview.thumb == null ? Colors.grey[300] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              offset: const Offset(0, 2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.transparent),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 아이콘
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _clickPlaceReviewHeart,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.heart_fill,
                            size: 20, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.placeReview.heart}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    widget.changePlaceShared(true, widget.placeReview);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.ios_share_outlined,
                        size: 20, color: Colors.white),
                  ),
                )
              ],
            ),
            // 하단 정보
            Container(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 24),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.0),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.placeReview.placeName ?? '장소명 없음', // Null 처리
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  Text(
                    widget.placeReview.addressName ?? '주소 없음', // Null 처리
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    opacity: showText ? 1.0 : 0.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      transform: Matrix4.translationValues(
                          0, showText ? 0 : 10, 0),
                      child: Visibility(
                        visible: showText,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              "🏷 ${widget.placeReview.userNick ?? '익명'}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                            Text(
                              "💬 ${widget.placeReview.contents ?? ''}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}