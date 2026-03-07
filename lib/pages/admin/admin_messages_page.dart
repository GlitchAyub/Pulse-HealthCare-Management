import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/healthreach_api.dart';

class AdminMessagesPage extends StatefulWidget {
  const AdminMessagesPage({super.key});

  @override
  State<AdminMessagesPage> createState() => _AdminMessagesPageState();
}

class _AdminMessagesPageState extends State<AdminMessagesPage> {
  final _api = HealthReachApi();
  bool _loading = true;
  String? _error;
  List<dynamic> _conversations = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final conversations = await _api.getChatConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Team Chat',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppTheme.textPrimary)),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('New Chat'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final leftPanel = _ConversationPanel(
              loading: _loading,
              error: _error,
              conversations: _conversations,
            );
            final rightPanel = const _ChatEmptyPanel();

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: leftPanel),
                  const SizedBox(width: 12),
                  Expanded(child: rightPanel),
                ],
              );
            }

            return Column(
              children: [
                leftPanel,
                const SizedBox(height: 12),
                rightPanel,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ConversationPanel extends StatelessWidget {
  const _ConversationPanel({
    required this.loading,
    required this.error,
    required this.conversations,
  });

  final bool loading;
  final String? error;
  final List<dynamic> conversations;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Conversations',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (error != null)
            Text(
              error!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFFE06C75)),
            )
          else if (conversations.isEmpty)
            Column(
              children: [
                const SizedBox(height: 12),
                const Icon(Icons.chat_bubble_outline,
                    size: 40, color: AppTheme.textMuted),
                const SizedBox(height: 8),
                Text('No conversations yet',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted)),
                Text('Start a new chat with a team member',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted)),
              ],
            )
          else
            Column(
              children: conversations
                  .whereType<Map<String, dynamic>>()
                  .map((conversation) => _ConversationTile(
                        conversation: conversation,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ChatEmptyPanel extends StatelessWidget {
  const _ChatEmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_outlined,
              size: 40, color: AppTheme.textMuted),
          const SizedBox(height: 8),
          Text('Select a conversation',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textMuted)),
          Text('or start a new chat with a team member',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final Map<String, dynamic> conversation;

  @override
  Widget build(BuildContext context) {
    final title = conversation['title']?.toString() ?? 'Conversation';
    final lastMessage = conversation['last_message']?.toString() ?? 'No messages';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.softBlue,
            child: Icon(Icons.person, color: AppTheme.deepBlue, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppTheme.textPrimary)),
                Text(lastMessage,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}
