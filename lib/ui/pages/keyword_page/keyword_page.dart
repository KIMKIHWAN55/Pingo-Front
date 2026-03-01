import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pingo_front/data/models/main_model/Profile.dart';
import 'package:pingo_front/data/view_models/keyword_view_model/keyword_view_model.dart';
import 'package:pingo_front/data/view_models/sign_view_model/signin_view_model.dart';
import 'package:pingo_front/ui/widgets/appbar/keyword_appbar.dart';
import '../../../data/models/keyword_model/keyword.dart';
import '../../../data/models/keyword_model/keyword_group.dart';

class KeywordPage extends ConsumerStatefulWidget {
  final Function changePageForKeyword;
  const KeywordPage(this.changePageForKeyword, {super.key});

  @override
  ConsumerState<KeywordPage> createState() => _KeywordPageState();
}

class _KeywordPageState extends ConsumerState<KeywordPage> {
  late final KeywordViewModel kGNotifier;
  late final String sessionUserNo;

  @override
  void initState() {
    super.initState();
    kGNotifier = ref.read(KeywordViewModelProvider.notifier);
    sessionUserNo = ref
        .read(sessionProvider)
        .userNo!;
    kGNotifier.fetchKeywords();
  }

  // 키워드로 조회 - 키워드 카드 클릭
  void _clickKeywordCard(String kwId) async {
    List<Profile> users =
    await kGNotifier.fetchSelectedKeyword(sessionUserNo, kwId);
    widget.changePageForKeyword(0, users);
  }

  @override
  Widget build(BuildContext context) {
    final groupList = ref.watch(KeywordViewModelProvider);

    return Scaffold(
      body: ListView(
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.key_outlined),
                const SizedBox(width: 12),
                Text(
                  '키워드를 통해 매칭이 이루어집니다. \n 내가 만나고 싶은 사람의 키워드를 선택해 보세요.',
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineSmall,
                ),
              ],
            ),
          ),
          ...groupList.entries.map((entry) {
            final key = entry.key;
            final keywordGroup = entry.value;
            return _keywordBox(context, keywordGroup);
          }).toList()
        ],
      ),
    );
  }

  // 키워드 그룹 List UI
  Widget _keywordBox(BuildContext buildContext, KeywordGroup keywordGroup) {
    // 💡 수정: childKeyword가 null이면 빈 리스트를 반환하여 에러 방지
    List<Keyword> keywords = keywordGroup.childKeyword ?? [];

    // 키워드가 없으면 빈 화면(SizedBox) 반환해서 자리만 안 차지하게 처리
    if (keywords.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(keywordGroup.kwName ?? '알 수 없는 그룹', // 💡 안전장치
              style: Theme.of(buildContext).textTheme.headlineLarge),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            cacheExtent: 2500,
            scrollDirection: Axis.horizontal,
            itemCount: keywords.length,
            itemBuilder: (context, index) {
              return _keywordCard(buildContext, keywords[index]);
            },
          ),
        ),
      ],
    );
  }

  // 개별 키워드 카드 UI
  Widget _keywordCard(BuildContext buildContext, Keyword keyword) {
    return GestureDetector(
      onTap: () {
        // 💡 kwId도 null일 수 있으니 안전하게 호출
        if (keyword.kwId != null) {
          _clickKeywordCard(keyword.kwId!);
        }
      },
      child: Container(
        margin: EdgeInsets.only(left: 16.0, bottom: 8.0),
        width: 340,
        decoration: BoxDecoration(
          borderRadius: BorderRadiusDirectional.circular(20),
          // 💡 주의: 이미지 파일명도 null이면 에러가 날 수 있으니 분기 처리가 필요할 수 있습니다.
          // 일단 기존 코드를 유지하되, 나중에 예외 처리가 필요할 수 있습니다.
          image: DecorationImage(
              image:
              AssetImage('assets/images/keyword_page/${keyword.kwId}.jpg'),
              fit: BoxFit.cover),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              offset: Offset(0, 2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadiusDirectional.circular(20),
            color: Color.fromRGBO(125, 125, 125, 0.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 💡 수정: kwName이 null일 때 대비
              Text('#${keyword.kwName ?? '이름 없음'}',
                  style: Theme
                      .of(buildContext)
                      .textTheme
                      .displaySmall!
                      .copyWith(color: Colors.white)),
              // 💡 수정: 대망의 135번째 줄! DB에 없는 kwMessage가 null일 때 띄울 기본 텍스트 지정
              Text(
                keyword.kwMessage ?? '키워드를 선택해보세요!',
                style: Theme
                    .of(buildContext)
                    .textTheme
                    .headlineMedium!
                    .copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}