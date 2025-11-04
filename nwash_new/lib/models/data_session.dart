import 'dart:convert';
import 'dart:io';

class DataSession {
  final String id;
  final DateTime timestamp;
  final List<String> photos; // file paths
  final List<String> audios; // file paths
  final String notes;
  final bool uploaded;
  final bool draft;

  DataSession({
    required this.id,
    required this.timestamp,
    required this.photos,
    required this.audios,
    required this.notes,
    this.uploaded = false,
    this.draft = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'photos': photos,
      'audios': audios,
      'notes': notes,
      'uploaded': uploaded,
      'draft': draft,
    };
  }

  factory DataSession.fromJson(Map<String, dynamic> json) {
    return DataSession(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      photos: List<String>.from(json['photos'] ?? []),
      audios: List<String>.from(json['audios'] ?? []),
      notes: json['notes'] as String? ?? '',
      uploaded: json['uploaded'] as bool? ?? false,
      draft: json['draft'] as bool? ?? false,
    );
  }

  // Add copyWith method
  DataSession copyWith({
    String? id,
    DateTime? timestamp,
    List<String>? photos,
    List<String>? audios,
    String? notes,
    bool? uploaded,
    bool? draft,
  }) {
    return DataSession(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      photos: photos ?? this.photos,
      audios: audios ?? this.audios,
      notes: notes ?? this.notes,
      uploaded: uploaded ?? this.uploaded,
      draft: draft ?? this.draft,
    );
  }
}