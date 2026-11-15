import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class OnboardingImageUpload extends StatefulWidget {
  const OnboardingImageUpload(
      {super.key,
      required this.label,
      required this.value,
      required this.onChanged,
      required this.onBusyChanged,
      this.banner = false});
  final String label, value;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onBusyChanged;
  final bool banner;
  @override
  State<OnboardingImageUpload> createState() => _OnboardingImageUploadState();
}

class _OnboardingImageUploadState extends State<OnboardingImageUpload> {
  bool _busy = false;
  String? _error;
  Future<void> _pick() async {
    final token = OnboarderSession.instance.accessToken;
    if (token == null) {
      setState(() => _error = 'Sign in to upload an image.');
      return;
    }
    var started = false;
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
          withData: true);
      if (!mounted || result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (file.bytes == null || file.size > 5 * 1024 * 1024) {
        setState(() => _error = 'Choose an image smaller than 5 MB.');
        return;
      }
      setState(() {
        _busy = true;
        _error = null;
      });
      widget.onBusyChanged(true);
      started = true;
      final url = await OnboarderSession.instance.api
          .uploadDocumentBytes(file.bytes!, file.name, token);
      if (mounted) widget.onChanged(url);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException
            ? e.message
            : 'Could not upload image. Please try again.');
      }
    } finally {
      if (mounted && started) {
        setState(() => _busy = false);
        widget.onBusyChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: Text('${widget.label} (optional)',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700))),
          if (widget.value.isNotEmpty)
            TextButton(
                onPressed: _busy ? null : () => widget.onChanged(''),
                child: const Text('Remove'))
        ]),
        const SizedBox(height: 8),
        OutlinedButton(
            onPressed: _busy ? null : _pick,
            style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.center,
                side: const BorderSide(color: Color(0xFFDBE4E9)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: SizedBox(
                height: widget.banner ? 120 : 100,
                width: double.infinity,
                child: _busy
                    ? const Center(child: CircularProgressIndicator())
                    : widget.value.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.network(widget.value,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                    child: Text(
                                        'Image uploaded • Tap to replace'))))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                const Icon(Icons.add_photo_alternate_outlined,
                                    size: 27),
                                const SizedBox(height: 6),
                                Text('Upload ${widget.label.toLowerCase()}'),
                                const SizedBox(height: 4),
                                const Text('JPG, PNG, WEBP or GIF • Up to 5 MB',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF7B8794))),
                              ]))),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_error!,
                  style:
                      const TextStyle(color: Color(0xFFBE123C), fontSize: 12))),
      ]));
}
