import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/student_models.dart';
import '../../../providers/student_provider.dart';

class MessagesMobileBody extends StatefulWidget {
  const MessagesMobileBody({super.key});

  @override
  State<MessagesMobileBody> createState() => _MessagesMobileBodyState();
}

class _MessagesMobileBodyState extends State<MessagesMobileBody> {
  bool _showDetail = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final selectedMessage = provider.selectedMessage;
    return Column(
      children: [
        // Top Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_showDetail)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () {
                      context.read<StudentProvider>().clearSelectedMessage();
                      setState(() {
                        _showDetail = false;
                      });
                    },
                  ),
                ),
              Text(
                'My Messages',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),

        // Scrollable Content
        Expanded(
          child: _showDetail
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    children: [
                      _buildTextReviewCard(selectedMessage),
                      const SizedBox(height: 20),
                      _buildFeedbackCard(selectedMessage),
                      const SizedBox(height: 20),
                    ],
                  ),
                )
              : _buildMessageList(),
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    final provider = context.watch<StudentProvider>();
    if (provider.isMessagesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.messagesError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: Center(
              child: Text(
                provider.messagesError!,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    if (provider.messages.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: Center(
              child: Text(
                'No messages yet.',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      children: provider.messages
          .map(
            (message) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: message.isUnread ? const Color(0xFFF7F9FC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: message.isUnread
                ? const Color(0xFF568AF2)
                : Colors.grey.shade300,
            width: message.isUnread ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (message.isUnread) ...[
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Text(
                      message.senderName,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: message.isUnread
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (message.isUnread) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'NEW',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  message.createdAtLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: message.isUnread
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextReviewCard(StudentMessage? message) {
    final feedback = StudentReadingFeedback.fromMessage(message);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Teacher Feedback',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF568AF2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildReportGrid(feedback),
          const SizedBox(height: 16),
          _buildPassageContainer(feedback),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(StudentMessage? message) {
    final feedback = StudentReadingFeedback.fromMessage(message);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            feedback.feedback.trim().isEmpty
                ? 'No feedback message was found.'
                : feedback.feedback,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '- Keep reading and keep blooming!',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportGrid(StudentReadingFeedback feedback) {
    return Row(
      children: [
        Expanded(child: _buildReportBox('OMISSION', feedback, 'omission')),
        const SizedBox(width: 6),
        Expanded(child: _buildReportBox('REPETITION', feedback, 'repetition')),
        const SizedBox(width: 6),
        Expanded(
          child: _buildReportBox(
            'SELF\nCORRECTION',
            feedback,
            'selfCorrection',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildReportBox(
            'MIS-\nPRONUNCIATION',
            feedback,
            'mispronunciation',
          ),
        ),
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
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color, width: 2.5),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.1,
            ),
          ),
          Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: 24,
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
      padding: const EdgeInsets.all(14),
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
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
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
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: key == null
                ? Colors.transparent
                : color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: key == null ? Colors.transparent : color,
              width: key == null ? 0 : 1.1,
            ),
          ),
          child: Text(
            entry.value,
            style: GoogleFonts.inter(
              fontSize: 13,
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
