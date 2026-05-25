import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';

typedef SendTextCallback = Future<void> Function(String text);
typedef SendImageCallback = Future<void> Function(
  File imageFile,
  ValueChanged<double> onProgress,
);

class MessageInputController extends ChangeNotifier {
  final text = TextEditingController();
  bool isUploading = false;
  double uploadProgress = 0;

  bool get canSend => text.text.trim().isNotEmpty && !isUploading;

  void textChanged() {
    notifyListeners();
  }

  void clearText() {
    text.clear();
    notifyListeners();
  }

  void setUploading(bool value) {
    isUploading = value;
    if (!value) {
      uploadProgress = 0;
    }
    notifyListeners();
  }

  void setUploadProgress(double value) {
    uploadProgress = value.clamp(0, 1);
    notifyListeners();
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }
}

class MessageInput extends StatelessWidget {
  const MessageInput({
    super.key,
    required this.focusNode,
    required this.onSendText,
    required this.onSendImage,
    required this.onTypingChanged,
  });

  final FocusNode focusNode;
  final SendTextCallback onSendText;
  final SendImageCallback onSendImage;
  final ValueChanged<bool> onTypingChanged;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MessageInputController(),
      child: _MessageInputBody(
        focusNode: focusNode,
        onSendText: onSendText,
        onSendImage: onSendImage,
        onTypingChanged: onTypingChanged,
      ),
    );
  }
}

class _MessageInputBody extends StatefulWidget {
  const _MessageInputBody({
    required this.focusNode,
    required this.onSendText,
    required this.onSendImage,
    required this.onTypingChanged,
  });

  final FocusNode focusNode;
  final SendTextCallback onSendText;
  final SendImageCallback onSendImage;
  final ValueChanged<bool> onTypingChanged;

  @override
  State<_MessageInputBody> createState() => _MessageInputBodyState();
}

class _MessageInputBodyState extends State<_MessageInputBody> {
  final _picker = ImagePicker();
  Timer? _typingTimer;

  @override
  void dispose() {
    _typingTimer?.cancel();
    widget.onTypingChanged(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MessageInputController>();
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.isUploading) ...[
              LinearProgressIndicator(
                value: controller.uploadProgress == 0
                    ? null
                    : controller.uploadProgress,
                minHeight: 2,
                color: AppColors.primary,
                backgroundColor: AppColors.border,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                IconButton(
                  onPressed: controller.isUploading ? null : _pickImage,
                  icon: const Icon(Icons.photo_outlined),
                  color: AppColors.textSecondary,
                ),
                Expanded(
                  child: TextField(
                    controller: controller.text,
                    focusNode: widget.focusNode,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    onChanged: _handleTyping,
                    decoration: const InputDecoration(
                      hintText: 'Message',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: controller.canSend ? _sendText : null,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.chatOutgoing,
                    disabledBackgroundColor: AppColors.border,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendText() async {
    final controller = context.read<MessageInputController>();
    final text = controller.text.text.trim();
    if (text.isEmpty) {
      return;
    }
    controller.clearText();
    widget.onTypingChanged(false);
    try {
      await widget.onSendText(text);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message failed to send.')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) {
      return;
    }

    final controller = context.read<MessageInputController>();
    controller.setUploading(true);
    try {
      await widget.onSendImage(
        File(picked.path),
        controller.setUploadProgress,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image failed to send.')),
        );
      }
    } finally {
      if (mounted) {
        controller.setUploading(false);
      }
    }
  }

  void _handleTyping(String value) {
    final controller = context.read<MessageInputController>();
    controller.textChanged();

    final isTyping = value.trim().isNotEmpty;
    widget.onTypingChanged(isTyping);
    _typingTimer?.cancel();
    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        widget.onTypingChanged(false);
      });
    }
  }
}
