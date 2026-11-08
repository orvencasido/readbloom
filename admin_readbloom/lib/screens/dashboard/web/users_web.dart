import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/admin_models.dart';
import '../../../providers/admin_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/loading_dialog.dart';

class UsersWebBody extends StatefulWidget {
  const UsersWebBody({super.key});

  @override
  State<UsersWebBody> createState() => _UsersWebBodyState();
}

class _UsersWebBodyState extends State<UsersWebBody> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'All Roles';
  int _currentPage = 1;
  final int _itemsPerPage = 8;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSectionDropdownField({
    required String value,
    required List<AdminSection> sections,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
          items: sections.isEmpty
              ? const [
                  DropdownMenuItem<String>(
                    value: '',
                    child: Text('No sections available'),
                  ),
                ]
              : sections.map((section) {
                  return DropdownMenuItem<String>(
                    value: section.id,
                    child: Text(section.label),
                  );
                }).toList(),
          onChanged: sections.isEmpty ? null : onChanged,
        ),
      ),
    );
  }

  void _showCreateAccountDialog(BuildContext context) {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();

    bool isDirty(Set<String> teacherSectionIds) {
      return nameC.text.trim().isNotEmpty ||
          emailC.text.trim().isNotEmpty ||
          passC.text.isNotEmpty ||
          teacherSectionIds.isNotEmpty;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String selectedRole = 'Student';
        String selectedSectionId =
            context.read<AdminProvider>().sections.isEmpty
            ? ''
            : context.read<AdminProvider>().sections.first.id;
        final selectedTeacherSectionIds = <String>{};
        String? formError;

        Future<void> closeDialog(BuildContext context) async {
          if (isDirty(selectedTeacherSectionIds)) {
            final shouldClose = await showAppConfirmDialog(
              context,
              title: 'Discard Account Draft?',
              message:
                  'The account details you entered will be lost if you close this form.',
              confirmLabel: 'Discard',
              isDanger: true,
            );
            if (!shouldClose || !context.mounted) return;
          }
          Navigator.of(context).pop();
        }

        return StatefulBuilder(
          builder: (context, setState) {
            final prov = context.watch<AdminProvider>();
            final sections = prov.sections;
            if (selectedSectionId.isEmpty && sections.isNotEmpty) {
              selectedSectionId = sections.first.id;
            }
            AdminSection? selectedSection;
            for (final section in sections) {
              if (section.id == selectedSectionId) {
                selectedSection = section;
                break;
              }
            }
            return PopScope<Object?>(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (!didPop) await closeDialog(context);
              },
              child: AppDialogFrame(
                maxWidth: 480,
                child: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Register a new teacher or student account.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildInputLabel('Full Name'),
                        _buildDialogField(nameC, 'Full name'),
                        const SizedBox(height: 14),

                        _buildInputLabel('Email Address'),
                        _buildDialogField(emailC, 'Email address'),
                        const SizedBox(height: 14),

                        _buildInputLabel('Password'),
                        _buildDialogField(
                          passC,
                          'Enter password',
                          obscure: true,
                        ),
                        const SizedBox(height: 14),

                        _buildInputLabel('Role'),
                        _buildDropdownField(
                          value: selectedRole,
                          items: const ['Student', 'Teacher'],
                          onChanged: (val) async {
                            if (val != null) {
                              if (selectedRole == 'Teacher' &&
                                  val != 'Teacher' &&
                                  selectedTeacherSectionIds.isNotEmpty) {
                                final shouldSwitch = await showAppConfirmDialog(
                                  context,
                                  title: 'Change Role?',
                                  message:
                                      'Assigned teacher sections will be cleared if you switch roles.',
                                  confirmLabel: 'Change Role',
                                  isDanger: true,
                                );
                                if (!shouldSwitch || !context.mounted) return;
                                selectedTeacherSectionIds.clear();
                              }
                              setState(() {
                                selectedRole = val;
                                formError = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        if (selectedRole == 'Student') ...[
                          _buildInputLabel('Grade and Section'),
                          _buildSectionDropdownField(
                            value: selectedSectionId,
                            sections: sections,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => selectedSectionId = val);
                              }
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            selectedSection == null
                                ? 'Create sections in Supabase before creating accounts.'
                                : selectedSection.label,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else if (selectedRole == 'Teacher') ...[
                          _buildInputLabel('Assigned Sections'),
                          _buildTeacherSectionPicker(
                            sections: sections,
                            selectedIds: selectedTeacherSectionIds,
                            onChanged: (sectionId, selected) {
                              setState(() {
                                if (selected) {
                                  selectedTeacherSectionIds.add(sectionId);
                                } else {
                                  selectedTeacherSectionIds.remove(sectionId);
                                }
                              });
                            },
                          ),
                        ],

                        if (formError != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            formError!,
                            style: GoogleFonts.inter(
                              color: AdminTheme.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => closeDialog(context),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.outfit(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: prov.isUserActionLoading
                                  ? null
                                  : () async {
                                      final navigator = Navigator.of(context);
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      if (nameC.text.trim().isEmpty ||
                                          emailC.text.trim().isEmpty ||
                                          passC.text.isEmpty) {
                                        setState(() {
                                          formError =
                                              'Full name, email, and password are required.';
                                        });
                                        return;
                                      }
                                      if (selectedRole == 'Student' &&
                                          selectedSectionId.trim().isEmpty) {
                                        setState(() {
                                          formError =
                                              'Student accounts require a section.';
                                        });
                                        return;
                                      }
                                      if (selectedRole == 'Teacher' &&
                                          selectedTeacherSectionIds.isEmpty) {
                                        setState(() {
                                          formError =
                                              'Teacher accounts require at least one assigned section.';
                                        });
                                        return;
                                      }
                                      final error = await runWithLoadingDialog(
                                        context,
                                        () => context
                                            .read<AdminProvider>()
                                            .createUser(
                                              nameC.text,
                                              emailC.text,
                                              passC.text,
                                              selectedRole,
                                              selectedSectionId,
                                              gradeLevel:
                                                  selectedSection?.gradeLevel,
                                              teacherSectionIds:
                                                  selectedRole == 'Teacher'
                                                  ? selectedTeacherSectionIds
                                                        .toList()
                                                  : const [],
                                            ),
                                        message: 'Creating account...',
                                      );
                                      if (error != null) {
                                        setState(() => formError = error);
                                        return;
                                      }
                                      navigator.pop();
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Account successfully created for ${nameC.text}!',
                                          ),
                                          backgroundColor: const Color(
                                            0xFF10B981,
                                          ),
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                              ),
                              child: prov.isUserActionLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Create Account',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
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
            );
          },
        );
      },
    ).whenComplete(() {
      nameC.dispose();
      emailC.dispose();
      passC.dispose();
    });
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherSectionPicker({
    required List<AdminSection> sections,
    required Set<String> selectedIds,
    required void Function(String sectionId, bool selected) onChanged,
  }) {
    if (sections.isEmpty) {
      return Text(
        'Create sections in Supabase before creating accounts.',
        style: GoogleFonts.outfit(
          fontSize: 11,
          color: Colors.black54,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: sections.map((section) {
            return CheckboxListTile(
              value: selectedIds.contains(section.id),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                section.label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onChanged: (value) => onChanged(section.id, value ?? false),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, AdminUser user) {
    showDialog(
      context: context,
      builder: (context) {
        return AppDialogFrame(
          title: 'Delete Account',
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
                  title: 'Permanently Delete?',
                  message:
                      'This cannot be undone. Delete ${user.name} and connected profile data? Type DELETE to continue.',
                  confirmationText: 'DELETE',
                );
                if (!shouldDelete || !context.mounted) return;
                final error = await runWithLoadingDialog(
                  context,
                  () => context.read<AdminProvider>().deleteAccount(user.id),
                  message: 'Deleting account...',
                );
                if (error != null) {
                  if (!context.mounted) return;
                  await showAppMessageDialog(
                    context,
                    title: 'Account Not Deleted',
                    message: error,
                    isDanger: true,
                  );
                  return;
                }
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Account deleted.')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
          child: Text(
            'Delete ${user.name}? This removes the Auth account and connected profile data.',
            style: GoogleFonts.inter(color: AdminTheme.mutedText, height: 1.45),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();
    final query = _searchQuery;

    final filteredUsers = prov.users.where((user) {
      final matchesSearch =
          user.name.toLowerCase().contains(query.toLowerCase()) ||
          user.role.toLowerCase().contains(query.toLowerCase()) ||
          user.email.toLowerCase().contains(query.toLowerCase());
      final matchesRole =
          _selectedRole == 'All Roles' || user.role == _selectedRole;
      return matchesSearch && matchesRole;
    }).toList();

    // Compute paginated items
    final totalItems = filteredUsers.length;
    final totalPages = (totalItems / _itemsPerPage).ceil() == 0
        ? 1
        : (totalItems / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < totalItems)
        ? startIndex + _itemsPerPage
        : totalItems;
    final paginatedItems = filteredUsers.sublist(
      startIndex,
      endIndex > totalItems ? totalItems : endIndex,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            children: [
              // Search & Add Header Controls Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: Row(
                  children: [
                    // Search bar
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12, width: 1.2),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                              _currentPage = 1; // Reset to page 1 on search
                            });
                          },
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search users by name, email, or role...',
                            hintStyle: TextStyle(color: Colors.black38),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.black54,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 150,
                      child: _buildDropdownField(
                        value: _selectedRole,
                        items: const [
                          'All Roles',
                          'Student',
                          'Teacher',
                          'Admin',
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedRole = val;
                              _currentPage = 1;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Create account button
                    ElevatedButton.icon(
                      onPressed: () => _showCreateAccountDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        'Create Account',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Users Table Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Manage Users Database',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Showing ${totalItems == 0 ? 0 : startIndex + 1}-$endIndex of $totalItems Users',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AdminTheme.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // User Management Table
                    Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildTableHeaderCell('Name'),
                              ),
                              Expanded(
                                flex: 4,
                                child: _buildTableHeaderCell('Email Address'),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildTableHeaderCell('Role'),
                              ),
                              Expanded(
                                flex: 3,
                                child: _buildTableHeaderCell('Section'),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildTableHeaderCell('Action'),
                              ),
                            ],
                          ),
                        ),
                        // Table Rows
                        filteredUsers.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(32),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'No user records found.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.black38,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: paginatedItems.length,
                                itemBuilder: (context, idx) {
                                  final user = paginatedItems[idx];
                                  final isLast =
                                      idx == paginatedItems.length - 1;
                                  final isEven = idx % 2 == 0;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isEven
                                          ? Colors.grey.shade50.withValues(
                                              alpha: 0.5,
                                            )
                                          : Colors.white,
                                      borderRadius: isLast
                                          ? const BorderRadius.vertical(
                                              bottom: Radius.circular(12),
                                            )
                                          : null,
                                      border: Border(
                                        left: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                        right: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            user.name,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                            user.email,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _roleBackground(
                                                  user.role,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                user.role,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: _roleColor(user.role),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            user.gradeSection?.isEmpty ?? true
                                                ? '-'
                                                : user.gradeSection!,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: ElevatedButton.icon(
                                              onPressed:
                                                  user.role == 'Admin' ||
                                                      prov.isUserActionLoading
                                                  ? null
                                                  : () => _confirmDeleteAccount(
                                                      context,
                                                      user,
                                                    ),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 15,
                                              ),
                                              label: const Text('Delete'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.redAccent,
                                                foregroundColor: Colors.white,
                                                disabledBackgroundColor:
                                                    Colors.grey.shade200,
                                                disabledForegroundColor:
                                                    Colors.grey.shade500,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pagination Control Row with Jump to Page
                    Wrap(
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
                              onPressed: _currentPage > 1
                                  ? () => setState(() => _currentPage = 1)
                                  : null,
                              icon: const Icon(Icons.first_page, size: 20),
                              splashRadius: 18,
                            ),
                            ElevatedButton.icon(
                              onPressed: _currentPage > 1
                                  ? () => setState(() => _currentPage--)
                                  : null,
                              icon: const Icon(Icons.chevron_left, size: 18),
                              label: const Text('Previous'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade100,
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _currentPage.clamp(1, totalPages),
                                  isDense: true,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AdminTheme.primary,
                                  ),
                                  items: List.generate(
                                    totalPages,
                                    (i) => i + 1,
                                  ).map((p) {
                                    return DropdownMenuItem<int>(
                                      value: p,
                                      child: Text('$p'),
                                    );
                                  }).toList(),
                                  onChanged: (newP) {
                                    if (newP != null && newP != _currentPage) {
                                      setState(() => _currentPage = newP);
                                    }
                                  },
                                ),
                              ),
                            ),
                            Text(
                              ' of $totalPages ($totalItems total)',
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
                            ElevatedButton.icon(
                              onPressed: _currentPage < totalPages
                                  ? () => setState(() => _currentPage++)
                                  : null,
                              icon: const Icon(Icons.chevron_right, size: 18),
                              label: const Text('Next'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade100,
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Last page',
                              onPressed: _currentPage < totalPages
                                  ? () => setState(() => _currentPage = totalPages)
                                  : null,
                              icon: const Icon(Icons.last_page, size: 20),
                              splashRadius: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Color _roleBackground(String role) {
    if (role == 'Admin') return Colors.purple.shade50;
    if (role == 'Teacher') return Colors.indigo.shade50;
    return Colors.blue.shade50;
  }

  Color _roleColor(String role) {
    if (role == 'Admin') return Colors.purple.shade700;
    if (role == 'Teacher') return Colors.indigo.shade700;
    return Colors.blue.shade700;
  }
}
