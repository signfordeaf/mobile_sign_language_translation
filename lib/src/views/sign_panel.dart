import 'package:flutter/material.dart';
import 'package:mobile_sign_language_translation/src/service/marquee_text.dart';
import 'package:video_player/video_player.dart';

class SignPanel extends StatefulWidget {
  final VideoPlayerController controller;
  final String? businessName;
  final String? text;
  final VoidCallback onClose;
  final Color primaryColor;
  final Color textColor;
  final String logoAsset;
  final String? videoPlayerLabel;
  final String? closeButtonLabel;
  final String? bottomSheetHint;
  const SignPanel({
    super.key,
    this.businessName,
    this.text,
    required this.controller,
    required this.onClose,
    this.primaryColor = const Color(0xFF6750A4),
    this.textColor = const Color(0xFF6750A4),
    this.logoAsset = 'images/logo_kafa.png',
    this.videoPlayerLabel,
    this.closeButtonLabel,
    this.bottomSheetHint,
  });

  @override
  State<SignPanel> createState() => _SignPanelState();
}

class _SignPanelState extends State<SignPanel> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Bottom safe area (home indicator, etc.): since the panel sits at the very
    // bottom of the screen, we push the content up by this much so it is not clipped.
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    return Semantics(
      container: true,
      hint: widget.bottomSheetHint,
      child: ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        color: const Color.fromARGB(255, 255, 255, 255),
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, 18, 8, 8 + bottomSafe),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Image.asset(
                      widget.logoAsset,
                      scale: 4,
                      package: 'mobile_sign_language_translation',
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      text: widget.businessName != null ? widget.businessName! : 'SignForDeaf',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: widget.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: widget.closeButtonLabel,
                    child: GestureDetector(
                      onTap: () {
                        widget.controller.pause();
                        widget.onClose();
                      },
                      child: SizedBox(
                        width: 50,
                        child: Icon(
                          Icons.close,
                          color: widget.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: widget.controller.value.isInitialized
                    ? Semantics(
                        label: widget.videoPlayerLabel,
                        child: AspectRatio(
                          aspectRatio: widget.controller.value.aspectRatio,
                          child: VideoPlayer(widget.controller),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              _buildTextWidget(context),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Container _buildTextWidget(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 30,
      alignment: Alignment.center,
      child: MarqueeText(
        text: widget.text ?? '',
        style: TextStyle(
          fontSize: 15.0,
          color: widget.textColor,
          fontWeight: FontWeight.bold,
        ),
        scrollSpeed: 55,
      ),
    );
  }

  // Note: `controller` (VideoPlayerController) is owned by SignForDeafController
  // and disposed there; it is not disposed again here.
}
