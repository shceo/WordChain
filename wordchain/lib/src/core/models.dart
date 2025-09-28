enum GameMode { relax, challenge, themed }

class Session {
  final String id;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final GameMode mode;
  final String seedWord;
  final int totalScore;
  final int durationSec;
  final String? pngPath;

  Session({
    required this.id,
    required this.startedAt,
    this.finishedAt,
    required this.mode,
    required this.seedWord,
    required this.totalScore,
    required this.durationSec,
    this.pngPath,
  });

  Session copyWith({
    DateTime? finishedAt,
    int? totalScore,
    int? durationSec,
    String? pngPath,
  }) =>
      Session(
        id: id,
        startedAt: startedAt,
        finishedAt: finishedAt ?? this.finishedAt,
        mode: mode,
        seedWord: seedWord,
        totalScore: totalScore ?? this.totalScore,
        durationSec: durationSec ?? this.durationSec,
        pngPath: pngPath ?? this.pngPath,
      );
}

class WordNode {
  final int id;
  final String text;
  final double x;
  final double y;
  final String? category;

  WordNode({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    this.category,
  });

  WordNode moveTo(double nx, double ny) =>
      WordNode(id: id, text: text, x: nx, y: ny, category: category);
}

class Edge {
  final int fromId;
  final int toId;
  final String letter;
  Edge({required this.fromId, required this.toId, required this.letter});
}

class Stats {
  final int totalWords;
  final int maxChain;
  final double avgWordsPerSession;

  const Stats({
    required this.totalWords,
    required this.maxChain,
    required this.avgWordsPerSession,
  });

  Stats addWords(int n) => Stats(
        totalWords: totalWords + n,
        maxChain: (maxChain >= n) ? maxChain : n,
        avgWordsPerSession: avgWordsPerSession, // вычисляй при чтении
      );
}

class AchievementProgress {
  final bool firstWeb;
  final bool brainstormer; // 50 слов за сессию
  final bool colorMaster;  // 5 категорий
  final bool speedThinker; // 10 слов/мин

  const AchievementProgress({
    required this.firstWeb,
    required this.brainstormer,
    required this.colorMaster,
    required this.speedThinker,
  });

  AchievementProgress copyWith({
    bool? firstWeb,
    bool? brainstormer,
    bool? colorMaster,
    bool? speedThinker,
  }) =>
      AchievementProgress(
        firstWeb: firstWeb ?? this.firstWeb,
        brainstormer: brainstormer ?? this.brainstormer,
        colorMaster: colorMaster ?? this.colorMaster,
        speedThinker: speedThinker ?? this.speedThinker,
      );
}
