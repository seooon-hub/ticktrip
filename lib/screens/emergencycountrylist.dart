import 'package:flutter/material.dart';
import 'package:ticktrip/screens/emergencycontactspage.dart';

class EmergencyCountryListPage extends StatefulWidget {
  @override
  _EmergencyCountryListPageState createState() => _EmergencyCountryListPageState();
}

class _EmergencyCountryListPageState extends State<EmergencyCountryListPage> {
  final Map<String, String> countryCodes = {
    "US": "미국",
    "JP": "일본",
    "DE": "독일",
    "FR": "프랑스",
    "CN": "중국",
    "IN": "인도",
    "GB": "영국",
    "IT": "이탈리아",
    "CA": "캐나다",
    "AU": "호주",
    "BR": "브라질",
    "RU": "러시아",
    "MX": "멕시코",
    "ES": "스페인",
    "ZA": "남아프리카공화국",
    "AR": "아르헨티나",
    "EG": "이집트",
    "NG": "나이지리아",
    "TR": "터키",
    "VN": "베트남",
    "TH": "태국",
    "SG": "싱가포르",
    "MY": "말레이시아",
    "ID": "인도네시아",
    "PH": "필리핀",
    "NZ": "뉴질랜드",
    "SA": "사우디아라비아",
    "AE": "아랍에미리트",
    "IL": "이스라엘",
    "SE": "스웨덴",
    "CH": "스위스",
    "NL": "네덜란드",
    "BE": "벨기에",
    "PL": "폴란드",
    "CZ": "체코",
    "HU": "헝가리",
    "GR": "그리스",
    "PT": "포르투갈",
  };

  final TextEditingController _searchController = TextEditingController();
  List<MapEntry<String, String>> _filteredCountries = [];

  @override
  void initState() {
    super.initState();
    _filteredCountries = countryCodes.entries.toList();
  }

  void _filterCountries(String query) {
    setState(() {
      _filteredCountries = countryCodes.entries
          .where((entry) => entry.value.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("비상 연락처"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 검색창
            TextField(
              controller: _searchController,
              onChanged: _filterCountries,
              decoration: InputDecoration(
                labelText: "나라 검색",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            // 국가 리스트
            Expanded(
              child: ListView.builder(
                itemCount: _filteredCountries.length,
                itemBuilder: (context, index) {
                  final country = _filteredCountries[index];
                  return ListTile(
                    title: Text(country.value),
                    onTap: () {
                      // 국가 선택 시, 비상 연락처 페이지로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmergencyContactsPage(countryCode: country.key),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
