class ServerInfo {
  final String ip;
  final int port;
  final String hostName;

  ServerInfo({
    required this.ip,
    required this.port,
    required this.hostName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerInfo &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          port == other.port;

  @override
  int get hashCode => ip.hashCode ^ port.hashCode;

  @override
  String toString() => 'ServerInfo($hostName at $ip:$port)';
}
