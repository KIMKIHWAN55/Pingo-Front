import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pingo_front/data/models/membership_model/membership.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentPage extends StatefulWidget {
  final Membership? selectedMembership;
  const PaymentPage(this.selectedMembership, {super.key});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final WebViewController _controller;
  // 실제 시연을 위해 유효한 리다이렉트 URL 사용 (테스트용)
  final String successUrl = "https://example.com/success";
  final String failUrl = "https://example.com/fail";

  @override
  void initState() {
    super.initState();

    // 1. 컨트롤러 기본 설정
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // 결제 성공 감지
            if (request.url.startsWith(successUrl)) {
              Navigator.pop(context, {"status": "success"});
              return NavigationDecision.prevent;
            }
            // 결제 실패 감지
            if (request.url.startsWith(failUrl)) {
              Navigator.pop(context, {"status": "fail"});
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    // 2. 토스 결제창을 실행할 HTML 로드
    _loadPaymentHtml();
  }

  void _loadPaymentHtml() {
    // 토스 테스트용 클라이언트 키 (주의: test_ck로 시작하는 키 사용)
    const String clientKey = "test_ck_DpexMgkW36va5xDNgvGN3GbR5ozO";

    final String orderId = "ORDER_${DateTime.now().millisecondsSinceEpoch}";
    final String orderName = widget.selectedMembership?.title ?? "Pingo 구독권";
    final int amount = widget.selectedMembership?.price ?? 0;

    // 결제창을 띄우는 최소한의 JS 코드
    final String paymentHtml = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8" />
          <script src="https://js.tosspayments.com/v1/payment"></script>
        </head>
        <body>
          <script>
            var tossPayments = TossPayments('$clientKey');
            tossPayments.requestPayment('카드', {
              amount: $amount,
              orderId: '$orderId',
              orderName: '$orderName',
              successUrl: '$successUrl',
              failUrl: '$failUrl',
            }).catch(function (error) {
              location.href = '$failUrl?message=' + error.message;
            });
          </script>
        </body>
      </html>
    ''';

    _controller.loadHtmlString(paymentHtml);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pingo 안전 결제"),
        backgroundColor: const Color(0xFF906FB7),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}