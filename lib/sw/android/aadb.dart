import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'dart:async';

class AADB {
  static final AADB _instance = AADB._internal();
  factory AADB() => _instance;
  AADB._internal();
  Socket? _socket;
  String? deviceId;
  bool isConnected = false;
  final BytesBuilder _buffer = BytesBuilder();
  Completer<bool>? _connectionCompleter;
  final Map<int, Completer<String>> _pendingRequests = {};
  final Map<int, StringBuffer> _responseBuffers = {};
  final Map<int, StreamController<List<int>>> _streamRequests = {};
  Future<bool> connect(String address) async {
    try {
      final List<String> parts = address.contains(':') ? address.split(':') : [address, '5555'];
      _socket = await Socket.connect(parts[0], int.parse(parts[1]), timeout: const Duration(seconds: 5));
      _connectionCompleter = Completer<bool>();
      _socket!.listen(_handleRawData, onError: (_) => _cleanup(), onDone: _cleanup);
      _sendPacket("CNXN", 0x01000000, 4096, "host::\x00");
      return await _connectionCompleter!.future.timeout(const Duration(seconds: 10), onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }

  void _handleRawData(Uint8List data) {
    _buffer.add(data);
    while (_buffer.length >= 24) {
      final Uint8List bytes = _buffer.toBytes();
      final ByteData byteData = bytes.buffer.asByteData();
      final int payloadLength = byteData.getInt32(12, Endian.little);
      if (bytes.length < 24 + payloadLength) break;
      final String command = utf8.decode(bytes.sublist(0, 4));
      final int remoteId = byteData.getInt32(4, Endian.little);
      final int localId = byteData.getInt32(8, Endian.little);
      final Uint8List payload = bytes.sublist(24, 24 + payloadLength);
      _processPacket(command, remoteId, localId, payload);
      _buffer.clear();
      _buffer.add(bytes.sublist(24 + payloadLength));
    }
  }

  void _processPacket(String command, int remoteId, int localId, Uint8List payload) {
    switch (command) {
      case "AUTH" when remoteId == 1:
        _sendPacket("AUTH", 3, 0, "AADB_KEY\x00");
      case "CNXN":
        isConnected = true;
        deviceId = "device";
        if (_connectionCompleter?.isCompleted == false) _connectionCompleter?.complete(true);
      case "WRTE":
        _responseBuffers[localId]?.write(utf8.decode(payload, allowMalformed: true));
        _streamRequests[localId]?.add(payload);
        _sendPacket("OKAY", localId, remoteId, "");
      case "CLSE":
        _pendingRequests.remove(localId)?.complete(_responseBuffers.remove(localId)?.toString().trim() ?? "");
        _streamRequests.remove(localId)?.close();
        _sendPacket("CLSE", localId, remoteId, "");
    }
  }

  void _sendPacket(String command, int arg0, int arg1, dynamic data) {
    if (_socket == null) return;
    final Uint8List payload = data is String ? utf8.encode(data) : (data as Uint8List);
    final Uint8List commandBytes = utf8.encode(command);
    int checksum = 0;
    for (int i = 0; i < payload.length; i++) checksum = (checksum + payload[i]) & 0xFFFFFFFF;
    final int magic = (commandBytes[0] ^ 0xFF) | ((commandBytes[1] ^ 0xFF) << 8) | ((commandBytes[2] ^ 0xFF) << 16) | ((commandBytes[3] ^ 0xFF) << 24);
    final BytesBuilder builder = BytesBuilder();
    builder.add(commandBytes);
    builder.add(_int32ToBytes(arg0));
    builder.add(_int32ToBytes(arg1));
    builder.add(_int32ToBytes(payload.length));
    builder.add(_int32ToBytes(checksum));
    builder.add(_int32ToBytes(magic));
    builder.add(payload);
    _socket!.add(builder.toBytes());
  }

  Uint8List _int32ToBytes(int value) => Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.little);
  void _cleanup() {
    isConnected = false;
    deviceId = null;
    _socket?.destroy();
    _socket = null;
    _pendingRequests.forEach((_, completer) => completer.complete("Error"));
    _pendingRequests.clear();
    _responseBuffers.clear();
    _streamRequests.forEach((_, controller) => controller.close());
    _streamRequests.clear();
    if (_connectionCompleter?.isCompleted == false) _connectionCompleter?.complete(false);
  }

  String _formatCommand(String command) {
    final List<String> parts = command.trim().split(RegExp(r'\s+'));
    final int index = parts.indexOf('shell');
    String result = index != -1 && index < parts.length - 1 ? parts.sublist(index + 1).join(' ') : (parts[0] == 'adb' ? parts.sublist(1).where((element) => !element.startsWith('-')).join(' ') : command.trim());
    return "shell:$result\x00";
  }

  Future<List<String>> listDevices() async => isConnected ? [deviceId!] : [];
  Future<String> execute(String command) async {
    if (!isConnected) return "";
    final int id = Random().nextInt(0x0FFFFFFF);
    final Completer<String> completer = Completer<String>();
    _pendingRequests[id] = completer;
    _responseBuffers[id] = StringBuffer();
    _sendPacket("OPEN", id, 0, _formatCommand(command));
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _pendingRequests.remove(id);
        return _responseBuffers.remove(id)?.toString().trim() ?? "";
      },
    );
  }

  Stream<List<int>> executeStream(String command) {
    final int id = Random().nextInt(0x0FFFFFFF);
    final StreamController<List<int>> controller = StreamController<List<int>>();
    if (!isConnected) return Stream.empty();
    _streamRequests[id] = controller;
    _sendPacket("OPEN", id, 0, _formatCommand(command));
    return controller.stream;
  }
}
