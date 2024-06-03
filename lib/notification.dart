class NotificationMessage {
  final String id;
  final String type;
  final String message;

  NotificationMessage({
    required this.id,
    required this.type,
    required this.message,
  });

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      id: json['id'].toString(),
      type: json['type'],
      message: json['message'],
    );
  }
}
