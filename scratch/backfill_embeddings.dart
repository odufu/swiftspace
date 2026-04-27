import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  // Load environment variables manually
  final envFile = File('.env');
  final lines = await envFile.readAsLines();
  final env = <String, String>{};
  for (final line in lines) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length >= 2) {
      env[parts[0]] = parts.sublist(1).join('=');
    }
  }

  final supabaseUrl = env['SUPABASE_URL']!;
  final supabaseKey = env['SUPABASE_ANON_KEY']!;
  // Service role key is required for writes — it bypasses RLS.
  // This is safe to use in a local CLI tool.
  final serviceKey = env['SUPABASE_SERVICE_ROLE_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtyd2tjaWxiaXRsc2JpdmtjdW5zIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NjI3MjMxMCwiZXhwIjoyMDkxODQ4MzEwfQ.bTrSyimJFE5R85iaIze3y92of4AipuB8uT6fy5h9vL0';
  final geminiKey = env['GEMINI_API_KEY']!;

  print('Fetching properties without embeddings...');
  // Fetch properties where embedding is null
  final response = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/properties?embedding=is.null'),
    headers: {
      'apikey': supabaseKey,
      'Authorization': 'Bearer $supabaseKey',
    },
  );

  if (response.statusCode != 200) {
    print('Failed to fetch properties: ${response.body}');
    return;
  }

  final List<dynamic> properties = jsonDecode(response.body);
  print('Found ${properties.length} properties to backfill.');

  for (final property in properties) {
    try {
      print('Generating embedding for: ${property['title']}');
      
      final textToEmbed = '''
        Title: ${property['title']}
        Location: ${property['location_name']}
        Description: ${property['description']}
        Type: ${property['type']}
        Bedrooms: ${property['beds']}
        Bathrooms: ${property['baths']}
        Amenities: ${(property['amenities'] as List?)?.join(', ') ?? ''}
        Listed By: ${property['lister_name']} ${property['company_name'] != null ? '(${property['company_name']})' : ''}
      '''.trim();

      // Call Gemini API — use gemini-embedding-001 (text-embedding-004 is deprecated)
      // outputDimensionality=768 matches our vector(768) column
      final geminiUrl = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent?key=$geminiKey');

      final geminiResponse = await http.post(
        geminiUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'models/gemini-embedding-001',
          'content': {
            'parts': [
              {'text': textToEmbed}
            ]
          },
          'outputDimensionality': 768,
        }),
      );

      if (geminiResponse.statusCode != 200) {
        print('Error from Gemini: ${geminiResponse.body}');
        continue;
      }

      final data = jsonDecode(geminiResponse.body);
      final embedding = data['embedding']?['values'];

      if (embedding == null) {
        print('No embedding returned from Gemini.');
        continue;
      }

      // Update Supabase.
      // IMPORTANT: Supabase/PostgREST requires pgvector values to be sent as a
      // bracket-formatted STRING like "[0.1,0.2,...]", not a raw JSON array.
      // Also use the service role key to bypass RLS on the UPDATE.
      final vectorString = '[${(embedding as List).join(',')}]';
      final updateResponse = await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/properties?id=eq.${property['id']}'),
        headers: {
          'apikey': serviceKey,
          'Authorization': 'Bearer $serviceKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal'
        },
        body: jsonEncode({'embedding': vectorString}),
      );

      if (updateResponse.statusCode >= 200 && updateResponse.statusCode < 300) {
        print('✅ Successfully updated embedding for: ${property['title']}');
      } else {
        print('❌ Failed to update Supabase: ${updateResponse.body}');
      }
    } catch (e) {
      print('❌ Failed to process property ${property['id']}: $e');
    }
  }

  print('Backfill complete!');
}

