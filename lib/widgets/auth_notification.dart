import 'package:flutter/material.dart';

class AuthNotification extends StatelessWidget {
  final String message;
  final bool isSuccess;
  final VoidCallback? onDismiss;

  const AuthNotification({
    Key? key,
    required this.message,
    this.isSuccess = true,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: isSuccess ? Colors.green.shade300 : Colors.red.shade300,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(
                Icons.close,
                color: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
                size: 20,
              ),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}

class AuthNotificationOverlay extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final Duration duration;

  const AuthNotificationOverlay({
    Key? key,
    required this.message,
    this.isSuccess = true,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<AuthNotificationOverlay> createState() =>
      _AuthNotificationOverlayState();
}

class _AuthNotificationOverlayState extends State<AuthNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: widget.isSuccess
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    border: Border.all(
                      color: widget.isSuccess
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isSuccess ? Icons.check_circle : Icons.error,
                        color: widget.isSuccess
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.message,
                        style: TextStyle(
                          color: widget.isSuccess
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _dismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isSuccess
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Helper function to show notification overlay
void showAuthNotification(
  BuildContext context, {
  required String message,
  bool isSuccess = true,
  Duration duration = const Duration(seconds: 3),
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AuthNotificationOverlay(
      message: message,
      isSuccess: isSuccess,
      duration: duration,
    ),
  );
}
