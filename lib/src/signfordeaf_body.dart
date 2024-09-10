import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_sign.dart';
import 'package:mobile_sign_language_translation/src/service/service.dart';
import 'package:mobile_sign_language_translation/src/signfordeaf_manager.dart';
import 'package:mobile_sign_language_translation/src/views/sign_panel.dart';
import 'package:video_player/video_player.dart';

class SignForDeafBody extends StatefulWidget {
  /// Creates a const instance of [SignForDeafBody].

  /// The [requestKey] must be entered for it to work.
  final String? requestKey;
  final String? requestUrl;
  final Widget? child;
  const SignForDeafBody(
      {super.key,
      this.requestKey,
      required this.requestUrl,
      required this.child});

  @override
  State<SignForDeafBody> createState() => _SignForDeafBodyState();
}

class _SignForDeafBodyState extends State<SignForDeafBody>
    with SingleTickerProviderStateMixin {
  Locale currentLocale = const Locale('tr');
  final SignForDeafManager _signForDeafManager = SignForDeafManager();
  late VideoPlayerController _videoController;
  SelectedContent? _selectedText;
  bool isSignReady = false;
  int videoPlayerErrorCount = 0;
  String signVideoUrl = '';

  ApiServices apiServices = ApiServices();
  late SignForDeafState _signForDeafState;
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    widget.requestKey != null ? _settingRequestKey() : null;
    widget.requestUrl != null ? _settingRequestUrl() : null;
    _signForDeafState = SignForDeafState.initial;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    currentLocale = Localizations.localeOf(context);
  }

  void _settingRequestKey() {
    _signForDeafManager.setRequestKey(widget.requestKey ?? '');
  }

  void _settingRequestUrl() {
    _signForDeafManager.setRequestUrl(widget.requestUrl ?? '');
  }

  void _initializeVideoPlayer(String signVideoUrl) {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(signVideoUrl.replaceFirst('http', 'https')),
      )..addListener(() {
          if (_videoController.value.hasError) {
            if (videoPlayerErrorCount <= 3) {
              videoPlayerErrorCount++;
              _initializeVideoPlayer(signVideoUrl);
            } else {
              videoPlayerErrorCount = 0;
              setState(() {
                _signForDeafState = SignForDeafState.error;
              });
            }
          }
        });
      _videoController.initialize().then((_) {
        setState(() {
          _signForDeafState = SignForDeafState.ready;
          _animationController.forward();
          _videoController.play();
          _videoController.setLooping(true);
        });
      });
    } catch (e) {
      setState(() {
        _signForDeafState = SignForDeafState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (SignForDeafManager().requestKey == null ||
        SignForDeafManager().requestUrl == null ||
        widget.child == null) {
      if (kDebugMode) {
        throw Exception('Please enter the request key or request url!');
      }
      if (kReleaseMode) return widget.child!;
    }
    if (_signForDeafManager.isSignForDeafOpen) {
      return init(context);
    } else {
      return widget.child!;
    }
  }

  AdaptiveTextSelectionToolbar _defaultContextMenuBuilder(
      BuildContext context, SelectableRegionState selectableRegionState) {
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: TextSelectionToolbarAnchors(
          primaryAnchor:
              selectableRegionState.contextMenuAnchors.primaryAnchor),
      buttonItems: [
        ContextMenuButtonItem(
          onPressed: () {
            selectableRegionState.hideToolbar();
            setState(() {
              _signForDeafState = SignForDeafState.loading;
            });
            ApiServices().getSignVideo(text: _selectedText!.plainText).then(
              (signModel) {
                if (signModel.state == null) {
                  setState(() {
                    _signForDeafState = SignForDeafState.error;
                  });
                } else if (signModel.cid == 'cancelled') {
                  setState(() {
                    _signForDeafState = SignForDeafState.cancelled;
                  });
                } else {
                  signVideoUrl = '${signModel.baseUrl}${signModel.name}';
                  _initializeVideoPlayer(signVideoUrl);
                }
              },
              onError: (e) {
                setState(() {
                  _signForDeafState = SignForDeafState.error;
                });
              },
            );
          },
          label: currentLocale == const Locale('tr')
              ? 'İşaret Dili'
              : 'Sign Language',
        ),
        for (final item in selectableRegionState.contextMenuButtonItems) item,
      ],
    );
  }

  /// Initializes the [SignForDeafArea] widget.
  Widget init(BuildContext context) {
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) {
            return SelectionArea(
              onSelectionChanged: (value) => _selectedText = value,
              contextMenuBuilder: (context, selectableRegionState) =>
                  _defaultContextMenuBuilder(context, selectableRegionState),
              child: widget.child!,
            );
          },
        ),
        OverlayEntry(
          builder: (context) {
            if (_signForDeafState == SignForDeafState.ready) {
              return _buildSignPanel(context);
            }
            return const SizedBox();
          },
        ),
        OverlayEntry(
          builder: (context) {
            if (_signForDeafState == SignForDeafState.error) {
              return _errorViewBody(context);
            }
            if (_signForDeafState == SignForDeafState.loading) {
              return _loadingViewBody(context);
            }
            if (_signForDeafState == SignForDeafState.cancelled) {
              return const SizedBox();
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  Stack _loadingViewBody(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        Container(
          color: Colors.black.withOpacity(0.3),
          width: double.infinity,
          height: double.infinity,
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'images/logo_head.png',
              scale: 3,
              package: 'mobile_sign_language_translation',
            ),
            SizedBox(
              width: MediaQuery.of(context).size.height * 0.1,
              height: MediaQuery.of(context).size.height * 0.1,
              child: const CircularProgressIndicator(
                color: Color.fromARGB(255, 103, 58, 183),
                strokeWidth: 6,
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: () {
              setState(() {
                apiServices.cancelRequest();
                _signForDeafState = SignForDeafState.none;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(top: 60, right: 30),
              child: const Icon(
                Icons.close,
                color: Color.fromARGB(255, 255, 255, 255),
                size: 30,
                weight: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Stack _errorViewBody(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        Container(
          color: const Color.fromRGBO(0, 0, 0, 0.5),
          width: double.infinity,
          height: double.infinity,
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'images/logo_head.png',
              scale: 1.5,
              package: 'mobile_sign_language_translation',
            ),
            Transform.translate(
              offset: Offset(0, MediaQuery.of(context).size.height * 0.1),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Text(
                  currentLocale == const Locale('tr')
                      ? 'Çeviri işlemi şu anda gerçekleştirilemiyor. Lütfen daha sonra tekrar deneyiniz.'
                      : 'Translation is not available at the moment. Please try again later.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 1),
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
        Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _signForDeafState = SignForDeafState.none;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(top: 60, right: 30),
              child: const Icon(
                Icons.close,
                color: Color.fromARGB(255, 255, 255, 255),
                size: 30,
                weight: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Stack _buildSignPanel(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.black.withOpacity(0.3),
          width: double.infinity,
          height: double.infinity,
        ),
        Positioned(
          bottom: 0,
          child: SlideTransition(
            position: _offsetAnimation,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: SignPanel(
                businessName: currentLocale == const Locale('tr')
                    ? 'Engelsiz Çeviri'
                    : 'SignForDeaf',
                controller: _videoController,
                onClose: () {
                  setState(() {
                    _signForDeafState = SignForDeafState.none;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoController.dispose();
    super.dispose();
  }
}
