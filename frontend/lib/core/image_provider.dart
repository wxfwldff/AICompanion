import 'dart:math';

/// 图片源类型
enum ImageSourceType { placeholder, network, aiGenerated }

/// 情绪 → 图片选择引擎
/// 当前使用免费可用的占位图/风景图 URL，后续可对接 AI 生成接口
class ImageEngine {
  final Random _random = Random();
  ImageSourceType sourceType;

  ImageEngine({this.sourceType = ImageSourceType.network});

  /// 根据情绪状态返回图片 URL（情绪键值 [love, jealousy, dependency, coldness, missing]）
  String getImageUrlForEmotion(Map<String, double> emotions) {
    final love = emotions['love'] ?? 0;
    final jealousy = emotions['jealousy'] ?? 0;
    final coldness = emotions['coldness'] ?? 0;
    final missing = emotions['missing'] ?? 0;
    final dependency = emotions['dependency'] ?? 0;

    // 优先级：最高情绪决定图片风格
    if (jealousy > 70) return _jealousyImage();
    if (love > 70) return _loveImage();
    if (missing > 60) return _missingImage();
    if (dependency > 70) return _dependencyImage();
    if (coldness > 60) return _coldnessImage();
    if (love > 50) return _loveImage();

    return _defaultImage();
  }

  // ---------- 各情绪图片池 ----------
  // 使用 picsum.photos —— 免费、稳定、支持 HTTPS 的占位图
  // 格式：https://picsum.photos/seed/{seed}/{width}/{height}
  // seed 固定保证同情绪展示一致图片

  String _loveImage() {
    final seeds = [
      'https://picsum.photos/seed/warm/400/300',
      'https://picsum.photos/seed/sunset/400/300',
      'https://picsum.photos/seed/rose/400/300',
      'https://picsum.photos/seed/cozy/400/300',
    ];
    return seeds[_random.nextInt(seeds.length)];
  }

  String _jealousyImage() {
    final seeds = [
      'https://picsum.photos/seed/storm/400/300',
      'https://picsum.photos/seed/dark/400/300',
      'https://picsum.photos/seed/alone/400/300',
      'https://picsum.photos/seed/rain/400/300',
    ];
    return seeds[_random.nextInt(seeds.length)];
  }

  String _missingImage() {
    final seeds = [
      'https://picsum.photos/seed/lonely/400/300',
      'https://picsum.photos/seed/night/400/300',
      'https://picsum.photos/seed/faraway/400/300',
      'https://picsum.photos/seed/waiting/400/300',
    ];
    return seeds[_random.nextInt(seeds.length)];
  }

  String _dependencyImage() {
    final seeds = [
      'https://picsum.photos/seed/together/400/300',
      'https://picsum.photos/seed/hug/400/300',
      'https://picsum.photos/seed/warmth/400/300',
      'https://picsum.photos/seed/companion/400/300',
    ];
    return seeds[_random.nextInt(seeds.length)];
  }

  String _coldnessImage() {
    final seeds = [
      'https://picsum.photos/seed/ice/400/300',
      'https://picsum.photos/seed/frost/400/300',
      'https://picsum.photos/seed/void/400/300',
      'https://picsum.photos/seed/silence/400/300',
    ];
    return seeds[_random.nextInt(seeds.length)];
  }

  String _defaultImage() {
    final seeds = [
      'https://picsum.photos/seed/daily/400/300',
      'https://picsum.photos/seed/moment/400/300',
      'https://picsum.photos/seed/scenery/400/300',
    ];
    return seeds[_random.nextInt(seeds.length)];
  }
}
