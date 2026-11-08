import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/teacher_provider.dart';
import '../../../models/teacher_models.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/loading_dialog.dart';

class BooksMobileBody extends StatefulWidget {
  const BooksMobileBody({super.key});

  @override
  State<BooksMobileBody> createState() => _BooksMobileBodyState();
}

class _BooksMobileBodyState extends State<BooksMobileBody> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _questionDrafts = List.generate(3, (_) => _QuestionDraftControllers());
  String _selectedGrade = 'Grade 4';
  String _selectedSection = 'Section A';

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    for (final draft in _questionDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  bool _isAddBookDirty() {
    return _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty ||
        _questionDrafts.any((draft) => draft.hasContent);
  }

  Future<void> _closeAddBookDialog(BuildContext context) async {
    if (_isAddBookDirty()) {
      final shouldClose = await showAppConfirmDialog(
        context,
        title: 'Discard Book Draft?',
        message:
            'Your title, passage, and quiz questions will be lost if you close this form.',
        confirmLabel: 'Discard',
        isDanger: true,
      );
      if (!shouldClose || !context.mounted) return;
    }
    Navigator.of(context).pop();
  }

  void _showAddBookDialog(BuildContext context) {
    final prov = context.read<TeacherProvider>();
    final sectionChoices = _sectionChoicesFor(prov);
    _titleController.clear();
    _contentController.clear();
    for (final draft in _questionDrafts) {
      draft.clear();
    }
    _selectedGrade = sectionChoices.first.grade;
    _selectedSection = sectionChoices.first.section;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PopScope<Object?>(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (!didPop) await _closeAddBookDialog(context);
              },
              child: Center(
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Container(
                        width: 320,
                        constraints: BoxConstraints(
                          maxHeight:
                              MediaQuery.of(context).size.height -
                              MediaQuery.of(context).viewInsets.bottom -
                              48,
                        ),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Add Book',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _closeAddBookDialog(context),
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Title Field
                                Text(
                                  'Book Title',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _titleController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: _glassInputDecoration(
                                    'Book Title',
                                    hintText: 'Enter title...',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter a title';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Grade Level Dropdown
                                Text(
                                  'Grade Level',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedGrade,
                                      dropdownColor: const Color(0xFF1E293B),
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.white70,
                                      ),
                                      isExpanded: true,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      onChanged: (newValue) {
                                        setDialogState(() {
                                          _selectedGrade = newValue!;
                                          _selectedSection = sectionChoices
                                              .firstWhere(
                                                (choice) =>
                                                    choice.grade ==
                                                    _selectedGrade,
                                              )
                                              .section;
                                        });
                                      },
                                      items: sectionChoices
                                          .map((choice) => choice.grade)
                                          .toSet()
                                          .map<DropdownMenuItem<String>>((
                                            value,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Section Dropdown
                                Text(
                                  'Section',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedSection,
                                      dropdownColor: const Color(0xFF1E293B),
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.white70,
                                      ),
                                      isExpanded: true,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      onChanged: (newValue) {
                                        setDialogState(() {
                                          _selectedSection = newValue!;
                                        });
                                      },
                                      items: sectionChoices
                                          .where(
                                            (choice) =>
                                                choice.grade == _selectedGrade,
                                          )
                                          .map<DropdownMenuItem<String>>((
                                            choice,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: choice.section,
                                              child: Text(choice.section),
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showAutoGenerateDialog(
                                      context,
                                      setDialogState,
                                    ),
                                    icon: const Icon(
                                      Icons.auto_awesome,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Auto Generate',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFFBBF24),
                                      side: BorderSide(
                                        color: const Color(
                                          0xFFFBBF24,
                                        ).withValues(alpha: 0.75),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Content Field
                                Text(
                                  'Content',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _contentController,
                                  maxLines: 5,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: _glassInputDecoration(
                                    'Content',
                                    hintText: 'Paste full texts...',
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter content';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                ...List.generate(
                                  _questionDrafts.length,
                                  (index) => _buildQuestionFields(
                                    setDialogState,
                                    _questionDrafts[index],
                                    index,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Save button
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: prov.isBooksLoading
                                        ? null
                                        : () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              final messenger =
                                                  ScaffoldMessenger.of(context);
                                              final navigator = Navigator.of(
                                                context,
                                              );
                                              final error =
                                                  await runWithLoadingDialog(
                                                    context,
                                                    () => context
                                                        .read<TeacherProvider>()
                                                        .addBook(
                                                          title:
                                                              _titleController
                                                                  .text,
                                                          grade: _selectedGrade,
                                                          section:
                                                              _selectedSection,
                                                          content:
                                                              _contentController
                                                                  .text,
                                                          questions:
                                                              _questionDrafts
                                                                  .map(
                                                                    (
                                                                      draft,
                                                                    ) => draft
                                                                        .toInput(),
                                                                  )
                                                                  .toList(),
                                                        ),
                                                    message: 'Saving book...',
                                                  );
                                              if (error != null) {
                                                if (!context.mounted) return;
                                                await showAppMessageDialog(
                                                  context,
                                                  title: 'Book Not Published',
                                                  message: error,
                                                  isDanger: true,
                                                );
                                                return;
                                              }
                                              navigator.pop();
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text('Book added!'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF60A5FA),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: prov.isBooksLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'Publish Book',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAutoGenerateDialog(
    BuildContext addBookContext,
    StateSetter setAddBookState,
  ) {
    final promptController = TextEditingController();
    var quizCount = 3;
    var passageLength = 'short';
    var isGenerating = false;

    Future<void> closeGenerateDialog(BuildContext context) async {
      if (isGenerating) return;
      if (promptController.text.trim().isNotEmpty) {
        final shouldClose = await showAppConfirmDialog(
          context,
          title: 'Discard Prompt?',
          message: 'Your story prompt and generation settings will be lost.',
          confirmLabel: 'Discard',
          isDanger: true,
        );
        if (!shouldClose || !context.mounted) return;
      }
      Navigator.of(context).pop();
    }

    showDialog(
      context: addBookContext,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setGenerateState) {
            return PopScope<Object?>(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (!didPop) await closeGenerateDialog(dialogContext);
              },
              child: Center(
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Container(
                        width: (MediaQuery.of(context).size.width * 0.9)
                            .clamp(340.0, 420.0),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Auto Generate',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: isGenerating
                                        ? null
                                        : () => closeGenerateDialog(
                                            dialogContext,
                                          ),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: promptController,
                                maxLines: 4,
                                maxLength: 1000,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                decoration: _glassInputDecoration(
                                  'Please state what story you like',
                                  hintText: 'Create a passage about kindness.',
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int>(
                                initialValue: quizCount,
                                dropdownColor: const Color(0xFF1E293B),
                                style: GoogleFonts.outfit(color: Colors.white),
                                decoration: _glassInputDecoration(
                                  'Quiz questions',
                                ),
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('1')),
                                  DropdownMenuItem(value: 2, child: Text('2')),
                                  DropdownMenuItem(value: 3, child: Text('3')),
                                ],
                                onChanged: (value) {
                                  setGenerateState(
                                    () => quizCount = value ?? 3,
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: passageLength,
                                dropdownColor: const Color(0xFF1E293B),
                                style: GoogleFonts.outfit(color: Colors.white),
                                decoration: _glassInputDecoration(
                                  'Passage length',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'short',
                                    child: Text('Short'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'medium',
                                    child: Text('Medium'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'long',
                                    child: Text('Long'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setGenerateState(
                                    () => passageLength = value ?? 'short',
                                  );
                                },
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: isGenerating
                                          ? null
                                          : () => closeGenerateDialog(
                                              dialogContext,
                                            ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: isGenerating
                                          ? null
                                          : () async {
                                              setGenerateState(
                                                () => isGenerating = true,
                                              );
                                              final provider = addBookContext
                                                  .read<TeacherProvider>();
                                              final messenger =
                                                  ScaffoldMessenger.of(
                                                    addBookContext,
                                                  );
                                              final navigator = Navigator.of(
                                                dialogContext,
                                              );
                                              final draft =
                                                  await runWithLoadingDialog(
                                                    dialogContext,
                                                    () => provider
                                                        .generateBookDraft(
                                                          prompt:
                                                              promptController
                                                                  .text,
                                                          grade: _selectedGrade,
                                                          section:
                                                              _selectedSection,
                                                          quizCount: quizCount,
                                                          passageLength:
                                                              passageLength,
                                                        ),
                                                    message:
                                                        'Generating book...',
                                                  );

                                              if (draft == null) {
                                                if (dialogContext.mounted) {
                                                  setGenerateState(
                                                    () => isGenerating = false,
                                                  );
                                                }
                                                if (!dialogContext.mounted) {
                                                  return;
                                                }
                                                await showAppMessageDialog(
                                                  dialogContext,
                                                  title: 'Generation Failed',
                                                  message:
                                                      provider
                                                          .generateBookDraftError ??
                                                      'Unable to generate book content right now.',
                                                  isDanger: true,
                                                );
                                                return;
                                              }

                                              if (_isAddBookDirty()) {
                                                if (!dialogContext.mounted) {
                                                  return;
                                                }
                                                final shouldReplace =
                                                    await showAppConfirmDialog(
                                                      dialogContext,
                                                      title:
                                                          'Replace Current Draft?',
                                                      message:
                                                          'Generated content will replace the title, passage, and quiz questions currently in the form.',
                                                      confirmLabel: 'Replace',
                                                      isDanger: true,
                                                    );
                                                if (!shouldReplace) {
                                                  if (dialogContext.mounted) {
                                                    setGenerateState(
                                                      () =>
                                                          isGenerating = false,
                                                    );
                                                  }
                                                  return;
                                                }
                                              }

                                              setAddBookState(
                                                () =>
                                                    _applyGeneratedDraft(draft),
                                              );
                                              navigator.pop();
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Generated draft added to the form.',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 12,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.auto_awesome,
                                        size: 16,
                                      ),
                                      label: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Generate',
                                          maxLines: 1,
                                          softWrap: false,
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(promptController.dispose);
  }

  InputDecoration _glassInputDecoration(
    String label, {
    String? hintText,
    EdgeInsetsGeometry? contentPadding,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF60A5FA)),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
    );
  }

  void _applyGeneratedDraft(GeneratedBookDraft draft) {
    _titleController.text = draft.title;
    _contentController.text = draft.passageText;
    for (final questionDraft in _questionDrafts) {
      questionDraft.clear();
    }
    for (var index = 0; index < draft.questions.length; index++) {
      final generatedQuestion = draft.questions[index];
      final target = _questionDrafts[index];
      target.questionController.text = generatedQuestion.questionText;
      target.correctOptionIndex = generatedQuestion.correctOptionIndex;
      for (
        var optionIndex = 0;
        optionIndex < generatedQuestion.options.length &&
            optionIndex < target.optionControllers.length;
        optionIndex++
      ) {
        target.optionControllers[optionIndex].text =
            generatedQuestion.options[optionIndex];
      }
    }
  }

  Widget _buildQuestionFields(
    StateSetter setDialogState,
    _QuestionDraftControllers draft,
    int questionIndex,
  ) {
    final isRequired = questionIndex == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRequired
                ? 'Quiz Question ${questionIndex + 1}'
                : 'Quiz Question ${questionIndex + 1} (optional)',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: draft.questionController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _glassInputDecoration(
              'Quiz Question ${questionIndex + 1}',
              hintText: 'Enter a question...',
              contentPadding: const EdgeInsets.all(12),
            ),
            validator: (value) {
              if (isRequired && (value == null || value.trim().isEmpty)) {
                return 'Please enter at least one quiz question';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          ...List.generate(4, (optionIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextFormField(
                controller: draft.optionControllers[optionIndex],
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: _glassInputDecoration(
                  'Option ${optionIndex + 1}',
                  prefixIcon: IconButton(
                    onPressed: () {
                      setDialogState(() {
                        draft.correctOptionIndex = optionIndex;
                      });
                    },
                    icon: Icon(
                      draft.correctOptionIndex == optionIndex
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: const Color(0xFF60A5FA),
                    ),
                  ),
                  hintText: 'Option ${optionIndex + 1}',
                  contentPadding: const EdgeInsets.all(12),
                ),
                validator: (value) {
                  if (isRequired &&
                      optionIndex < 2 &&
                      (value == null || value.trim().isEmpty)) {
                    return 'At least two options are required';
                  }
                  return null;
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  List<_SectionChoice> _sectionChoicesFor(TeacherProvider prov) {
    final choices = prov.assignedSections
        .map(_SectionChoice.fromLabel)
        .whereType<_SectionChoice>()
        .toList();
    if (choices.isEmpty) {
      return const [
        _SectionChoice('Grade 4', 'Section A'),
        _SectionChoice('Grade 4', 'Section B'),
      ];
    }
    return choices;
  }

  void _showBookContentDialog(BuildContext context, Book book) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (BuildContext context) {
        return Center(
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  width: 320,
                  constraints: const BoxConstraints(maxHeight: 450),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${book.grade} • ${book.section}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white24, thickness: 1),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            book.content,
                            textAlign: TextAlign.left,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TeacherProvider>();

    // Sort books
    final sortedBooks = List<Book>.from(prov.books)
      ..sort((a, b) {
        int gradeComp = a.grade.compareTo(b.grade);
        if (gradeComp != 0) return gradeComp;
        int sectComp = a.section.compareTo(b.section);
        if (sectComp != 0) return sectComp;
        return a.title.compareTo(b.title);
      });

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBookDialog(context),
        backgroundColor: const Color(0xFF60A5FA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 12.0),
            child: Text(
              'Books Library',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),

          // List
          Expanded(
            child: sortedBooks.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.45,
                        child: Center(
                          child: Text(
                            'No books available.',
                            style: GoogleFonts.outfit(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    itemCount: sortedBooks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final book = sortedBooks[index];
                      return InkWell(
                        onTap: () => _showBookContentDialog(context, book),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF60A5FA,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF60A5FA,
                                    ).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.menu_book,
                                  color: Color(0xFF60A5FA),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.white54,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionChoice {
  final String grade;
  final String section;

  const _SectionChoice(this.grade, this.section);

  static _SectionChoice? fromLabel(String label) {
    final parts = label.split(' - ');
    if (parts.length < 2) return null;
    return _SectionChoice(parts.first.trim(), parts.sublist(1).join(' - '));
  }
}

class _QuestionDraftControllers {
  final questionController = TextEditingController();
  final optionControllers = List.generate(4, (_) => TextEditingController());
  int correctOptionIndex = 0;

  void clear() {
    questionController.clear();
    for (final controller in optionControllers) {
      controller.clear();
    }
    correctOptionIndex = 0;
  }

  void dispose() {
    questionController.dispose();
    for (final controller in optionControllers) {
      controller.dispose();
    }
  }

  BookQuestionInput toInput() {
    return BookQuestionInput(
      questionText: questionController.text,
      options: optionControllers.map((controller) => controller.text).toList(),
      correctOptionIndex: correctOptionIndex,
    );
  }

  bool get hasContent {
    return questionController.text.trim().isNotEmpty ||
        optionControllers.any(
          (controller) => controller.text.trim().isNotEmpty,
        ) ||
        correctOptionIndex != 0;
  }
}
