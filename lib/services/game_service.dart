import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_data_model.dart';

class GameService {
  static const String baseUrl = 'https://pub.gamezop.com/v3/games';

  static Future<GameDataResponse?> fetchGames({String? id}) async {
    try {
      final String url = id != null ? '$baseUrl?id=$id' : baseUrl;
      print('Making API request to: $url');
      
      final response = await http.get(Uri.parse(url));

      print('API Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('Successfully parsed JSON response');
        
        final gameData = GameDataResponse.fromJson(jsonResponse);
        print('Found ${gameData.games.length} games');
        
        return gameData;
      } else {
        print('API request failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      return null;
    } catch (e) {
      print('Error in fetchGames: $e');
      return null;
    }
  }

  static List<String> getUniqueCategories(List<Game> games) {
    final Set<String> categories = {};
    
    for (final game in games) {
      categories.addAll(game.categories.en);
    }
    
    return categories.toList()..sort();
  }

  static List<Game> getGamesByCategory(List<Game> games, String category) {
    return games.where((game) => 
      game.categories.en.contains(category)
    ).toList();
  }
}
