import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/loading_dialog.dart';

enum AdminManagementView { sections, books, readingHistory }

class AdminManagementBody extends StatefulWidget {
  final AdminManagementView view;

  const AdminManagementBody({super.key, required this.view});

  @override
  State<AdminManagementBody> createState() => _AdminManagementBodyState();
}

class _AdminManagementBodyState extends State<AdminManagementBody> {
  static const int _pageSize = 8;

  int _sectionsPage = 1;
  int _booksPage = 1;
  int _historiesPage = 1;
  int _historyPageSize = 8;
  String _sectionSearchQuery = '';
  String _bookSearchQuery = '';
  String _historySearchQuery = '';

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();
    final table = switch (widget.view) {
      AdminManagementView.sections => _buildSectionsTable(context, prov),
      AdminManagementView.books => _buildBooksTable(context, prov),
      AdminManagementView.readingHistory => _buildReadingHistoryTable(
        context,
        prov,
      ),
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          child: table,
        ),
      ),
    );
  }

  Widget _buildSectionsTable(BuildContext context, AdminProvider prov) {
    final query = _sectionSearchQuery.trim().toLowerCase();
    final sections = prov.sections.where((section) {
      if (query.isEmpty) return true;
      return section.gradeLevel.toLowerCase().contains(query) ||
          section.name.toLowerCase().contains(query) ||
          section.label.toLowerCase().contains(query);
    }).toList();
    final pageData = _pageData(sections, _sectionsPage);
    return _tableCard(
      onSearchChanged: (value) => setState(() {
        _sectionSearchQuery = value;
        _sectionsPage = 1;
      }),
      trailing: ElevatedButton.icon(
        onPressed: prov.isUserActionLoading
            ? null
            : () => _showAddSectionDialog(context),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add Section'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      header: _tableHeader([
        _ColumnSpec('Grade', 2),
        _ColumnSpec('Section', 3),
        _ColumnSpec('Action', 2),
      ]),
      rows: sections.isEmpty
          ? [_emptyRow('No sections found.')]
          : pageData.items.asMap().entries.map((entry) {
              final index = entry.key;
              final section = entry.value;
              return _tableRow(
                isEven: index.isEven,
                cells: [
                  _cell(section.gradeLevel, flex: 2),
                  _cell(section.name, flex: 3, isStrong: true),
                  _actionCell(
                    flex: 2,
                    onDelete: prov.isUserActionLoading
                        ? null
                        : () => _confirmDelete(
                            context,
                            title: 'Delete Section',
                            message:
                                'Delete ${section.label}? Students in this section may lose their section assignment.',
                            action: () => context
                                .read<AdminProvider>()
                                .deleteSection(section.id),
                          ),
                  ),
                ],
              );
            }).toList(),
      pagination: _pagination(
        page: pageData.page,
        totalPages: pageData.totalPages,
        totalCount: sections.length,
        onPageSelected: (p) => setState(() => _sectionsPage = p),
      ),
    );
  }

  Widget _buildBooksTable(BuildContext context, AdminProvider prov) {
    final query = _bookSearchQuery.trim().toLowerCase();
    final books = prov.books.where((book) {
      if (query.isEmpty) return true;
      return book.title.toLowerCase().contains(query) ||
          book.gradeSection.toLowerCase().contains(query);
    }).toList();
    final pageData = _pageData(books, _booksPage);
    return _tableCard(
      onSearchChanged: (value) => setState(() {
        _bookSearchQuery = value;
        _booksPage = 1;
      }),
      header: _tableHeader([
        _ColumnSpec('Book Title', 4),
        _ColumnSpec('Grade / Section', 3),
        _ColumnSpec('Action', 2),
      ]),
      rows: books.isEmpty
          ? [_emptyRow('No books found.')]
          : pageData.items.asMap().entries.map((entry) {
              final index = entry.key;
              final book = entry.value;
              return _tableRow(
                isEven: index.isEven,
                cells: [
                  _cell(book.title, flex: 4, isStrong: true),
                  _cell(
                    book.gradeSection.isEmpty
                        ? 'No section assigned'
                        : book.gradeSection,
                    flex: 3,
                  ),
                  _actionCell(
                    flex: 2,
                    onDelete: prov.isUserActionLoading
                        ? null
                        : () => _confirmDelete(
                            context,
                            title: 'Delete Book',
                            message:
                                'Delete ${book.title}? Related quiz questions will also be removed.',
                            action: () => context
                                .read<AdminProvider>()
                                .deleteBook(book.id),
                          ),
                  ),
                ],
              );
            }).toList(),
      pagination: _pagination(
        page: pageData.page,
        totalPages: pageData.totalPages,
        totalCount: books.length,
        onPageSelected: (p) => setState(() => _booksPage = p),
      ),
    );
  }

  Widget _buildReadingHistoryTable(BuildContext context, AdminProvider prov) {
    final query = _historySearchQuery.trim().toLowerCase();
    final histories = prov.readingHistories.where((history) {
      if (query.isEmpty) return true;
      return history.studentName.toLowerCase().contains(query) ||
          history.bookTitle.toLowerCase().contains(query) ||
          history.startedAt.toLowerCase().contains(query) ||
          history.submittedAt.toLowerCase().contains(query) ||
          history.status.toLowerCase().contains(query);
    }).toList();
    final pageData = _pageData(
      histories,
      _historiesPage,
      pageSize: _historyPageSize,
    );
    return _tableCard(
      minTableWidth: 960.0,
      onSearchChanged: (value) => setState(() {
        _historySearchQuery = value;
        _historiesPage = 1;
      }),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AdminTheme.border),
            ),
            child: Text(
              '${histories.length} total records',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AdminTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _historyPageSize,
                isDense: true,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                items: const [
                  DropdownMenuItem(value: 8, child: Text('8 per page')),
                  DropdownMenuItem(value: 25, child: Text('25 per page')),
                  DropdownMenuItem(value: 50, child: Text('50 per page')),
                  DropdownMenuItem(value: 100, child: Text('100 per page')),
                  DropdownMenuItem(value: 0, child: Text('Show all')),
                ],
                onChanged: (newSize) {
                  if (newSize != null) {
                    setState(() {
                      _historyPageSize = newSize;
                      _historiesPage = 1;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
      header: _tableHeader([
        _ColumnSpec('Student', 3),
        _ColumnSpec('Book', 3),
        _ColumnSpec('Date Read / Deployed', 3),
        _ColumnSpec('Submitted', 3),
        _ColumnSpec('Status', 2),
        _ColumnSpec('Action', 2),
      ]),
      rows: histories.isEmpty
          ? [_emptyRow('No reading histories found.')]
          : pageData.items.asMap().entries.map((entry) {
              final index = entry.key;
              final history = entry.value;
              return _tableRow(
                isEven: index.isEven,
                cells: [
                  _cell(history.studentName, flex: 3, isStrong: true),
                  _cell(history.bookTitle, flex: 3),
                  _cell(history.startedAt, flex: 3),
                  _cell(history.submittedAt, flex: 3),
                  _statusCell(history.status, flex: 2),
                  _actionCell(
                    flex: 2,
                    onDelete: prov.isUserActionLoading
                        ? null
                        : () => _confirmDelete(
                            context,
                            title: 'Delete Reading History',
                            message:
                                'Delete this reading history for ${history.studentName}?',
                            action: () => context
                                .read<AdminProvider>()
                                .deleteReadingHistory(history.id),
                          ),
                  ),
                ],
              );
            }).toList(),
      pagination: _pagination(
        page: pageData.page,
        totalPages: pageData.totalPages,
        totalCount: histories.length,
        onPageSelected: (p) => setState(() => _historiesPage = p),
      ),
    );
  }

  Widget _tableCard({
    required ValueChanged<String> onSearchChanged,
    required Widget header,
    required List<Widget> rows,
    Widget? trailing,
    Widget? pagination,
    double? minTableWidth,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = minTableWidth ?? 760.0;
        final tableWidth = constraints.maxWidth < minWidth
            ? minWidth
            : constraints.maxWidth;
        final maxSearchWidth = trailing == null ? 420.0 : 360.0;
        final searchWidth = constraints.maxWidth < maxSearchWidth + 40
            ? (constraints.maxWidth - 40)
                  .clamp(220.0, maxSearchWidth)
                  .toDouble()
            : maxSearchWidth;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: searchWidth,
                    child: _searchField(onChanged: onSearchChanged),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(children: [header, ...rows]),
                ),
              ),
              if (pagination != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                pagination,
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _searchField({required ValueChanged<String> onChanged}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12, width: 1.2),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: Colors.black, fontSize: 14),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.black54),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  _PageData<T> _pageData<T>(
    List<T> source,
    int requestedPage, {
    int? pageSize,
  }) {
    final effectivePageSize = pageSize ?? _pageSize;
    if (effectivePageSize <= 0) {
      return _PageData(
        page: 1,
        totalPages: 1,
        items: source,
      );
    }
    final totalPages = source.isEmpty ? 1 : (source.length / effectivePageSize).ceil();
    final page = requestedPage.clamp(1, totalPages);
    final start = (page - 1) * effectivePageSize;
    final end = (start + effectivePageSize) > source.length
        ? source.length
        : start + effectivePageSize;
    return _PageData(
      page: page,
      totalPages: totalPages,
      items: source.isEmpty ? const [] : source.sublist(start, end),
    );
  }

  Widget _pagination({
    required int page,
    required int totalPages,
    required ValueChanged<int> onPageSelected,
    int? totalCount,
  }) {
    final safeTotalPages = totalPages < 1 ? 1 : totalPages;
    final safePage = page.clamp(1, safeTotalPages);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'First page',
              onPressed: safePage > 1 ? () => onPageSelected(1) : null,
              icon: const Icon(Icons.first_page, size: 20),
              splashRadius: 18,
            ),
            TextButton.icon(
              onPressed: safePage > 1 ? () => onPageSelected(safePage - 1) : null,
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('Previous'),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Page ',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: safePage,
                  isDense: true,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.primary,
                  ),
                  items: List.generate(safeTotalPages, (i) => i + 1).map((p) {
                    return DropdownMenuItem<int>(
                      value: p,
                      child: Text('$p'),
                    );
                  }).toList(),
                  onChanged: (newP) {
                    if (newP != null && newP != safePage) {
                      onPageSelected(newP);
                    }
                  },
                ),
              ),
            ),
            Text(
              ' of $safeTotalPages${totalCount != null ? ' ($totalCount total)' : ''}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: safePage < safeTotalPages
                  ? () => onPageSelected(safePage + 1)
                  : null,
              label: const Text('Next'),
              icon: const Icon(Icons.chevron_right, size: 18),
            ),
            IconButton(
              tooltip: 'Last page',
              onPressed: safePage < safeTotalPages
                  ? () => onPageSelected(safeTotalPages)
                  : null,
              icon: const Icon(Icons.last_page, size: 20),
              splashRadius: 18,
            ),
          ],
        ),
      ],
    );
  }

  Widget _tableHeader(List<_ColumnSpec> columns) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: columns.map((column) {
          return Expanded(
            flex: column.flex,
            child: Text(
              column.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _tableRow({required bool isEven, required List<Widget> cells}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isEven
            ? Colors.grey.shade50.withValues(alpha: 0.5)
            : Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(children: cells),
    );
  }

  Widget _cell(String text, {required int flex, bool isStrong = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: isStrong ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _statusCell(String status, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionCell({required int flex, required VoidCallback? onDelete}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Delete'),
          style: TextButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red.shade700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyRow(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: Colors.black38,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  void _showAddSectionDialog(BuildContext context) {
    final gradeC = TextEditingController();
    final sectionC = TextEditingController();
    String? formError;

    bool isDirty() {
      return gradeC.text.trim().isNotEmpty || sectionC.text.trim().isNotEmpty;
    }

    Future<void> closeDialog(BuildContext context) async {
      if (isDirty()) {
        final shouldClose = await showAppConfirmDialog(
          context,
          title: 'Discard Section Draft?',
          message: 'The grade and section values you entered will be lost.',
          confirmLabel: 'Discard',
          isDanger: true,
        );
        if (!shouldClose || !context.mounted) return;
      }
      Navigator.of(context).pop();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PopScope<Object?>(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (!didPop) await closeDialog(context);
              },
              child: AppDialogFrame(
                title: 'Add Section',
                actions: [
                  TextButton(
                    onPressed: () => closeDialog(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      if (gradeC.text.trim().isEmpty ||
                          sectionC.text.trim().isEmpty) {
                        setDialogState(() {
                          formError = 'Grade and section name are required.';
                        });
                        return;
                      }
                      final error = await runWithLoadingDialog(
                        context,
                        () => context.read<AdminProvider>().addSection(
                          gradeC.text,
                          sectionC.text,
                        ),
                        message: 'Adding section...',
                      );
                      if (error != null) {
                        setDialogState(() => formError = error);
                        return;
                      }
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Section added.')),
                      );
                    },
                    child: const Text('Add'),
                  ),
                ],
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: gradeC,
                        decoration: const InputDecoration(
                          labelText: 'Grade',
                          hintText: 'Grade level',
                        ),
                      ),
                      TextField(
                        controller: sectionC,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          hintText: 'Section name',
                        ),
                      ),
                      if (formError != null) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formError!,
                            style: GoogleFonts.inter(
                              color: AdminTheme.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      gradeC.dispose();
      sectionC.dispose();
    });
  }

  void _confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
    required Future<String?> Function() action,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AppDialogFrame(
          title: title,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final shouldDelete = await showTypedConfirmDialog(
                  context,
                  title: 'Delete Permanently?',
                  message:
                      'This action cannot be undone. Type DELETE to continue.',
                  confirmationText: 'DELETE',
                );
                if (!shouldDelete || !context.mounted) return;
                final error = await runWithLoadingDialog(
                  context,
                  action,
                  message: 'Deleting...',
                );
                if (error != null) {
                  if (!context.mounted) return;
                  await showAppMessageDialog(
                    context,
                    title: 'Delete Failed',
                    message: error,
                    isDanger: true,
                  );
                  return;
                }
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Deleted successfully.')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
          child: Text(
            message,
            style: GoogleFonts.inter(color: AdminTheme.mutedText, height: 1.45),
          ),
        );
      },
    );
  }
}

class _ColumnSpec {
  final String label;
  final int flex;

  const _ColumnSpec(this.label, this.flex);
}

class _PageData<T> {
  final int page;
  final int totalPages;
  final List<T> items;

  const _PageData({
    required this.page,
    required this.totalPages,
    required this.items,
  });
}
