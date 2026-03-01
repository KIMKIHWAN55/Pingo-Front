import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pingo_front/_core/utils/logger.dart';
import 'package:pingo_front/data/models/global_model/session_user.dart';
import 'package:pingo_front/data/models/membership_model/membership.dart';
import 'package:pingo_front/data/models/membership_model/user_membership.dart';
import 'package:pingo_front/data/repository/membership_repository/membership_repository.dart';
import 'package:pingo_front/data/view_models/sign_view_model/signin_view_model.dart';
import 'package:pingo_front/ui/pages/membership_Page/payment_page.dart';

class MembershipPage extends ConsumerStatefulWidget {
  const MembershipPage({super.key});

  @override
  ConsumerState<MembershipPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<MembershipPage> {
  final MembershipRepository _repository = MembershipRepository();
  Future<List<Membership>>? _membershipFuture;

  // [해결 1] late 제거: 초기화 지연으로 인한 null 참조 에러 원천 차단
  UserMembership? userMembership;

  Membership? selectedMembership;
  late SessionUser sessionUser;

  @override
  void initState() {
    super.initState();
    sessionUser = ref.read(sessionProvider);
    _loadMembershipData();
  }

  Future<void> _loadMembershipData() async {
    try {
      if (sessionUser.userNo == null) return;

      var result = await _repository.fetchSelectMemberShip(sessionUser.userNo!);

      if (mounted) {
        setState(() {
          userMembership = result.item1;
          _membershipFuture = Future.value(result.item2);
        });
      }
    } catch (e) {
      logger.e("멤버십 로딩 실패: $e");
    }
  }

  void _clickCoupon(Membership membership) {
    setState(() {
      selectedMembership = membership;
    });
  }

  void _clickPayment() async {
    if (selectedMembership == null) {
      _showSnackBar("결제하실 구독권을 선택해주세요.");
      return;
    }

    if (userMembership != null) {
      _showSnackBar("이미 구독중인 상품이 존재합니다.");
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(selectedMembership),
      ),
    );

    if (result != null && mounted) {
      if (result["status"] == "success") {
        Navigator.pop(context, {"status": "success", "membership": selectedMembership});
      } else {
        _showSnackBar("결제에 실패했습니다.");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF906FB7),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pingo 구독권 구매', style: TextStyle(fontSize: 16)),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Membership>>(
          future: _membershipFuture,
          builder: (context, snapshot) {
            // [해결 2] 로딩 및 에러 상태를 명확히 분기하여 불완전한 UI 렌더링 방지
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("멤버십 정보를 불러올 수 없습니다."));
            }

            final memberships = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Pingo 유료 구독으로 \n더 많은 기능을 경험해보세요!',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // 쿠폰 리스트
                  ...memberships.map((m) => _couponBox(m, Colors.grey.shade300)),
                  const SizedBox(height: 16),
                  _explainRow('무제한 SUPER PING'),
                  const SizedBox(height: 8),
                  _explainRow('나를 PING한 사람 프로필 보기'),
                  const SizedBox(height: 8),
                  _explainRow('상대와의 최대거리 200KM'),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: _paymentBtn(),
      ),
    );
  }

  Widget _explainRow(String explain) {
    return Row(
      children: [
        const Icon(Icons.check, color: Color(0xFF906FB7)),
        const SizedBox(width: 8),
        Text(explain, style: Theme.of(context).textTheme.headlineMedium)
      ],
    );
  }

  Widget _paymentBtn() {
    // [해결 3] null 방어 코드를 사용하여 isNegative 계산 에러 방지
    final price = selectedMembership?.price ?? 0;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF906FB7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
        ),
        onPressed: _clickPayment,
        child: Text(
          '${NumberFormat('#,###').format(price)} 원  결제하기',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _couponBox(Membership membership, Color backColor) {
    final bool isSelected = selectedMembership?.msNo == membership.msNo;

    return InkWell(
      onTap: () => _clickCoupon(membership),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 140,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 45),
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF906FB7) : backColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  membership.title ?? '',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black54),
                ),
                Text(
                  '${NumberFormat('#,###').format(membership.price ?? 0)} 원',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black54),
                ),
              ],
            ),
          ),
          // 디자인 요소 (기존 로직 유지)
          Positioned(
            top: 35, left: -20,
            child: Container(width: 70, height: 70, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ),
          if (isSelected)
            const Positioned(right: 30, top: 10, child: Icon(Icons.check, color: Colors.white, size: 30)),
        ],
      ),
    );
  }
}