import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/student_models.dart';
import '../../../providers/student_provider.dart';

class MessagesWebBody extends StatefulWidget {
  const MessagesWebBody({super.key});

  @override
  State<MessagesWebBody> createState() => _MessagesWebBodyState();
}

class _MessagesWebBodyState extends State<MessagesWebBody> {
  bool _showDetail = false;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 1100;
    final selectedMessage = context.watch<StudentProvider>().selectedMessage;

    final reviewCard = _buildTextReviewCard(isCompact, selectedMessage);
    final feedbackCard = _buildFeedbackCard(selectedMessage);

    return Container(
      padding: const EdgeInsets.all(32),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_showDetail)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        context.read<StudentProvider>().clearSelectedMessage();
                        setState(() {
                          _showDetail = false;
                        });
                      },
                    ),
                  ),
                Text(
                  _showDetail ? 'Message Details' : 'My Messages',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _showDetail
                  ? SingleChildScrollView(
                      child: isCompact
                          ? Column(
                              children: [
                                reviewCard,
                                const SizedBox(height: 24),
                                feedbackCard,
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: reviewCard),
                                const SizedBox(width: 24),
                                Expanded(flex: 2, child: feedbackCard),
                              ],
                            ),
                    )
                  : _buildMessageList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    final provider = context.watch<StudentProvider>();
    if (provider.isMessagesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.messagesError != null) {
      return Center(child: Text(provider.messagesError!));
    }
    if (provider.messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet.',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      );
    }
    return ListView(
      children: provider.messages
          .map(
            (message) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildMessageListItem(message),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMessageListItem(StudentMessage message) {
    return InkWell(
      onTap: () async {
        await context.read<StudentProvider>().selectMessage(message);
        if (!mounted) return;
        setState(() {
          _showDetail = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: message.isUnread ? const Color(0xFFF7F9FC) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: message.isUnread
                ? const Color(0xFF5C8DF6)
                : Colors.grey.shade300,
            width: message.isUnread ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (message.isUnread) ...[
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Text(
                      message.senderName,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: message.isUnread
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (message.isUnread) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'New Feedback',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: message.isUnread
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Text(
              message.createdAtLabel,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextReviewCard(bool isCompact, StudentMessage? message) {
    final feedback = StudentReadingFeedback.fromMessage(message);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black, width: 2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'From: ${message?.senderName ?? 'ReadBloom'}',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          Text(
            message?.createdAtLabel ?? '',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: Column(
              children: [
                Text(
                  message?.title ?? 'Reading Review',
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Teacher Feedback',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF5C8DF6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildReportGrid(feedback, isCompact),
          const SizedBox(height: 20),
          _buildPassageContainer(feedback),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(StudentMessage? message) {
    final feedback = StudentReadingFeedback.fromMessage(message);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black, width: 2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              'Teacher Feedback',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            feedback.feedback.trim().isEmpty
                ? 'No feedback message was found.'
                : feedback.feedback,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 80),
          Align(
            alignment: Alignment.center,
            child: Column(
              children: [
                Text(
                  '- Keep reading and',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'keep blooming!',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportGrid(StudentReadingFeedback feedback, bool isCompact) {
    final boxes = [
      _buildReportBox('OMISSION', feedback, 'omission'),
      _buildReportBox('REPETITION', feedback, 'repetition'),
      _buildReportBox('SELF\nCORRECTION', feedback, 'selfCorrection'),
      _buildReportBox('MIS-\nPRONUNCIATION', feedback, 'mispronunciation'),
    ];
    if (isCompact) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: boxes[0]),
              const SizedBox(width: 12),
              Expanded(child: boxes[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: boxes[2]),
              const SizedBox(width: 12),
              Expanded(child: boxes[3]),
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: boxes[0]),
        const SizedBox(width: 12),
        Expanded(child: boxes[1]),
        const SizedBox(width: 12),
        Expanded(child: boxes[2]),
        const SizedBox(width: 12),
        Expanded(child: boxes[3]),
      ],
    );
  }

  Widget _buildReportBox(
    String title,
    StudentReadingFeedback feedback,
    String key,
  ) {
    final color = _remarkColor(key);
    final count = feedback.remarks[key]?.count ?? 0;
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color, width: 2.5),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.1,
            ),
          ),
          Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassageContainer(StudentReadingFeedback feedback) {
    final text = feedback.transcript.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transcribed Passage',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildHighlightedWords(text, feedback),
        ],
      ),
    );
  }

  Widget _buildHighlightedWords(String text, StudentReadingFeedback feedback) {
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) {
      return const Text('No transcribed passage was found.');
    }
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      children: words.asMap().entries.map((entry) {
        final key = _remarkKeyForIndex(entry.key, entry.value, feedback);
        final color = key == null ? Colors.black87 : _remarkColor(key);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: key == null
                ? Colors.transparent
                : color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: key == null ? Colors.transparent : color,
              width: key == null ? 0 : 1.2,
            ),
          ),
          child: Text(
            entry.value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: key == null ? FontWeight.w600 : FontWeight.w900,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }

  String? _remarkKeyForIndex(
    int index,
    String word,
    StudentReadingFeedback feedback,
  ) {
    for (final entry in feedback.remarks.entries) {
      if (entry.value.indexes.contains(index)) return entry.key;
    }
    final normalizedWord = _normalizeWord(word);
    if (normalizedWord.isEmpty) return null;
    for (final entry in feedback.remarks.entries) {
      final selectedWords = entry.value.words.map(_normalizeWord).toSet();
      if (selectedWords.contains(normalizedWord)) return entry.key;
    }
    return null;
  }

  String _normalizeWord(String word) {
    return word.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Color _remarkColor(String key) {
    switch (key) {
      case 'omission':
        return Colors.red;
      case 'repetition':
        return const Color(0xFF8B5CF6);
      case 'selfCorrection':
        return const Color(0xFF10B981);
      case 'mispronunciation':
        return const Color(0xFFF97316);
      default:
        return Colors.black87;
    }
  }
}
