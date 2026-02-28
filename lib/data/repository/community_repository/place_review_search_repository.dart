import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pingo_front/_core/utils/logger.dart';
import 'package:pingo_front/data/models/community_model/place_review.dart';
import 'package:pingo_front/data/network/custom_dio.dart';
import 'package:mime/mime.dart';

class PlaceReviewSearchRepository {
  // _dio는 더 이상 직접 쓰지 않으므로 삭제해도 되지만, 다른 곳에 쓸 수 있으니 둠
  final Dio _dio = Dio();
  final CustomDio _customDio = CustomDio.instance;

  // 🗑️ 삭제: 프론트에서 직접 카카오를 호출하면 안 되므로 아래 두 줄은 지웁니다.
  // final String _baseUrl = "https://dapi.kakao.com/v2/local/search/keyword.json";
  // final String _apiKey = "KakaoAK ...";

  // placeReview 작성
  Future<bool> fetchInsertPlaceReview(Map<String, dynamic> data) async {
    String? mimeType = lookupMimeType(data['placeImage'].path) ?? 'image/jpeg';

    FormData formData = FormData.fromMap({
      "placeReview": MultipartFile.fromString(
        jsonEncode(data['placeReview'].toJson()),
        contentType: DioMediaType("application", "json"),
      ),
      "placeImage": await MultipartFile.fromFile(
        data['placeImage'].path,
        filename: "placeImage.jpg",
        contentType: DioMediaType.parse(mimeType),
      )
    });

    final response = await _customDio.post(
      '/community/place',
      data: formData,
      contentType: 'multipart/form-data',
    );

    return response;
  }

  // 게시글 좋아요
  Future<String> fetchClickThumbUp(String userNo, String prNo) async {
    final response = await _customDio.post(
      '/community/place/heart',
      data: {
        'userNo': userNo,
        'prNo': prNo,
      },
    );
    return response;
  }

  // 서버에서 장소 리뷰 조회
  Future<List<PlaceReview>> fetchSearchPlaceReview(
      {required String? cateSort,
        required String? searchSort,
        String? keyword}) async {
    List<dynamic> response = await _customDio.get('/community/place', query: {
      'cateSort': cateSort,
      'searchSort': searchSort,
      'keyword': keyword
    });

    return response.map((json) => PlaceReview.fromJson(json)).toList();
  }

  // 서버에서 장소 리뷰 조회 with location
  Future<List<PlaceReview>> fetchSearchPlaceReviewWithLocation(
      {required String? cateSort,
        required double latitude,
        required double longitude}) async {
    List<dynamic> response = await _customDio.get('/community/place/location',
        query: {
          'cateSort': cateSort,
          'latitude': latitude,
          'longitude': longitude
        });

    return response.map((json) => PlaceReview.fromJson(json)).toList();
  }

  // ⭐️ [수정됨] 카카오 API 검색 (백엔드 중계)
  Future<Map<String, dynamic>> fetchSearchKaKaoLocation(String keyword,
      {int page = 1, int size = 10}) async {
    try {
      // 1. CustomDio를 사용하여 내 백엔드 서버로 요청합니다.
      // 2. Authorization 헤더는 백엔드에서 처리하므로 여기서는 뺍니다.
      // 3. 파라미터 키를 'query'가 아니라 백엔드 Controller가 받는 'keyword'로 보냅니다.
      dynamic response = await _customDio.get(
        '/pingo/map/search',
        query: {
          "keyword": keyword, // ⚠️ 주의: 백엔드(@RequestParam String keyword)와 이름 일치 필수
          "page": page,
          "size": size
        },
      );

      logger.i("백엔드 장소 검색 응답: $response");

      // CustomDio가 이미 JSON을 파싱해서 dynamic(Map) 형태로 줄 것으로 예상됩니다.
      // 만약 String으로 온다면 jsonDecode(response)가 필요할 수 있습니다.
      if (response is String) {
        return jsonDecode(response);
      } else {
        return response as Map<String, dynamic>;
      }

    } catch (e) {
      throw Exception("장소 검색 실패: ${e.toString()}");
    }
  }

  // 카카오 주소 기반 장소 이미지 크롤링
  Future<dynamic> fetchCrawlingPlaceImage(String placeUrl) async {
    dynamic response = await _customDio
        .post('/community/place/crawling', data: {'placeUrl': placeUrl});

    print(response.runtimeType);

    return response;
  }

  // 장소 공유 채팅 조회
  Future<PlaceReview> fetchSearchPlaceForChat(
      String placeName, String placeAddress) async {
    dynamic response = await _customDio.get(
      '/community/chat',
      query: {'placeName': placeName, 'placeAddress': placeAddress},
    );

    return PlaceReview.fromJson(response);
  }
}