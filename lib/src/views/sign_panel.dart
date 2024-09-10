import 'package:flutter/material.dart';
import 'package:mobile_sign_language_translation/src/service/marquee_text.dart';
import 'package:video_player/video_player.dart';

class SignPanel extends StatefulWidget {
  final VideoPlayerController controller;
  final String? businessName;
  final String? text;
  final VoidCallback onClose;
  const SignPanel({
    super.key,
    this.businessName,
    this.text,
    required this.controller,
    required this.onClose,
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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        color: const Color.fromARGB(255, 255, 255, 255),
        child: Padding(
          padding: const EdgeInsets.all(8.0) + const EdgeInsets.only(top: 10.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Image.asset(
                      'images/logo_kafa.png',
                      scale: 4,
                      package: 'signfordeaf',
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      text: widget.businessName != null
                          ? widget.businessName!
                          : 'SignForDeaf',
                      style: const TextStyle(
                        fontSize: 18.0,
                        color: Color.fromARGB(255, 103, 58, 183),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      widget.controller.pause();
                      widget.onClose();
                    },
                    child: const SizedBox(
                      width: 50,
                      child: Icon(
                        Icons.close,
                        color: Color.fromARGB(255, 103, 58, 183),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                child: widget.controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: widget.controller.value.aspectRatio,
                        child: VideoPlayer(widget.controller),
                      )
                    : const SizedBox.shrink(),
              ),
              _buildTextWidget(context),
            ],
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
        style: const TextStyle(
          fontSize: 15.0,
          color: Color.fromARGB(255, 103, 58, 183),
          fontWeight: FontWeight.bold,
        ),
        scrollSpeed: 25,
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }
}
