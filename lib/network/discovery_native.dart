import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'server_info.dart';

class NetworkDiscovery {
  static Stream<ServerInfo> discover() {
    late StreamController<ServerInfo> controller;
    RawDatagramSocket? socket;
    Timer? broadcastTimer;

    controller = StreamController<ServerInfo>(
      onListen: () async {
        try {
          // Bind to port 0 (dynamic port) to receive response broadcast
          socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
          socket!.broadcastEnabled = true;

          socket!.listen((event) {
            if (event == RawSocketEvent.read) {
              Datagram? dg = socket!.receive();
              if (dg != null) {
                final message = utf8.decode(dg.data);
                if (message.startsWith("BITTHEPLAYER_SERVER_INFO:")) {
                  final parts = message.split(":");
                  if (parts.length >= 4) {
                    final ip = parts[1];
                    final port = int.tryParse(parts[2]) ?? 4000;
                    final hostName = parts[3];
                    controller.add(ServerInfo(ip: ip, port: port, hostName: hostName));
                  }
                }
              }
            }
          });

          // Send initial and periodic discovery broadcast onto port 8888
          void sendDiscovery() {
            try {
              socket?.send(
                utf8.encode("DISCOVER_BITTHEPLAYER_SERVER"),
                InternetAddress("255.255.255.255"),
                8888,
              );
            } catch (e) {
              // Ignore socket errors during broadcast
            }
          }

          sendDiscovery();
          broadcastTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            sendDiscovery();
          });
        } catch (e) {
          print("[Discovery] Error starting UDP scanner: $e");
          controller.close();
        }
      },
      onCancel: () {
        broadcastTimer?.cancel();
        socket?.close();
      },
    );

    return controller.stream;
  }
}
