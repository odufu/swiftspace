import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://maps.app.goo.gl/FNZCMuSrCNkJpxLf7';
  
  try {
    final response = await http.get(
      Uri.parse(url), 
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      }
    );
    print('Status: ${response.statusCode}');
    print('Redirected to: ${response.request?.url}');
    
    // Check if body has any lat/lng data
    final body = response.body;
    print('Body excerpt: ${body.substring(0, body.length > 500 ? 500 : body.length)}');
    
    final pattern = RegExp(r'([-+]?\d{1,3}\.\d+)(?:%2C|,)\s?([-+]?\d{1,3}\.\d+)');
    final match = pattern.firstMatch(body);
    if (match != null) {
      print('Extracted from body: ${match.group(1)}, ${match.group(2)}');
    } else {
      print('URL Regex match from redirected url: ${pattern.firstMatch(response.request?.url.toString() ?? '')?.group(0)}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
