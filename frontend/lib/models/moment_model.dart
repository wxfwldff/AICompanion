class Moment {
  final String characterId;
  final String text;
  final String? imageUrl;
  final String emotionState;
  final int timestamp;

  Moment({
    required this.characterId,
    required this.text,
    this.imageUrl,
    required this.emotionState,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'character_id': characterId,
        'text': text,
        'image_url': imageUrl,
        'emotion_state': emotionState,
        'timestamp': timestamp,
      };

  factory Moment.fromMap(Map<String, dynamic> map) => Moment(
        characterId: map['character_id'] as String,
        text: map['text'] as String,
        imageUrl: map['image_url'] as String?,
        emotionState: map['emotion_state'] as String,
        timestamp: map['timestamp'] as int,
      );
}
