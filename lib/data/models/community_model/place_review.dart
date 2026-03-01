class PlaceReview {
  final String? prNo;
  final String? placeName;
  final String? thumb;
  final String? addressName;
  final String? roadAddressName;
  final String? userNo;
  final String? contents;
  final String? category;
  final double? latitude;
  final double? longitude;
  final int? heart;
  final String? userNick;
  final String? imageUrl;

  // [수정 1] 생성자를 Named Parameter ({})로 변경하여 가독성 높임
  PlaceReview({
    this.prNo,
    this.placeName,
    this.thumb,
    this.addressName,
    this.roadAddressName,
    this.userNo,
    this.contents,
    this.category,
    this.latitude,
    this.longitude,
    this.heart,
    this.userNick,
    this.imageUrl,
  });

  // [수정 2] Riverpod 상태 관리를 위한 핵심 메서드 (값 변경 시 사용)
  PlaceReview copyWith({
    String? prNo,
    String? placeName,
    String? thumb,
    String? addressName,
    String? roadAddressName,
    String? userNo,
    String? contents,
    String? category,
    double? latitude,
    double? longitude,
    int? heart,
    String? userNick,
    String? imageUrl,
  }) {
    return PlaceReview(
      prNo: prNo ?? this.prNo,
      placeName: placeName ?? this.placeName,
      thumb: thumb ?? this.thumb,
      addressName: addressName ?? this.addressName,
      roadAddressName: roadAddressName ?? this.roadAddressName,
      userNo: userNo ?? this.userNo,
      contents: contents ?? this.contents,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heart: heart ?? this.heart,
      userNick: userNick ?? this.userNick,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // [수정 3] JSON 파싱 시 숫자 타입 안전하게 변환 (num -> double)
  factory PlaceReview.fromJson(Map<String, dynamic> json) {
    return PlaceReview(
      prNo: json['prNo'],
      placeName: json['placeName'],
      thumb: json['thumb'],
      addressName: json['addressName'],
      roadAddressName: json['roadAddressName'],
      userNo: json['userNo'],
      contents: json['contents'],
      category: json['category'],
      // API에서 좌표가 정수로 올 수도 있으므로 안전하게 캐스팅
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      heart: json['heart'],
      userNick: json['userNick'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "prNo": prNo,
      "placeName": placeName,
      "thumb": thumb,
      "addressName": addressName,
      "roadAddressName": roadAddressName,
      "userNo": userNo,
      "contents": contents,
      "category": category,
      "latitude": latitude,
      "longitude": longitude,
      "heart": heart,
      "userNick": userNick,
      "imageUrl": imageUrl,
    };
  }

  @override
  String toString() {
    return 'PlaceReview{prNo: $prNo, placeName: $placeName, heart: $heart, userNick: $userNick}';
  }
}