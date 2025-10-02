class GameDataResponse {
  final List<Game> games;

  GameDataResponse({required this.games});

  factory GameDataResponse.fromJson(Map<String, dynamic> json) {
    return GameDataResponse(
      games: (json['games'] as List)
          .map((gameJson) => Game.fromJson(gameJson))
          .toList(),
    );
  }
}

class Game {
  final String code;
  final String url;
  final GameName name;
  final bool isPortrait;
  final GameDescription description;
  final GameAssets assets;
  final GameCategories categories;
  final GameTags tags;
  final int width;
  final int height;
  final String colorMuted;
  final String colorVibrant;
  final bool privateAllowed;
  final double rating;
  final int numberOfRatings;
  final int gamePlays;
  final bool hasIntegratedAds;

  Game({
    required this.code,
    required this.url,
    required this.name,
    required this.isPortrait,
    required this.description,
    required this.assets,
    required this.categories,
    required this.tags,
    required this.width,
    required this.height,
    required this.colorMuted,
    required this.colorVibrant,
    required this.privateAllowed,
    required this.rating,
    required this.numberOfRatings,
    required this.gamePlays,
    required this.hasIntegratedAds,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      code: json['code'] ?? '',
      url: json['url'] ?? '',
      name: GameName.fromJson(json['name'] ?? {}),
      isPortrait: json['isPortrait'] ?? false,
      description: GameDescription.fromJson(json['description'] ?? {}),
      assets: GameAssets.fromJson(json['assets'] ?? {}),
      categories: GameCategories.fromJson(json['categories'] ?? {}),
      tags: GameTags.fromJson(json['tags'] ?? {}),
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
      colorMuted: json['colorMuted'] ?? '',
      colorVibrant: json['colorVibrant'] ?? '',
      privateAllowed: json['privateAllowed'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      numberOfRatings: json['numberOfRatings'] ?? 0,
      gamePlays: json['gamePlays'] ?? 0,
      hasIntegratedAds: json['hasIntegratedAds'] ?? false,
    );
  }
}

class GameName {
  final String en;

  GameName({required this.en});

  factory GameName.fromJson(Map<String, dynamic> json) {
    return GameName(en: json['en'] ?? '');
  }
}

class GameDescription {
  final String en;

  GameDescription({required this.en});

  factory GameDescription.fromJson(Map<String, dynamic> json) {
    return GameDescription(en: json['en'] ?? '');
  }
}

class GameAssets {
  final String cover;
  final String brick;
  final String thumb;
  final String wall;
  final String square;
  final List<String> screens;
  final String coverTiny;
  final String brickTiny;

  GameAssets({
    required this.cover,
    required this.brick,
    required this.thumb,
    required this.wall,
    required this.square,
    required this.screens,
    required this.coverTiny,
    required this.brickTiny,
  });

  factory GameAssets.fromJson(Map<String, dynamic> json) {
    return GameAssets(
      cover: json['cover'] ?? '',
      brick: json['brick'] ?? '',
      thumb: json['thumb'] ?? '',
      wall: json['wall'] ?? '',
      square: json['square'] ?? '',
      screens: List<String>.from(json['screens'] ?? []),
      coverTiny: json['coverTiny'] ?? '',
      brickTiny: json['brickTiny'] ?? '',
    );
  }
}

class GameCategories {
  final List<String> en;

  GameCategories({required this.en});

  factory GameCategories.fromJson(Map<String, dynamic> json) {
    return GameCategories(
      en: List<String>.from(json['en'] ?? []),
    );
  }
}

class GameTags {
  final List<String> en;

  GameTags({required this.en});

  factory GameTags.fromJson(Map<String, dynamic> json) {
    return GameTags(
      en: List<String>.from(json['en'] ?? []),
    );
  }
}
