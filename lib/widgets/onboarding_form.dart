import 'package:flutter/material.dart';
import '../app.dart';
import 'onboarder_app_bar.dart';

class OnboardingStep {
  const OnboardingStep(
      {required this.label,
      required this.title,
      required this.description,
      required this.builder,
      this.validate,
      this.ready = true,
      this.validationMessage = 'Check the highlighted details to continue.'});
  final String label, title, description, validationMessage;
  final WidgetBuilder builder;
  final bool Function()? validate;
  final bool ready;
}

/// Keeps every step mounted so going back never discards fields or uploads.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow(
      {super.key,
      required this.title,
      required this.icon,
      required this.steps,
      required this.submitLabel,
      required this.onSubmit,
      this.busy = false,
      this.error});
  final String title, submitLabel;
  final IconData icon;
  final List<OnboardingStep> steps;
  final VoidCallback onSubmit;
  final bool busy;
  final String? error;
  @override
  State<OnboardingFlow> createState() => OnboardingFlowState();
}

class OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0, _furthest = 0;
  late final _forms =
      List.generate(widget.steps.length, (_) => GlobalKey<FormState>());
  late final _scrolls =
      List.generate(widget.steps.length, (_) => ScrollController());
  final Set<int> _attempted = {};
  String? _validationError;

  bool _valid(int index) {
    _attempted.add(index);
    final fields = _forms[index].currentState?.validate() ?? false;
    final extra = widget.steps[index].validate?.call() ?? true;
    return fields && extra;
  }

  void goToStep(int index) {
    if (widget.busy || index < 0 || index >= widget.steps.length) return;
    FocusScope.of(context).unfocus();
    if (index > _step && !_valid(_step)) {
      setState(() => _validationError = widget.steps[_step].validationMessage);
      _scrolls[_step].animateTo(0,
          duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      return;
    }
    setState(() {
      _validationError = null;
      _step = index;
      if (index > _furthest) _furthest = index;
    });
  }

  void _continue() {
    if (_step < widget.steps.length - 1) {
      goToStep(_step + 1);
      return;
    }
    for (var i = 0; i < widget.steps.length; i++) {
      if (!_valid(i)) {
        setState(() {
          _step = i;
          _validationError = widget.steps[i].validationMessage;
        });
        _scrolls[i].jumpTo(0);
        return;
      }
    }
    FocusScope.of(context).unfocus();
    widget.onSubmit();
  }

  @override
  void didUpdateWidget(covariant OnboardingFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error != null && widget.error != oldWidget.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrolls[_step].hasClients) {
          _scrolls[_step].animateTo(0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final scroll in _scrolls) {
      scroll.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.steps[_step];
    final finalStep = _step == widget.steps.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: OnboarderAppBar(title: widget.title),
      body: SafeArea(
          bottom: false,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border:
                      Border(bottom: BorderSide(color: Colors.grey.shade200))),
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: OnboarderApp.brandTealLight,
                                      borderRadius: BorderRadius.circular(14)),
                                  child: Icon(widget.icon,
                                      color: OnboarderApp.brandTealDark,
                                      size: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(
                                        'STEP ${_step + 1} OF ${widget.steps.length}',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.3,
                                            color: OnboarderApp.brandTealDark)),
                                    const SizedBox(height: 3),
                                    Text(current.title,
                                        style: const TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w800,
                                            color: OnboarderApp.ink,
                                            letterSpacing: -.5)),
                                  ])),
                            ]),
                            const SizedBox(height: 16),
                            Row(
                                children: List.generate(
                                    widget.steps.length,
                                    (index) => Expanded(
                                            child: Padding(
                                          padding: EdgeInsets.only(
                                              right: index ==
                                                      widget.steps.length - 1
                                                  ? 0
                                                  : 8),
                                          child: Semantics(
                                              selected: index == _step,
                                              child: InkWell(
                                                onTap: !widget.busy &&
                                                        index <= _furthest
                                                    ? () => goToStep(index)
                                                    : null,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 6),
                                                    child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          AnimatedContainer(
                                                              duration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          180),
                                                              height: 4,
                                                              decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              4),
                                                                  color: index <= _step
                                                                      ? OnboarderApp
                                                                          .brandTeal
                                                                      : const Color(
                                                                          0xFFE7ECEF))),
                                                          const SizedBox(
                                                              height: 7),
                                                          Text(
                                                              widget
                                                                  .steps[index]
                                                                  .label,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                  fontSize: 11,
                                                                  fontWeight: index ==
                                                                          _step
                                                                      ? FontWeight
                                                                          .w800
                                                                      : FontWeight
                                                                          .w500,
                                                                  color: index ==
                                                                          _step
                                                                      ? OnboarderApp
                                                                          .brandTealDark
                                                                      : const Color(
                                                                          0xFF7B8794))),
                                                        ])),
                                              )),
                                        )))),
                          ]))),
            ),
            Expanded(
                child: AbsorbPointer(
                    absorbing: widget.busy,
                    child: IndexedStack(
                      index: _step,
                      children: List.generate(
                          widget.steps.length,
                          (index) => SingleChildScrollView(
                                key: PageStorageKey('onboarding-step-$index'),
                                controller: _scrolls[index],
                                padding: const EdgeInsets.all(20),
                                child: Center(
                                    child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 640),
                                  child: Form(
                                      key: _forms[index],
                                      autovalidateMode: _attempted
                                              .contains(index)
                                          ? AutovalidateMode.onUserInteraction
                                          : AutovalidateMode.disabled,
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            if (widget.error != null ||
                                                _validationError != null) ...[
                                              OnboardingNotice(
                                                  text: widget.error ??
                                                      _validationError!,
                                                  error: true),
                                              const SizedBox(height: 16),
                                            ],
                                            Text(
                                                widget.steps[index].description,
                                                style: const TextStyle(
                                                    color: Color(0xFF64748B),
                                                    fontSize: 13,
                                                    height: 1.5)),
                                            const SizedBox(height: 16),
                                            widget.steps[index]
                                                .builder(context),
                                            const SizedBox(height: 12),
                                            if (index !=
                                                widget.steps.length - 1)
                                              const Text('* Required fields',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Color(0xFF7B8794))),
                                          ])),
                                )),
                              )),
                    ))),
          ])),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: SafeArea(
              top: false,
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Row(children: [
                      if (_step > 0) ...[
                        OutlinedButton(
                            onPressed:
                                widget.busy ? null : () => goToStep(_step - 1),
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(72, 50)),
                            child: const Text('Back')),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                          child: ElevatedButton.icon(
                              onPressed: widget.busy || !current.ready
                                  ? null
                                  : _continue,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: OnboarderApp.brandTealDark,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 50),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14))),
                              icon: widget.busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Icon(
                                      finalStep
                                          ? Icons.check_circle_outline
                                          : Icons.arrow_forward_rounded,
                                      size: 19),
                              label: Text(widget.busy
                                  ? 'Creating account…'
                                  : finalStep
                                      ? widget.submitLabel
                                      : 'Continue'))),
                    ])),
              )),
        ),
      ),
    );
  }
}

class OnboardingCard extends StatelessWidget {
  const OnboardingCard(
      {super.key,
      required this.title,
      required this.children,
      this.subtitle,
      this.onEdit});
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4EAED))),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        color: OnboarderApp.ink,
                        fontWeight: FontWeight.w800))),
            if (onEdit != null)
              TextButton(onPressed: onEdit, child: const Text('Edit'))
          ]),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF64748B), height: 1.45))
          ],
          const SizedBox(height: 18),
          ...children,
        ]),
      );
}

class OnboardingNotice extends StatelessWidget {
  const OnboardingNotice({super.key, required this.text, this.error = false});
  final String text;
  final bool error;
  @override
  Widget build(BuildContext context) => Semantics(
      liveRegion: error,
      child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: error ? const Color(0xFFFFF1F2) : const Color(0xFFEAF6F2),
              borderRadius: BorderRadius.circular(14)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(error ? Icons.error_outline : Icons.info_outline_rounded,
                size: 19,
                color: error
                    ? const Color(0xFFBE123C)
                    : OnboarderApp.brandTealDark),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: error
                            ? const Color(0xFF9F1239)
                            : const Color(0xFF24584B)))),
          ])));
}

class OnboardingField extends StatefulWidget {
  const OnboardingField(
      {super.key,
      required this.controller,
      required this.label,
      this.hint,
      this.helper,
      this.required = true,
      this.password = false,
      this.keyboardType,
      this.icon,
      this.maxLines = 1,
      this.readOnly = false,
      this.onTap,
      this.validator});
  final TextEditingController controller;
  final String label;
  final String? hint, helper;
  final bool required, password, readOnly;
  final int maxLines;
  final TextInputType? keyboardType;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  @override
  State<OnboardingField> createState() => _OnboardingFieldState();
}

class _OnboardingFieldState extends State<OnboardingField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: widget.controller,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        obscureText: widget.password && _obscure,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        textInputAction: widget.maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        autocorrect: !widget.password &&
            widget.keyboardType != TextInputType.emailAddress,
        enableSuggestions: !widget.password,
        validator: (value) {
          final text = value?.trim() ?? '';
          if (widget.required && text.isEmpty) {
            return 'Enter ${widget.label.toLowerCase()}.';
          }
          if (widget.password && text.length < 8) {
            return 'Use at least 8 characters.';
          }
          if (text.isNotEmpty &&
              widget.keyboardType == TextInputType.emailAddress &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
            return 'Enter a valid email address.';
          }
          if (text.isNotEmpty &&
              widget.keyboardType == TextInputType.phone &&
              !RegExp(r'^(?:0\d{10}|234\d{10}|\+\d{10,15})$')
                  .hasMatch(text.replaceAll(RegExp(r'[\s()-]'), ''))) {
            return 'Enter a valid phone number, e.g. 0803 123 4567.';
          }
          return widget.validator?.call(value);
        },
        decoration: InputDecoration(
            labelText:
                '${widget.label}${widget.required ? ' *' : ' (optional)'}',
            hintText: widget.hint,
            helperText: widget.helper,
            helperMaxLines: 3,
            alignLabelWithHint: widget.maxLines > 1,
            prefixIcon: widget.icon == null ? null : Icon(widget.icon),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDFE6EA))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDFE6EA))),
            suffixIcon: widget.password
                ? IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined))
                : null),
      ));
}

Widget onboardingSummary(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF7B8794))),
      const SizedBox(height: 4),
      Text(value.trim().isEmpty ? 'Not provided' : value,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: OnboarderApp.ink))
    ]));
