import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  // Speech recognition replaces the attachment button, which only ever showed
  // an "Attachments coming soon!" snackbar. Recognition runs on the platform
  // recogniser, so audio stays on the device.
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _listening = false;

  /// Drives the pulsing rings while recording.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// Live loudness, 0-1, from the recogniser. The rings scale with it so the
  /// animation reflects the customer actually speaking rather than just
  /// spinning regardless.
  double _level = 0;

  /// What was in the field before dictation started, so recognised words are
  /// appended rather than replacing something already typed.
  String _textBeforeListening = '';

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() {
        _listening = false;
        _level = 0;
      });
      _pulse.stop();
      return;
    }

    if (!_speechReady) {
      _speechReady = await _speech.initialize(
        onStatus: (status) {
          // The recogniser stops itself after a pause in speech; reflect that
          // in the UI rather than leaving the mic looking live.
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _listening = false;
              _level = 0;
            });
            _pulse.stop();
          }
        },
        onError: (_) {
          if (!mounted) return;
          setState(() {
            _listening = false;
            _level = 0;
          });
          _pulse.stop();
        },
      );
    }

    if (!_speechReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Microphone unavailable. Check app permissions.')),
        ),
      );
      return;
    }

    _textBeforeListening = _controller.text;
    setState(() => _listening = true);
    _pulse.repeat(reverse: true);

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final prefix = _textBeforeListening.isEmpty
            ? ''
            : '${_textBeforeListening.trimRight()} ';
        setState(() {
          _controller.text = '$prefix${result.recognizedWords}';
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        // Reported in dB, roughly -2 to 10 on Android. Normalised for the rings.
        setState(() => _level = ((level + 2) / 12).clamp(0.0, 1.0));
      },
      listenOptions: stt.SpeechListenOptions(cancelOnError: true),
    );
  }

  // Starts empty. This list used to be pre-filled with a five-message
  // conversation in which "Finix AI" told every customer they had saved ₹4,200
  // in tax, that their Tesla goal was 64% funded and that they had ₹4.4 crore
  // saved. None of it came from the backend — it was fabricated advice with
  // invented figures, presented as though the assistant had actually computed
  // it. A disclaimer is shown instead until the customer asks something.
  final List<_Message> _messages = [];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
    final now = DateTime.now();
    final timeStr = "${now.hour > 12 ? now.hour - 12 : now.hour == 0 ? 12 : now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

    setState(() {
      _messages.add(_Message(
        isUser: true,
        text: text,
        time: timeStr,
      ));
      _controller.clear();
    });
    _scrollToBottom();
    
    try {
      final response = await ApiService.instance.chatbotQuery(prompt: text);
      final reply = response['content'] as String;
      
      if (mounted) {
        setState(() {
          _messages.add(_Message(
            isUser: false,
            text: reply,
            time: timeStr,
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_Message(
            isUser: false,
            text: "I am analyzing your portfolio and will get back to you shortly. Feel free to explore other dashboard sections in the meantime!",
            time: timeStr,
          ));
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Status Bar
            const _StatusBar(),

            // 2. Custom App Bar
            _buildAppBar(context),

            // 3. Standing AI disclaimer. Deliberately always visible rather
            // than a one-off intro message: it has to stay on screen once the
            // conversation is under way, which is exactly when someone might
            // act on what the assistant says.
            _buildAiDisclaimer(),

            // 4. Messages List
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyChatState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return _buildMessageBubble(msg);
                      },
                    ),
            ),

            // 5. Input Area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF2E75B6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tr('Finix AI'),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B2545),
                  ),
                ),
                Text(
                  tr('Online • Wealth Assistant'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF16A34A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.more_horiz_rounded,
              color: Color(0xFF475569),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Permanent notice that this is a generative model, not advice.
  Widget _buildAiDisclaimer() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8A951).withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: Color(0xFF8E7733)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Finix AI is an automated assistant and can be wrong. Nothing here '
              'is financial advice — check anything important with a qualified '
              'financial professional before you act on it.',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B5A28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_outlined,
                  color: Color(0xFF2E75B6), size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              tr('Ask Finix AI'),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A1628),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Questions about your spending, goals or tax. Answers are '
              'generated, so treat them as a starting point.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.5,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_Message msg) {
    final bool isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF0B2545) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: isUser
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: isUser ? Colors.white : const Color(0xFF0A1628),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                msg.time,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isUser ? Colors.white.withOpacity(0.6) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: tr('Ask Finix AI...'),
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                  ),
                  // Dictation. Replaces an attachment button that did
                  // nothing but show a "coming soon" snackbar.
                  _MicButton(
                    listening: _listening,
                    level: _level,
                    pulse: _pulse,
                    onTap: _toggleListening,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF2E75B6),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final bool isUser;
  final String text;
  final String time;

  _Message({
    required this.isUser,
    required this.text,
    required this.time,
  });
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Mic button with a recording animation.
///
/// While listening, two rings pulse outward behind the icon and scale with the
/// measured sound level, so the customer can see the app is hearing them —
/// a spinner that animates identically whether or not audio is arriving gives
/// no such feedback.
class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.listening,
    required this.level,
    required this.pulse,
    required this.onTap,
  });

  final bool listening;
  final double level;
  final AnimationController pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!listening) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Icon(Icons.mic_none_rounded, color: Color(0xFF64748B), size: 20),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        // Same footprint as the idle icon plus its padding, so swapping between
        // the two states does not shift the text field's width.
        width: 28,
        height: 28,
        child: AnimatedBuilder(
          animation: pulse,
          builder: (context, child) {
            // Loudness widens the rings; the controller keeps them moving even
            // during a silent moment so the control never looks frozen.
            final spread = 0.35 + (level * 0.5);
            return Stack(
              alignment: Alignment.center,
              children: [
                _ring(scale: 1 + spread * pulse.value, opacity: 0.10),
                _ring(scale: 1 + spread * pulse.value * 0.6, opacity: 0.18),
                child!,
              ],
            );
          },
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 12),
          ),
        ),
      ),
    );
  }

  Widget _ring({required double scale, required double opacity}) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withOpacity(opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
