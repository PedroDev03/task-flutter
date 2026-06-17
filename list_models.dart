import 'dart:convert';
import 'dart:io';

void main() async {
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print('No .env file found');
    return;
  }
  
  final lines = await envFile.readAsLines();
  String apiKey = '';
  for (final line in lines) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }

  if (apiKey.isEmpty) {
    print('No API key found in .env');
    return;
  }

  final client = HttpClient();
  final request = await client.getUrl(Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'));
  final response = await request.close();
  
  final responseBody = await response.transform(utf8.decoder).join();
  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(responseBody);
    final models = data['models'] as List<dynamic>;
    for (final model in models) {
      if (model['name'].toString().contains('gemini')) {
        print(model['name']);
      }
    }
  } else {
    print('Error ${response.statusCode}: $responseBody');
  }
  client.close();
}
