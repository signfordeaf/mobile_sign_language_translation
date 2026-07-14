import 'package:flutter/material.dart';
import 'package:mobile_sign_language_translation/src/l10n/strings.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_controller.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_manager.dart';

/// Helper that adds a "Sign Language" item to the selection menu of text
/// widgets that are already natively selectable (`TextField`,
/// `SelectableText`…) while the SDK is **enabled**.
///
/// This package no longer forces any text to be selectable (the old always-on
/// `SelectionArea` behavior broke normal UX). Instead, you pass this builder to
/// the app's already-selectable areas. Since the builder is bound to the
/// controller, read the controller from the tree first:
///
/// ```dart
/// Builder(
///   builder: (context) {
///     final sfd = SignForDeaf.of(context); // under scope
///     return SelectableText(
///       'Merhaba dünya',
///       contextMenuBuilder: sfd.contextMenuBuilder,
///     );
///   },
/// )
/// ```
///
/// When the SDK is disabled (or the selection is empty) only the default menu
/// items are shown; no behavior changes.
///
/// Note: the builder captures the controller via a closure; because the
/// selection menu is drawn in the root overlay (outside the scope), a
/// `SignForDeafScope` lookup via `context` does not work here — hence it binds
/// to the controller directly.
extension SignForDeafContextMenu on SignForDeafController {
  Widget contextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final buttonItems = editableTextState.contextMenuButtonItems;
    final value = editableTextState.textEditingValue;
    final selected = value.selection.isValid
        ? value.selection.textInside(value.text)
        : '';

    if (isEnabled && selected.trim().isNotEmpty) {
      buttonItems.insert(
        0,
        ContextMenuButtonItem(
          label: SignForDeafStrings.of(SignForDeafManager().language).menuTitle,
          onPressed: () {
            editableTextState.hideToolbar();
            translate(selected);
          },
        ),
      );
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }
}
