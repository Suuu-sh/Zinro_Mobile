import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/socket_service.dart';
import 'online_lobby_screen.dart';

class OnlineHomeScreen extends StatefulWidget {
  const OnlineHomeScreen({super.key});

  static const String routeName = '/online';

  @override
  State<OnlineHomeScreen> createState() => _OnlineHomeScreenState();
}

class _OnlineHomeScreenState extends State<OnlineHomeScreen> {
  final _socketService = SocketService();
  final _nameController = TextEditingController();
  final _roomIdController = TextEditingController();
  bool _showJoinInput = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (!_socketService.isConnected) {
      _socketService.connect();
    }
  }

  void _createRoom() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'プレイヤー名を入力してください');
      return;
    }

    _socketService.socket.emit('create_room', _nameController.text.trim());
    _socketService.socket.once('room_created', (data) {
      Navigator.of(context).pushNamed(
        OnlineLobbyScreen.routeName,
        arguments: {
          'roomId': data['roomId'],
          'playerId': data['playerId'],
          'playerName': _nameController.text.trim(),
        },
      );
    });
  }

  void _joinRoom() {
    if (_nameController.text.trim().isEmpty ||
        _roomIdController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'プレイヤー名とルームIDを入力してください');
      return;
    }

    _socketService.socket.emit('join_room', {
      'roomId': _roomIdController.text.trim().toUpperCase(),
      'playerName': _nameController.text.trim(),
    });

    _socketService.socket.once('room_joined', (data) {
      Navigator.of(context).pushNamed(
        OnlineLobbyScreen.routeName,
        arguments: {
          'roomId': data['roomId'],
          'playerId': data['playerId'],
          'playerName': _nameController.text.trim(),
        },
      );
    });

    _socketService.socket.once('error', (message) {
      setState(() => _errorMessage = message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '🐺',
                        style: const TextStyle(fontSize: 80),
                      ).animate().fadeIn(duration: 600.ms).scale(),
                      const SizedBox(height: 16),
                      Text(
                        '神狼ゲーム',
                        style: GoogleFonts.notoSansJp(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: const Color(0xFFe94560).withOpacity(0.5),
                              offset: const Offset(0, 2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Divine Wolf',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          color: const Color(0xFFe94560),
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'プレイヤー名',
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: Color(0xFFe94560),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: const Color(0xFFe94560)
                                        .withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFe94560),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _createRoom,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFe94560),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_circle_outline),
                                    const SizedBox(width: 8),
                                    Text(
                                      '新しいルームを作成',
                                      style: GoogleFonts.notoSansJp(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    'または',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (!_showJoinInput)
                              TextButton(
                                onPressed: () =>
                                    setState(() => _showJoinInput = true),
                                child: Text(
                                  'ルームIDで参加する',
                                  style: GoogleFonts.notoSansJp(
                                    color: const Color(0xFFe94560),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: [
                                  TextField(
                                    controller: _roomIdController,
                                    style: const TextStyle(color: Colors.white),
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      labelText: 'ルームID',
                                      labelStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.vpn_key,
                                        color: Color(0xFFe94560),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: const Color(0xFFe94560)
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFe94560),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(duration: 300.ms)
                                      .slideY(begin: -0.2, end: 0),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _joinRoom,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF533483),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.login),
                                          const SizedBox(width: 8),
                                          Text(
                                            'ルームに参加',
                                            style: GoogleFonts.notoSansJp(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(duration: 300.ms)
                                      .slideY(begin: -0.2, end: 0),
                                ],
                              ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _socketService.isConnected
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _socketService.isConnected ? '接続済み' : '接続中...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }
}
