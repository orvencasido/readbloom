import 'package:flutter/material.dart';

class GuardedPopScope extends StatefulWidget {
  final Widget child;
  final Future<bool> Function() onConfirmPop;
  final Future<void> Function()? onConfirmedPop;

  const GuardedPopScope({
    super.key,
    required this.child,
    required this.onConfirmPop,
    this.onConfirmedPop,
  });

  @override
  State<GuardedPopScope> createState() => _GuardedPopScopeState();
}

class _GuardedPopScopeState extends State<GuardedPopScope> {
  bool _allowPop = false;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await widget.onConfirmPop();
        if (!shouldPop || !mounted) return;
        await widget.onConfirmedPop?.call();
        if (!mounted || !context.mounted) return;
        setState(() => _allowPop = true);
        Navigator.of(context).pop(result);
      },
      child: widget.child,
    );
  }
}
