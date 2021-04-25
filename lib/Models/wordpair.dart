import 'dart:convert';

class WordPairModel {
  final String id;
  final String wordpair;
  WordPairModel({
    this.id,
    this.wordpair,
  });

  WordPairModel copyWith({
    String id,
    String wordpair,
  }) {
    return WordPairModel(
      id: id ?? this.id,
      wordpair: wordpair ?? this.wordpair,
    );
  }
}
