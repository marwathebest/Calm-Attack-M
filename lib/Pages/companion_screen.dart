/// Chat with Bloom, the app's AI companion.
///
/// A calm, simple chat screen. The conversation lives only in memory on
/// this screen and is gone when the user leaves it.
library;

import 'package:flutter/material.dart';

import '../Animations/breathing_flower.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/companion_service.dart';
import '../core/widgets/botanical_background.dart';

class CompanionScreen extends StatefulWidget {
  /// When set, the user chose to talk through their check-ins: Bloom gets
  /// this summary and opens the conversation about it.
  final String? checkInSummary;

  const CompanionScreen({super.key, this.checkInSummary});

  @override
  State<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends State<CompanionScreen> {
  /// Local greetings in English and Arabic; they are never sent to the
  /// server.
  static const _greetings = [
    ChatMessage(
      role: 'assistant',
      text: "Hi, I'm Bloom. I'm here with you. How are you feeling right now?",
    ),
    ChatMessage(
      role: 'assistant',
      text: 'أنا بلوم، وأنا هنا معك. كيف تشعر الآن؟',
    ),
  ];

  static const _patternsGreeting = [
    ChatMessage(
      role: 'assistant',
      text: "Hi, I'm Bloom. Let's look at your check-ins together, gently.",
    ),
  ];

  late final List<ChatMessage> _localGreeting =
      widget.checkInSummary == null ? _greetings : _patternsGreeting;
  late final List<ChatMessage> _messages = [..._localGreeting];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _waiting = false;

  @override
  void initState() {
    super.initState();
    // Start the patterns conversation so the user doesn't have to.
    if (widget.checkInSummary != null) {
      _input.text = 'Can you help me understand my check-ins?';
      WidgetsBinding.instance.addPostFrameCallback((_) => _send());
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _waiting) return;
    _input.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text));
      _waiting = true;
    });
    _scrollToEnd();

    // The greetings are local, so the server only sees the real chat.
    final reply = await CompanionService.reply(
      _messages.skip(_localGreeting.length).toList(),
      checkInSummary: widget.checkInSummary,
    );
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(role: 'assistant', text: reply));
      _waiting = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryDeep,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 34,
              child: CustomPaint(
                painter: FlowerPainter(bloom: 0.75, holding: true),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Bloom'),
          ],
        ),
      ),
      body: BotanicalBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const _Notice(),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppSizes.mediumPadding),
                  itemCount: _messages.length + (_waiting ? 1 : 0),
                  itemBuilder: (context, i) => i < _messages.length
                      ? _Bubble(message: _messages[i])
                      : const _TypingBubble(),
                ),
              ),
              _InputBar(
                controller: _input,
                enabled: !_waiting,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Short, always-visible reminder of what Bloom is and isn't.
class _Notice extends StatelessWidget {
  const _Notice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceSoft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        CompanionService.isConfigured
            ? 'Bloom is an AI companion, not a therapist. '
                'In an emergency, call your local emergency number.'
            : 'Bloom is not connected yet, so replies are basic. '
                'In an emergency, call your local emergency number.',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

/// Picks right-to-left layout for Arabic and other RTL scripts.
TextDirection _directionOf(String text) {
  final rtl = RegExp(r'[֐-ࣿיִ-﷿ﹰ-﻿]');
  return rtl.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;

  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final mine = message.fromUser;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
        ),
        child: Text(
          message.text,
          textDirection: _directionOf(message.text),
          style: AppTextStyles.bodyMedium.copyWith(
            color: mine ? AppColors.textOnPrimary : AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const SizedBox(
          width: 36,
          height: 12,
          child: LinearProgressIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceSoft,
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Write how you feel…',
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            tooltip: 'Send',
            onPressed: enabled ? onSend : null,
            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
