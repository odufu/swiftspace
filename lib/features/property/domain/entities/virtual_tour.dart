import 'dart:convert';

class VirtualTour {
  final Map<String, TourNode> nodes;
  final String startNodeId;

  VirtualTour({
    required this.nodes,
    required this.startNodeId,
  });

  factory VirtualTour.fromMap(Map<String, dynamic> map) {
    final nodesMap = map['nodes'] as Map<String, dynamic>;
    final nodes = nodesMap.map((key, value) => MapEntry(
          key,
          TourNode.fromMap(value as Map<String, dynamic>),
        ));
    return VirtualTour(
      nodes: nodes,
      startNodeId: map['startNodeId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nodes': nodes.map((key, value) => MapEntry(key, value.toMap())),
      'startNodeId': startNodeId,
    };
  }

  String toJson() => json.encode(toMap());
  factory VirtualTour.fromJson(String source) => VirtualTour.fromMap(json.decode(source));
}

class TourNode {
  final String id;
  final String panoramaUrl;
  final String name;
  final List<TourHotspot> hotspots;

  TourNode({
    required this.id,
    required this.panoramaUrl,
    required this.name,
    this.hotspots = const [],
  });

  factory TourNode.fromMap(Map<String, dynamic> map) {
    return TourNode(
      id: map['id'],
      panoramaUrl: map['imageUrl'] ?? map['panoramaUrl'],
      name: map['name'],
      hotspots: (map['hotspots'] as List<dynamic>?)
              ?.map((h) => TourHotspot.fromMap(h as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'panoramaUrl': panoramaUrl,
      'name': name,
      'hotspots': hotspots.map((h) => h.toMap()).toList(),
    };
  }
}

class TourHotspot {
  final double latitude;
  final double longitude;
  final String targetNodeId;
  final String label;

  TourHotspot({
    required this.latitude,
    required this.longitude,
    required this.targetNodeId,
    required this.label,
  });

  factory TourHotspot.fromMap(Map<String, dynamic> map) {
    return TourHotspot(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      targetNodeId: map['targetNodeId'],
      label: map['label'] ?? 'Next Room',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'targetNodeId': targetNodeId,
      'label': label,
    };
  }
}
