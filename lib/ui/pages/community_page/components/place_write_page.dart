import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pingo_front/_core/utils/logger.dart';
import 'package:pingo_front/data/models/community_model/kakao_search.dart';
import 'package:pingo_front/data/models/community_model/place_review.dart';
import 'package:pingo_front/data/view_models/community_view_model/place_review_search_view_model.dart';
import 'package:path_provider/path_provider.dart';

class PlaceWritePage extends StatefulWidget {
  final String userNo;
  final PlaceReviewSearchViewModel kakaoSearchProvider;

  const PlaceWritePage(this.kakaoSearchProvider, this.userNo, {super.key});

  @override
  State<PlaceWritePage> createState() => _PlaceWritePageState();
}

class _PlaceWritePageState extends State<PlaceWritePage> {
  late KakaoSearch kakaoSearch;

  // 수정 가능하도록 각각의 Controller 추가
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  File? _placeImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 1. Provider에서 마지막으로 검색된 장소 정보를 가져옵니다.
    kakaoSearch = widget.kakaoSearchProvider.lastSearch;

    // 2. 검색된 결과가 있다면 초기값으로 설정합니다. (유저가 수정 가능)
    _nameController.text = kakaoSearch.placeName ?? "";
    _addressController.text = kakaoSearch.addressName ?? "";

    if (kakaoSearch.placeUrl != null && kakaoSearch.placeUrl!.isNotEmpty) {
      _fetchServerImage(kakaoSearch.placeUrl!);
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 기존 이미지 크롤링 로직 유지
  Future<void> _fetchServerImage(String url) async {
    try {
      var result = await widget.kakaoSearchProvider.crawlingPlaceImage(url);
      if (result != null && result is String && result.isNotEmpty) {
        Uint8List bytes = base64Decode(result);
        File file = await _saveImageToFile(bytes);
        if (!mounted) return;
        setState(() {
          _placeImage = file;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      logger.e('서버 이미지 가져오기 실패: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<File> _saveImageToFile(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/place_image_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _placeImage = File(pickedFile.path);
      });
    }
  }

  void checkValidation() async {
    // Controller에서 현재 입력된 값을 가져옵니다.
    String placeName = _nameController.text.trim();
    String addressName = _addressController.text.trim();
    String contents = _contentController.text.trim();

    if (placeName.isEmpty) {
      _showSnackBar('장소 이름을 입력해주세요.');
      return;
    }
    if (addressName.isEmpty) {
      _showSnackBar('주소를 입력해주세요.');
      return;
    }
    if (_placeImage == null) {
      _showSnackBar('장소 이미지를 등록해주세요.');
      return;
    }
    if (contents.isEmpty) {
      _showSnackBar('한 줄평을 작성해주세요.');
      return;
    }

    PlaceReview placeReview = PlaceReview(
      prNo: null,
      placeName: placeName, // 유저가 수정한 이름 사용
      addressName: addressName, // 유저가 수정한 주소 사용
      roadAddressName: kakaoSearch.roadAddressName ?? "",
      userNo: widget.userNo,
      contents: contents,
      category: kakaoSearch.category ?? "음식점",
      latitude: kakaoSearch.latitude ?? 0.0,
      longitude: kakaoSearch.longitude ?? 0.0,
      heart: 0,
    );

    Map<String, dynamic> data = {
      'placeReview': placeReview,
      'placeImage': _placeImage,
    };

    try {
      bool result = await widget.kakaoSearchProvider.insertPlaceReview(data);
      if (result && mounted) {
        FocusScope.of(context).unfocus();
        Navigator.pop(context);
      } else {
        _showSnackBar('서버 저장에 실패했습니다.');
      }
    } catch (e) {
      logger.e('등록 중 예외 발생: $e');
      _showSnackBar('네트워크 오류가 발생했습니다.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    double cntWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text("추천 장소 등록")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('장소 정보를 확인하고 추천글을 남겨주세요!',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildProfileBox(cntWidth),
              const SizedBox(height: 12),
              const Center(child: Text('이미지를 클릭하여 변경할 수 있습니다.', style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 32),

              // 1. 장소명 입력 필드
              const Text("장소 이름", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: "장소명을 입력하세요",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 20),

              // 2. 주소 입력 필드
              const Text("주소", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: "주소를 입력하세요",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 20),

              // 3. 한 줄평 입력 필드
              const Text("한 줄평", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '이 장소를 추천하는 이유를 적어주세요.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF906FB7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: checkValidation,
                  child: const Text('등록하기',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileBox(double cntWidth) {
    return GestureDetector(
      onTap: _pickProfileImage,
      child: Container(
        width: double.infinity,
        height: cntWidth * 0.5,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(color: Colors.black12, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : (_placeImage == null
            ? const Center(child: Icon(Icons.add_a_photo, size: 40, color: Colors.black26))
            : ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.file(_placeImage!, fit: BoxFit.cover),
        )),
      ),
    );
  }
}