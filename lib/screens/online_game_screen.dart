import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../services/socket_service.dart';

class OnlineGameScreen extends StatefulWidget {
  const OnlineGameScreen({super.key});

  static const String routeName = '/online-game';

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  final _socketService = SocketService();
  late String _roomId;
  late String _playerId;
  late String _playerName;

  GameState? _gameState;
  PlayerInfo? _playerInfo;
  String? _selectedTarget;
  String? _actionResult;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _roomId = args['roomId'];
    _playerId = args['playerId'];
    _playerName = args['playerName'];

    _socketService.socket.on('role_assigned', _onRoleAssigned);
    _socketService.socket.on('game_state', _onGameState);
    _socketService.socket.on('divination_result', _onDivinationResult);
    _socketService.socket.on('observation_result', _onObservationResult);
    _socketService.socket.on('night_result', _onNightResult);
    _socketService.socket.on('voting_result', _onVotingResult);
    _socketService.socket.on('game_end', _onGameEnd);
  }

  void _onRoleAssigned(dynamic data) {
    setState(() {
      _playerInfo = PlayerInfo.fromJson(data as Map<String, dynamic>);
    });
  }

  void _onGameState(dynamic data) {
    setState(() {
      _gameState = GameState.fromJson(data as Map<String, dynamic>);
      _selectedTarget = null;
    });
  }

  void _onDivinationResult(dynamic data) {
    final result = data as Map<String, dynamic>;
    final target = _gameState!.players
        .firstWhere((p) => p.id == result['targetId']);
    setState(() {
      _actionResult =
          '占い結果: ${target.name}は${result['isWolf'] ? '人狼' : '市民'}です';
    });
  }

  void _onObservationResult(dynamic data) {
    final result = data as Map<String, dynamic>;
    final target = _gameState!.players
        .firstWhere((p) => p.id == result['targetId']);
    setState(() {
      _actionResult =
          '観測結果: ${target.name}は${result['didAct'] ? '行動しました' : '行動していません'}';
    });
  }

  void _onNightResult(dynamic data) {
    final result = data as Map<String, dynamic>;
    if (result['victim'] != null) {
      final victim = _gameState!.players
          .firstWhere((p) => p.id == result['victim']);
      _showDialog('夜の結果', '${victim.name}が襲撃されました');
    }
  }

  void _onVotingResult(dynamic data) {
    final result = data as Map<String, dynamic>;
    if (result['executed'] != null) {
      final executed = _gameState!.players
          .firstWhere((p) => p.id == result['executed']);
      _showDialog('投票結果', '${executed.name}が処刑されました');
    }
  }

  void _onGameEnd(dynamic data) {
    final result = data as Map<String, dynamic>;
    final winner = result['winner'] == 'village' ? '村人陣営' : '人狼陣営';
    _showDialog('ゲーム終了', '$winnerの勝利！', onClose: () {
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  void _showDialog(String title, String message, {VoidCallback? onClose}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.notoSansJp(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.notoSansJp(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onClose?.call();
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFFe94560))),
          ),
        ],
      ),
    );
  }

  void _submitNightAction() {
    if (_selectedTarget == null) return;
    _socketService.socket.emit('night_action', {
      'targetId': _selectedTarget,
      'actionType': 'default',
    });
    setState(() => _actionResult = '行動を送信しました');
  }

  void _startVoting() {
    _socketService.socket.emit('start_voting');
  }

  void _submitVote() {
    if (_selectedTarget == null) return;
    _socketService.socket.emit('vote', _selectedTarget);
    setState(() => _actionResult = '投票しました');
  }

  @override
  Widget build(BuildContext context) {
    if (_playerInfo == null || _gameState == null) {
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
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFe94560)),
          ),
        ),
      );
    }

    final alivePlayers =
        _gameState!.players.where((p) => p.alive && p.id != _playerId).toList();

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
              _buildHeader(),
              if (_actionResult != null) _buildActionResult(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRoleCard(),
                      const SizedBox(height: 20),
                      if (_playerInfo!.alive) ...[
                        _buildPhaseInfo(),
                        const SizedBox(height: 20),
                        if (_gameState!.isNight &&
                            _playerInfo!.role.nightAction)
                          _buildPlayerSelection(alivePlayers),
                        if (_gameState!.isVoting)
                          _buildPlayerSelection(alivePlayers),
                      ],
                    ],
                  ),
                ),
              ),
              if (_playerInfo!.alive) _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String phaseText = '';
    IconData phaseIcon = Icons.nightlight;
    
    if (_gameState!.isNight) {
      phaseText = '夜';
      phaseIcon = Icons.nightlight;
    } else if (_gameState!.isDay) {
      phaseText = '昼';
      phaseIcon = Icons.wb_sunny;
    } else if (_gameState!.isVoting) {
      phaseText = '投票';
      phaseIcon = Icons.how_to_vote;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFe94560),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(phaseIcon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$phaseText（${_gameState!.day}日目）',
                    style: GoogleFonts.notoSansJp(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getPhaseHint(),
                    style: GoogleFonts.notoSansJp(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  String _getPhaseHint() {
    if (_gameState!.isNight) return '役職の能力を使用してください';
    if (_gameState!.isDay) return '議論を行ってください';
    if (_gameState!.isVoting) return '処刑する人を投票してください';
    return '';
  }

  Widget _buildActionResult() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFe94560).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe94560)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Color(0xFFe94560)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _actionResult!,
              style: GoogleFonts.notoSansJp(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).shake();
  }

  Widget _buildRoleCard() {
    final role = _playerInfo!.role;
    final roleColor = role.isWerewolf
        ? const Color(0xFFe94560)
        : const Color(0xFF2F9C95);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            roleColor.withOpacity(0.3),
            roleColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: roleColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                role.isWerewolf ? '🐺' : '👼',
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'あなたの役職',
                      style: GoogleFonts.notoSansJp(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      role.name,
                      style: GoogleFonts.notoSansJp(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            role.description,
            style: GoogleFonts.notoSansJp(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (_playerInfo!.werewolfTeam != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '仲間の人狼:',
                    style: GoogleFonts.notoSansJp(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._playerInfo!.werewolfTeam!.map(
                    (wolf) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${wolf.name}',
                        style: GoogleFonts.notoSansJp(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale();
  }

  Widget _buildPhaseInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            _gameState!.isNight
                ? Icons.nightlight
                : _gameState!.isDay
                    ? Icons.wb_sunny
                    : Icons.how_to_vote,
            color: const Color(0xFFe94560),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getPhaseDescription(),
              style: GoogleFonts.notoSansJp(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPhaseDescription() {
    if (_gameState!.isNight && _playerInfo!.role.nightAction) {
      return '対象を選択して行動してください';
    } else if (_gameState!.isNight) {
      return '他のプレイヤーの行動を待っています';
    } else if (_gameState!.isDay) {
      return '議論を行い、投票フェーズに進んでください';
    } else if (_gameState!.isVoting) {
      return '処刑する人を選んで投票してください';
    }
    return '';
  }

  Widget _buildPlayerSelection(List<Player> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '対象を選択',
          style: GoogleFonts.notoSansJp(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...players.map((player) {
          final isSelected = _selectedTarget == player.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedTarget = player.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFe94560).withOpacity(0.3)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFe94560)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFe94560).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        player.name.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      player.name,
                      style: GoogleFonts.notoSansJp(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Color(0xFFe94560)),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
        }),
      ],
    );
  }

  Widget _buildActionButton() {
    String buttonText = '';
    VoidCallback? onPressed;

    if (_gameState!.isNight && _playerInfo!.role.nightAction) {
      buttonText = '行動を実行';
      onPressed = _selectedTarget != null ? _submitNightAction : null;
    } else if (_gameState!.isDay) {
      buttonText = '投票フェーズへ';
      onPressed = _startVoting;
    } else if (_gameState!.isVoting) {
      buttonText = '投票する';
      onPressed = _selectedTarget != null ? _submitVote : null;
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed != null
                ? const Color(0xFFe94560)
                : Colors.white.withOpacity(0.1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            disabledBackgroundColor: Colors.white.withOpacity(0.1),
            disabledForegroundColor: Colors.white.withOpacity(0.3),
          ),
          child: Text(
            buttonText,
            style: GoogleFonts.notoSansJp(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _socketService.socket.off('role_assigned');
    _socketService.socket.off('game_state');
    _socketService.socket.off('divination_result');
    _socketService.socket.off('observation_result');
    _socketService.socket.off('night_result');
    _socketService.socket.off('voting_result');
    _socketService.socket.off('game_end');
    super.dispose();
  }
}
