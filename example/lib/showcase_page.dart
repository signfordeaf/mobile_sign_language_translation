import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_sign_language_translation/mobile_sign_language_translation.dart';

import 'widgets/section_card.dart';

class ShowcasePage extends StatefulWidget {
  final SignForDeafController controller;
  final bool apiConfigured;
  final SignLanguage language;
  final ValueChanged<SignLanguage> onLanguageChanged;
  final Color primaryColor;
  final ValueChanged<Color> onPrimaryColorChanged;

  const ShowcasePage({
    super.key,
    required this.controller,
    required this.apiConfigured,
    required this.language,
    required this.onLanguageChanged,
    required this.primaryColor,
    required this.onPrimaryColorChanged,
  });

  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage> {
  final List<SignForDeafEvent> _events = [];
  StreamSubscription<SignForDeafEvent>? _eventsSub;
  final TextEditingController _field =
      TextEditingController(text: 'Bir kelime seçip menüden çevir');

  SignForDeafController get _controller => widget.controller;

  static const List<Color> _swatches = [
    Color(0xFF6750A4), // purple
    Color(0xFF00639B), // blue
    Color(0xFF146C2E), // green
    Color(0xFFB3261E), // red
    Color(0xFF8C4A00), // orange
  ];

  @override
  void initState() {
    super.initState();
    _eventsSub = _controller.events.listen((event) {
      if (!mounted) return;
      setState(() {
        _events.insert(0, event);
        if (_events.length > 6) _events.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SignForDeaf'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _header(context),
          if (!widget.apiConfigured) _apiBanner(context),
          _modeSection(),
          _tapToTranslateSection(),
          _selectionMenuSection(),
          _programmaticSection(),
          _sensitiveSection(),
          _personalizationSection(),
          _eventsSection(),
        ],
      ),
    );
  }

  // ---- Header + live status ----------------------------------------------

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'images/logo_kafa.png',
                package: 'mobile_sign_language_translation',
                height: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sign Language Translation',
                        style: Theme.of(context).textTheme.titleLarge),
                    Text('Flutter SDK showcase',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusChip('Mode', _controller.isEnabled),
                _statusChip('Tap-to-translate', _controller.isTapToTranslateActive),
                _statusChip('Loading', _controller.isLoading),
                _statusChip('Panel', _controller.isPanelVisible),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, bool active) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        active ? Icons.check_circle : Icons.remove_circle_outline,
        size: 18,
        color: active ? scheme.primary : scheme.outline,
      ),
      label: Text(label),
      backgroundColor:
          active ? scheme.primaryContainer.withValues(alpha: 0.5) : null,
    );
  }

  Widget _apiBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: scheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Add your API key & URL in main.dart (kApiKey / kApiUrl) to play '
              'real sign-language videos. Every other feature works without it.',
              style: TextStyle(color: scheme.onTertiaryContainer, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ---- 1) Enable / disable -----------------------------------------------

  Widget _modeSection() {
    return SectionCard(
      icon: Icons.toggle_on,
      title: 'Sign Language mode',
      description:
          'Off by default → the app is 100% native. Turn it on to enable the '
          'floating tap-to-translate button and the selection-menu item.',
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_controller.isEnabled ? 'Enabled' : 'Disabled'),
          value: _controller.isEnabled,
          onChanged: (v) =>
              v ? _controller.enable() : _controller.disable(),
        ),
      ),
    );
  }

  // ---- 2) Tap-to-translate ------------------------------------------------

  Widget _tapToTranslateSection() {
    return SectionCard(
      icon: Icons.touch_app,
      title: 'Tap-to-translate',
      description:
          'When the mode is on, tapping any on-screen text translates it. '
          'Toggle it with the floating button, or the button below.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => FilledButton.tonalIcon(
              onPressed: _controller.isEnabled
                  ? _controller.toggleTapToTranslate
                  : null,
              icon: Icon(_controller.isTapToTranslateActive
                  ? Icons.pause
                  : Icons.play_arrow),
              label: Text(_controller.isTapToTranslateActive
                  ? 'Tap-to-translate: ON'
                  : 'Tap-to-translate: OFF'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Merhaba! Bugün hava çok güzel, dışarıda yürüyüşe çıkmak için '
            'harika bir gün.',
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text('Reliable fallback for custom widgets — SignForDeafText:',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          const SignForDeafText(
            'Teşekkür ederim',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ---- 3) Selection menu (opt-in) ----------------------------------------

  Widget _selectionMenuSection() {
    return SectionCard(
      icon: Icons.text_fields,
      title: 'Selection menu (opt-in)',
      description:
          'For text your app already makes selectable, pass '
          'controller.contextMenuBuilder. Select text → "İşaret Dili" appears '
          '(only while enabled). Works for SelectableText and TextField.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(
            'Bu cümleden bir kelime seçin ve menüde İşaret Dili seçeneğini görün.',
            contextMenuBuilder: _controller.contextMenuBuilder,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _field,
            contextMenuBuilder: _controller.contextMenuBuilder,
            decoration: const InputDecoration(
              labelText: 'Editable field',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  // ---- 4) Programmatic ----------------------------------------------------

  Widget _programmaticSection() {
    const phrases = ['Merhaba', 'Teşekkürler', 'Evet', 'Hayır', 'Görüşürüz'];
    return SectionCard(
      icon: Icons.smart_button,
      title: 'Programmatic translation',
      description: 'Call controller.translate(text) from anywhere.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final p in phrases)
            ActionChip(
              label: Text(p),
              onPressed: () => _controller.translate(p),
            ),
        ],
      ),
    );
  }

  // ---- 5) Sensitive data --------------------------------------------------

  Widget _sensitiveSection() {
    return SectionCard(
      icon: Icons.privacy_tip,
      title: 'Sensitive data protection',
      description:
          'Personal data is never sent to the server. Mark content with '
          'SignForDeafSensitive, and common PII (ID no, card, IBAN, e-mail, '
          'phone) is auto-detected and blocked.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SignForDeafSensitive(
            child: Text('Marked: T.C. Kimlik No: 10000000146'),
          ),
          const SizedBox(height: 6),
          const Text('Unmarked but auto-detected: card 4242 4242 4242 4242'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _controller.translate('4242 4242 4242 4242'),
            icon: const Icon(Icons.block),
            label: const Text('Try to translate the card number'),
          ),
        ],
      ),
    );
  }

  // ---- 6) Personalization -------------------------------------------------

  Widget _personalizationSection() {
    return SectionCard(
      icon: Icons.palette,
      title: 'Personalization',
      description:
          'Language and theme are applied live to the panel, floating button '
          'and menu.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Language'),
              const SizedBox(width: 16),
              DropdownButton<SignLanguage>(
                value: widget.language,
                onChanged: (l) {
                  if (l != null) widget.onLanguageChanged(l);
                },
                items: [
                  for (final lang in SignLanguage.values)
                    DropdownMenuItem(
                      value: lang,
                      child: Text(lang.localeCode.toUpperCase()),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Primary color'),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final color in _swatches)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => widget.onPrimaryColorChanged(color),
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: 16,
                      child: widget.primaryColor == color
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- 7) Events ----------------------------------------------------------

  Widget _eventsSection() {
    return SectionCard(
      icon: Icons.list_alt,
      title: 'Live events',
      description: 'The controller emits a lifecycle event stream.',
      child: _events.isEmpty
          ? Text('No events yet — try a translation.',
              style: Theme.of(context).textTheme.bodySmall)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in _events)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.chevron_right, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            e.text != null
                                ? '${e.type.name}  —  "${e.text}"'
                                : e.type.name,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
