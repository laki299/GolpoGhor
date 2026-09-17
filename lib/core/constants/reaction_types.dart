class ReactionTypes {
  static const String love = 'love';
  static const String wow = 'wow';
  static const String sad = 'sad';
  static const String thrill = 'thrill';
  static const String funny = 'funny';
  static const String fire = 'fire';

  static const List<String> all = [
    love,
    wow,
    sad,
    thrill,
    funny,
    fire,
  ];

  static String getEmoji(String type) {
    switch (type) {
      case love:
        return '❤️';
      case wow:
        return '🥰';
      case sad:
        return '😢';
      case thrill:
        return '😱';
      case funny:
        return '😂';
      case fire:
        return '🔥';
      default:
        return '❤️';
    }
  }

  static String getLabel(String type) {
    switch (type) {
      case love:
        return 'ভালো লেগেছে';
      case wow:
        return 'মুগ্ধ';
      case sad:
        return 'আবেগঘন';
      case thrill:
        return 'রোমাঞ্চকর';
      case funny:
        return 'মজার';
      case fire:
        return 'অসাধারণ';
      default:
        return 'ভালো লেগেছে';
    }
  }
}
