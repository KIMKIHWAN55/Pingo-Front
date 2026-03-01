import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pingo_front/data/models/community_model/dating_guide.dart';
import 'package:pingo_front/data/models/community_model/dating_guide_search.dart';
import 'package:pingo_front/data/view_models/community_view_model/dating_guide_view_model.dart';
import 'package:pingo_front/data/view_models/sign_view_model/signin_view_model.dart';
import 'package:pingo_front/ui/pages/community_page/components/dating_guide_view_page.dart';
import 'package:pingo_front/ui/pages/community_page/components/dating_guide_write_page.dart';
import 'package:pingo_front/ui/widgets/custom_image.dart';

class DatingGuidePage extends ConsumerStatefulWidget {
  const DatingGuidePage({super.key});

  @override
  ConsumerState<DatingGuidePage> createState() => _DatingGuidePageState();
}

class _DatingGuidePageState extends ConsumerState<DatingGuidePage> {
  late String sessionUserNo;
  late DatingGuideViewModel datingGuideViewModel;

  @override
  void initState() {
    super.initState();
    // [수정] 세션 정보 null 방어
    final user = ref.read(sessionProvider).userNo;
    sessionUserNo = user ?? 'unknown';
    datingGuideViewModel = ref.read(datingGuideViewModelProvider.notifier);
  }

  void changeSearchSort(String newSort, int category, String cateName) async {
    await datingGuideViewModel.changeSearchSort(newSort, category, cateName);
    if (mounted) setState(() {});
  }

  void moveToWritePage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DatingGuideWritePage(sessionUserNo),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("게시글이 성공적으로 작성되었습니다."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void moveToViewPage(BuildContext context, DatingGuide datingGuide) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DatingGuideViewPage(datingGuide),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // ViewModel 상태 감시
    Map<String, DatingGuideSearch> dgsMap = ref.watch(datingGuideViewModelProvider);

    // [추가] 데이터가 아예 없을 때 로딩 인디케이터 표시
    if (dgsMap.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    double cntWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...dgsMap.entries.map(
                    (entry) {
                  return SizedBox(
                    height: 320, // 높이 소폭 조정
                    child: guideGroup(cntWidth, entry.value),
                  );
                },
              ),
              const SizedBox(height: 80), // 하단 여백
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF906FB7),
            onPressed: () => moveToWritePage(context),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget guideGroup(double cntWidth, DatingGuideSearch group) {
    // [핵심 수정] 리스트 null 체크 및 빈 리스트 방어
    final guideList = group.datingGuideList ?? [];

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  group.category ?? '카테고리',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                _buildSortToggle(group),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Text(group.cateDesc ?? '', style: Theme.of(context).textTheme.headlineSmall),
          ),
          Expanded(
            child: guideList.isEmpty
                ? const Center(child: Text("등록된 가이드가 없습니다."))
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: guideList.length,
              itemBuilder: (context, index) => guideBox(cntWidth, guideList[index]),
            ),
          ),
        ],
      ),
    );
  }

  // [추가] 정렬 토글 위젯 분리 (null 방어 포함)
  Widget _buildSortToggle(DatingGuideSearch group) {
    return Row(
      children: [
        _sortTextButton('인기순', 'popular', group),
        const SizedBox(width: 12),
        _sortTextButton('최신순', 'newest', group),
      ],
    );
  }

  Widget _sortTextButton(String label, String sortKey, DatingGuideSearch group) {
    bool isSelected = group.sort == sortKey;
    return GestureDetector(
      onTap: () => changeSearchSort(sortKey, group.cateNo ?? 0, group.category ?? ''),
      child: Container(
        decoration: BoxDecoration(
          border: BorderDirectional(
            bottom: BorderSide(width: 2, color: isSelected ? const Color(0xFF906FB7) : Colors.transparent),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF906FB7) : Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget guideBox(double cntWidth, DatingGuide datingGuide) {
    return GestureDetector(
      onTap: () => moveToViewPage(context, datingGuide),
      child: Container(
        width: cntWidth * 0.6,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 140,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CustomImage().token(datingGuide.thumb ?? ''),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    datingGuide.title ?? '제목 없음',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  _buildGuideFooter(datingGuide),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGuideFooter(DatingGuide datingGuide) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundImage: CustomImage().provider(datingGuide.userProfile ?? ''),
            ),
            const SizedBox(width: 6),
            Text(datingGuide.userName ?? '알 수 없음', style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
        Row(
          children: [
            const Icon(CupertinoIcons.heart_fill, size: 16, color: Colors.redAccent),
            const SizedBox(width: 4),
            Text('${datingGuide.heart ?? 0}', style: const TextStyle(fontSize: 12)),
          ],
        )
      ],
    );
  }
}