class Membership {
  String? msNo;
  String? title;
  int? period;
  String? contents;
  int? price;

  Membership(this.msNo, this.title, this.period, this.contents, this.price);

  @override
  String toString() {
    return 'Membership{msNo: $msNo, title: $title, period: $period, contents: $contents, price: $price}';
  }

  Membership.fromJson(Map<String, dynamic> json)
      : msNo = json['msNo'],
        title = json['msName'],       // msName을 title에 담기
        period = json['msDuration'],  // msDuration을 period에 담기
        contents = json['description'], // description을 contents에 담기
        price = json['msPrice'];      // msPrice를 price에 담기
}
