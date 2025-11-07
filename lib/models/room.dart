class Room {
  final String id;
  final String name;
  final String location; // Floor/Building info
  final double xPosition; // 2D map X coordinate
  final double yPosition; // 2D map Y coordinate
  final double width;
  final double height;

  Room({
    required this.id,
    required this.name,
    required this.location,
    required this.xPosition,
    required this.yPosition,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'xPosition': xPosition,
      'yPosition': yPosition,
      'width': width,
      'height': height,
    };
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      xPosition: (json['xPosition'] as num).toDouble(),
      yPosition: (json['yPosition'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }
}
