import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';

abstract class AIDataSource {
  Future<List<String>> generatePhrases(String term, String targetLanguage);
}

class AIDataSourceImpl implements AIDataSource {
  final Dio dio;
  final String Function() apiKeyProvider;

  AIDataSourceImpl({required this.dio, required this.apiKeyProvider});

  @override
  Future<List<String>> generatePhrases(
      String term, String targetLanguage) async {
    final apiKey = apiKeyProvider();
    if (apiKey.isEmpty) throw Exception('Gemini API key is not set.');

    final prompt =
        'Generate exactly ${ApiConstants.phrasesCount} example sentences '
        'using the term or phrasal verb "$term" in $targetLanguage. '
        'Each sentence should show the term used naturally in context. '
        'Return only the sentences, each on a new line, with no numbering or extra text.';

    final response = await dio.post(
      '${ApiConstants.geminiBaseUrl}?key=$apiKey',
      data: {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      },
    );

    final text =
        response.data['candidates'][0]['content']['parts'][0]['text'] as String;

    return text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(ApiConstants.phrasesCount)
        .toList();
  }
}
