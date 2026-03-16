import 'package:flutter/material.dart';
import 'chat_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  bool _sending = false;

  late final ChatService _chat = ChatService(
    "https://chat-jzb2oeiixq-uc.a.run.app".trim(),
  );

  final List<_ChatMessage> _messages = [
    const _ChatMessage("Hi! 👋 I'm AskUCP, your campus assistant.", isUser: false),
    const _ChatMessage("You can ask about notices, teachers, or uploads.", isUser: false),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    if (_sending) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(text, isUser: true));
      _controller.clear();
      _messages.add(const _ChatMessage("Typing…", isUser: false, isTyping: true));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      final result = await _chat.send(text);

      if (!mounted) return;
      setState(() {
        if (_messages.isNotEmpty && _messages.last.isTyping) _messages.removeLast();
        _messages.add(
          _ChatMessage(
            result.answer.trim().isEmpty ? "No reply received." : result.answer.trim(),
            isUser: false,
            sourceLabels: result.sourceLabels,
          ),
        );
        _sending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_messages.isNotEmpty && _messages.last.isTyping) _messages.removeLast();
        _messages.add(const _ChatMessage(
          "Something went wrong. Please try again.",
          isUser: false,
        ));
        _sending = false;
      });
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.72;

    return Scaffold(
      // background is deprecated -> use surface
      backgroundColor: cs.surface,
      appBar: const _GradientAppBar(title: "AskUCP Assistant"),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];

                final align =
                    m.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

                final bubbleColor = m.isUser
                    ? cs.primaryContainer.withOpacity(.85)
                    : cs.surfaceVariant.withOpacity(.7);

                final textColor =
                    m.isUser ? cs.onPrimaryContainer : cs.onSurface;

                return Column(
                  crossAxisAlignment: align,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(18).copyWith(
                          bottomLeft: m.isUser ? const Radius.circular(18) : Radius.zero,
                          bottomRight: m.isUser ? Radius.zero : const Radius.circular(18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 8,
                            offset: const Offset(2, 3),
                            color: Colors.black.withOpacity(.08),
                          ),
                        ],
                      ),
                      child: Text(
                        m.text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          height: 1.4,
                          fontStyle: m.isTyping ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ),

                    // ✅ subtle trust line
                    if (!m.isUser && !m.isTyping && m.sourceLabels.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          "Based on official UCP information",
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.55),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),

          // Composer
          Container(
            color: cs.surface.withOpacity(.85),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 20),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_sending,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: _sending ? "Sending…" : "Ask something...",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: cs.surfaceVariant.withOpacity(.6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _sending ? cs.primary.withOpacity(.6) : cs.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _sending ? null : _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _GradientAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isTyping;
  final List<String> sourceLabels;

  const _ChatMessage(
    this.text, {
    required this.isUser,
    this.isTyping = false,
    this.sourceLabels = const [],
  });
}
