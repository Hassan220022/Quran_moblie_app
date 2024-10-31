// lib/screens/surah_reader.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/provider/preference_settings_provider.dart';
import '../utils/provider/bookmarks_provider.dart';
import '../models/bookmark.dart';

class Ayah {
  final int numberInSurah;
  final String text;

  Ayah({required this.numberInSurah, required this.text});

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      numberInSurah: json['numberInSurah'],
      text: json['text'],
    );
  }
}

class SurahReaderScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final int? highlightAyah; // Optional parameter for highlighting

  const SurahReaderScreen({
    Key? key,
    required this.surahNumber,
    required this.surahName,
    this.highlightAyah,
  }) : super(key: key);

  @override
  _SurahReaderScreenState createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  List<Ayah> _ayahs = [];
  bool _isLoading = true;
  bool _isError = false;

  static const String basmallahImagePath = 'assets/basmallah.png';

  @override
  void initState() {
    super.initState();
    fetchAyahs();
  }

  Future<void> fetchAyahs() async {
    final String apiUrl =
        'http://api.alquran.cloud/v1/surah/${widget.surahNumber}/quran-uthmani';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<Ayah> fetchedAyahs = [];

        if (data['status'] == 'OK') {
          final List<dynamic> ayahs = data['data']['ayahs'];
          for (var ayah in ayahs) {
            final ayahObj = Ayah.fromJson(ayah);
            String normalizedAyahText = normalizeText(ayahObj.text);
            if (!normalizedAyahText.contains('بِسْمِ ٱللَّهِ')) {
              fetchedAyahs.add(ayahObj);
            }
          }
        }

        setState(() {
          _ayahs = fetchedAyahs;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  // Utility function to normalize text
  String normalizeText(String input) {
    final diacritics = RegExp(r'[\u064B-\u0652]');
    return input
        .replaceAll(diacritics, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _showBookmarkDialog(Ayah ayah) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add to Bookmarks'),
          content:
              const Text('Do you want to add this Ayah to your bookmarks?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final bookmark = Bookmark(
                  surahNumber: widget.surahNumber,
                  surahName: widget.surahName,
                  ayahNumber: ayah.numberInSurah,
                  text: ayah.text,
                );
                Provider.of<BookmarksProvider>(context, listen: false)
                    .addBookmark(bookmark);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ayah added to bookmarks'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkTheme =
        Provider.of<PreferenceSettingsProvider>(context).isDarkTheme;
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    EdgeInsets safePadding = MediaQuery.of(context).padding;
    double horizontalPadding = 16.0;
    double additionalLeftPadding = isLandscape ? safePadding.left : 0.0;
    double additionalRightPadding = isLandscape ? safePadding.right : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.surahName}',
          style: TextStyle(
            color: isDarkTheme ? Colors.white : const Color(0xff682DBD),
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(
          color: isDarkTheme ? Colors.white : const Color(0xff682DBD),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkTheme ? Icons.light_mode : Icons.dark_mode,
              color: isDarkTheme ? Colors.white : const Color(0xff682DBD),
            ),
            onPressed: () {
              Provider.of<PreferenceSettingsProvider>(context, listen: false)
                  .enableDarkTheme(!isDarkTheme);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isError
              ? Center(
                  child: Text(
                    'Failed to load ayahs. Please try again later.',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black,
                      fontSize: 16.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: _ayahs.length + 1, // +1 for the Basmallah png
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // First item is the Basmallah PNG image
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ColorFiltered(
                          colorFilter: isDarkTheme
                              ? ColorFilter.mode(
                                  Colors.transparent, BlendMode.multiply)
                              : const ColorFilter.matrix([
                                  -1,
                                  0,
                                  0,
                                  0,
                                  255,
                                  0,
                                  -1,
                                  0,
                                  0,
                                  255,
                                  0,
                                  0,
                                  -1,
                                  0,
                                  255,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ]),
                          child: Image.asset(
                            basmallahImagePath,
                            height: 50.0,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    }

                    final ayah = _ayahs[index - 1];
                    bool isHighlighted = widget.highlightAyah != null &&
                        ayah.numberInSurah == widget.highlightAyah;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding +
                            (isLandscape
                                ? safePadding.left + safePadding.right
                                : 0.0),
                        vertical: 8.0,
                      ),
                      child: GestureDetector(
                        onLongPress: () => _showBookmarkDialog(ayah),
                        child: Container(
                          decoration: isHighlighted
                              ? BoxDecoration(
                                  color: Colors.yellowAccent.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8.0),
                                )
                              : null,
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Number in Surah
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDarkTheme
                                      ? Colors.white
                                      : const Color(0xFF091945),
                                ),
                                child: Text(
                                  ayah.numberInSurah.toString(),
                                  style: TextStyle(
                                    color: isDarkTheme
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              // Ayah Text
                              Expanded(
                                child: Text(
                                  ayah.text,
                                  style: const TextStyle(
                                    fontFamily: 'Quran',
                                    fontSize: 20.0,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}