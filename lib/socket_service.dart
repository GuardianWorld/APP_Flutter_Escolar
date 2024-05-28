import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket socket;

  SocketService() : socket = IO.io('http://127.0.0.1:5000', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
  });

  void connect() {
    socket.connect();

    socket.on('connect', (_) {
      print('Connected to the server');
    });

    socket.on('notification', (data) {
      print('Received notification: $data');
    });

    socket.on('disconnect', (_) {
      print('Disconnected from the server');
    });
  }

  void sendLocation(Map<String, dynamic> location) {
    socket.emit('location', location);
  }
}