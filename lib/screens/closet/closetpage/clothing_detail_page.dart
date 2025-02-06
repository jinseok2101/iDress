import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ColorOption {
  final String name;
  final Color color;

  ColorOption(this.name, this.color);
}

class ClothingDetailPage extends StatefulWidget {
  final Map<dynamic, dynamic> clothing;
  final String clothingId;
  final String category;
  final String childId;

  const ClothingDetailPage({
    Key? key,
    required this.clothing,
    required this.clothingId,
    required this.category,
    required this.childId,
  }) : super(key: key);

  @override
  _ClothingDetailPageState createState() => _ClothingDetailPageState();
}

class _ClothingDetailPageState extends State<ClothingDetailPage> {
  bool isFavorite = false;
  bool isEditing = false;
  late TextEditingController nameController;
  late TextEditingController sizeController;
  late TextEditingController memoController;
  Set<String> selectedSeasons = {};
  Color selectedColor = Colors.grey;
  bool _isLoading = false;
  DatabaseReference? _clothingRef;

  final List<ColorOption> colorOptions = [
    ColorOption('흰색', Colors.white),
    ColorOption('검정', Colors.black),
    ColorOption('회색', Colors.grey),
    ColorOption('빨강', Colors.red),
    ColorOption('분홍', Colors.pink),
    ColorOption('주황', Colors.orange),
    ColorOption('노랑', Colors.yellow),
    ColorOption('초록', Colors.green),
    ColorOption('파랑', Colors.blue),
    ColorOption('남색', Colors.indigo),
    ColorOption('보라', Colors.purple),
    ColorOption('갈색', Colors.brown),
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.clothing['name'] ?? '');
    sizeController = TextEditingController(text: widget.clothing['size'] ?? '');
    memoController = TextEditingController(text: widget.clothing['memo'] ?? '');
    isFavorite = widget.clothing['isFavorite'] ?? false;  // 즐겨찾기 상태 초기화

    // season 데이터 처리
    if (widget.clothing['season'] is List) {
      selectedSeasons = Set<String>.from(widget.clothing['season']);
    } else {
      selectedSeasons = {'사계절'};
    }

    String savedColorName = widget.clothing['color'] ?? '회색';
    selectedColor = colorOptions
        .firstWhere((option) => option.name == savedColorName,
        orElse: () => ColorOption('회색', Colors.grey))
        .color;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _clothingRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('children')
          .child(widget.childId)
          .child('clothing')
          .child(widget.category)
          .child(widget.clothingId);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    sizeController.dispose();
    memoController.dispose();
    super.dispose();
  }

  Future<void> _updateClothing() async {
    if (_clothingRef == null) return;

    setState(() => _isLoading = true);

    try {
      final colorName = colorOptions
          .firstWhere((option) => option.color == selectedColor)
          .name;

      final updates = {
        'name': nameController.text,
        'size': sizeController.text,
        'season': selectedSeasons.toList(),
        'color': colorName,
        'memo': memoController.text,
        'isFavorite': isFavorite,
        'lastModified': ServerValue.timestamp,
      };

      await _clothingRef!.update(updates);

      if (mounted) {
        setState(() {
          isEditing = false;
          _isLoading = false;
        });

        widget.clothing['name'] = nameController.text;
        widget.clothing['size'] = sizeController.text;
        widget.clothing['season'] = selectedSeasons.toList();
        widget.clothing['color'] = colorName;
        widget.clothing['memo'] = memoController.text;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('수정이 완료되었습니다'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error updating clothing: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수정 중 오류가 발생했습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '옷 상세정보',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // 즐겨찾기 버튼 추가
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey,
            ),
            onPressed: () async {
              if (_clothingRef != null) {
                final newValue = !isFavorite;
                await _clothingRef!.update({'isFavorite': newValue});
                setState(() {
                  isFavorite = newValue;
                });

                // 스낵바로 상태 변경 알림
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(newValue ? '즐겨찾기에 추가되었습니다' : '즐겨찾기가 해제되었습니다'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          if (!isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.black),
              onPressed: () => setState(() => isEditing = true),
            )
          else
            TextButton(
              onPressed: _isLoading ? null : _updateClothing,
              child: _isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(
                '저장',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.grey[100],
              ),
              child: Image.network(
                widget.clothing['imageUrl'],
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEditing) ...[
                    _buildEditTextField('이름', nameController),
                    _buildEditTextField('사이즈', sizeController),
                    _buildSeasonSelector(),
                    _buildColorSelector(),
                    _buildEditTextField('메모', memoController, maxLines: 3),
                  ] else ...[
                    Text(
                      widget.clothing['name'] ?? '이름 없음',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildInfoItem('카테고리', widget.category),
                    _buildInfoItem('사이즈', widget.clothing['size'] ?? '미지정'),
                    _buildInfoItem('계절', widget.clothing['season'] ?? '미지정'),
                    _buildInfoItem('색상', widget.clothing['color'] ?? '미지정'),
                    if (widget.clothing['memo'] != null &&
                        widget.clothing['memo'].toString().isNotEmpty)
                      _buildInfoItem('메모', widget.clothing['memo']),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: label == '사이즈' ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '계절',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['봄', '여름', '가을', '겨울', '사계절'].map((season) {
              return ChoiceChip(
                label: Text(season),
                selected: selectedSeasons.contains(season),
                onSelected: (bool selected) {
                  setState(() {
                    if (season == '사계절') {
                      if (selected) {
                        selectedSeasons = {'봄', '여름', '가을', '겨울', '사계절'};
                      } else {
                        selectedSeasons.clear();
                      }
                    } else {
                      if (selected) {
                        selectedSeasons.add(season);
                        if (selectedSeasons.containsAll(['봄', '여름', '가을', '겨울'])) {
                          selectedSeasons.add('사계절');
                        }
                      } else {
                        selectedSeasons.remove(season);
                        selectedSeasons.remove('사계절');
                      }
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '색상',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colorOptions.map((option) => GestureDetector(
              onTap: () {
                setState(() {
                  selectedColor = option.color;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: option.color,
                  border: Border.all(
                    color: selectedColor == option.color
                        ? Colors.blue
                        : Colors.grey,
                    width: selectedColor == option.color ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: selectedColor == option.color
                    ? Icon(
                  Icons.check,
                  color: option.color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                )
                    : null,
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, dynamic value) {
    String displayValue;
    if (label == '계절' && value is List) {
      displayValue = (value as List).join(', ');
    } else {
      displayValue = value?.toString() ?? '미지정';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}