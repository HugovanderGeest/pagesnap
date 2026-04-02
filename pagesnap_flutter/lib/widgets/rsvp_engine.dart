import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/colors.dart';

class RSVPEngine extends StatefulWidget {
  final List<String> words;
  final int initialSpeed;
  final int initialIndex;
  final Function(int) onProgress;
  final VoidCallback onCompletion;
  final VoidCallback? onFullscreen;

  const RSVPEngine({
    super.key,
    required this.words,
    this.initialSpeed = 300,
    this.initialIndex = 0,
    required this.onProgress,
    required this.onCompletion,
    this.onFullscreen,
  });

  @override
  State<RSVPEngine> createState() => _RSVPEngineState();
}

class _RSVPEngineState extends State<RSVPEngine> with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  late int _currentIndex;
  late int _wpm;
  Timer? _timer;
  Timer? _hideTimer;

  // Controls visibility — auto-hides after 3 s of play
  bool _controlsVisible = true;
  bool _showSettings = false;
  bool _isFullscreen = false;
  final bool _isLightMode = true;  // default to paper-white
  double _fontSize = 48.0;
  Color _pivotColor = AppTheme.primary;
  bool _showContext = true;
  final String _fontFamily = 'Courier';

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _wpm = widget.initialSpeed;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) _showSettings = false;
      _controlsVisible = true;
    });
    if (_isPlaying) {
      _scheduleNextWord();
      _scheduleHideControls();
    } else {
      _timer?.cancel();
      _hideTimer?.cancel();
    }
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) setState(() => _controlsVisible = false);
    });
  }

  void _onTapScreen() {
    if (_showSettings) {
      setState(() { _showSettings = false; });
      return;
    }
    setState(() => _controlsVisible = !_controlsVisible);
    if (_isPlaying && _controlsVisible) _scheduleHideControls();
  }

  void _restart() {
    setState(() { _currentIndex = 0; _isPlaying = true; _showSettings = false; _controlsVisible = true; });
    _timer?.cancel();
    _scheduleNextWord();
    _scheduleHideControls();
  }

  int _computeOptimalPivot(String word) {
    if (word.isEmpty) return 0;
    return (word.length / 2.0).ceil() - 1;
  }

  Duration _getDelayForWord(String word, double baseDelayMs) {
    double delay = baseDelayMs;
    if (word.isNotEmpty) {
      final last = word[word.length - 1];
      if (last == ',' || last == ';') delay *= 1.5;
      if (last == '.' || last == '!' || last == '?') delay *= 2.0;
    }
    if (word.length > 8) delay *= 1.2;
    return Duration(milliseconds: delay.round());
  }

  void _scheduleNextWord() {
    if (!mounted || !_isPlaying || widget.words.isEmpty) return;
    if (_currentIndex >= widget.words.length - 1) {
      setState(() => _isPlaying = false);
      widget.onCompletion();
      return;
    }
    _timer = Timer(_getDelayForWord(widget.words[_currentIndex], 60000 / _wpm), () {
      if (!mounted) return;
      setState(() => _currentIndex++);
      widget.onProgress(_currentIndex);
      _scheduleNextWord();
    });
  }

  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
      _controlsVisible = true;
      if (_showSettings) { _isPlaying = false; _timer?.cancel(); _hideTimer?.cancel(); }
    });
  }

  void _onFullscreenTap() {
    setState(() => _isFullscreen = !_isFullscreen);
    widget.onFullscreen?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) return const SizedBox.shrink();

    final currentWord = widget.words[_currentIndex];
    final prevWord = _currentIndex > 0 ? widget.words[_currentIndex - 1] : '';
    final nextWord = _currentIndex < widget.words.length - 1 ? widget.words[_currentIndex + 1] : '';

    final pivotIndex = _computeOptimalPivot(currentWord);
    final leftPart = currentWord.substring(0, pivotIndex);
    final pivotChar = currentWord.isNotEmpty ? currentWord[pivotIndex] : '';
    final rightPart = currentWord.length > pivotIndex ? currentWord.substring(pivotIndex + 1) : '';

    final progress = _currentIndex / (widget.words.length <= 1 ? 1 : widget.words.length - 1);

    final Color bgColor = _isLightMode ? AppTheme.background : Colors.black;
    final Color textColor = _isLightMode ? AppTheme.text : Colors.white;
    final Color dimColor = _isLightMode ? AppTheme.textDim : Colors.white30;
    final Color surfaceColor = _isLightMode ? AppTheme.surface : const Color(0xFF111111);
    final Color borderColor = _isLightMode ? AppTheme.border : const Color(0xFF2a2a2a);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: _isLightMode ? Brightness.light : Brightness.dark,
        statusBarIconBrightness: _isLightMode ? Brightness.dark : Brightness.light,
      ),
      child: Container(
        color: bgColor,
        child: Stack(
          children: [
            // ── Full-screen tap area ─────────────────────────────────────────
            Positioned.fill(
              child: GestureDetector(
                onTap: _onTapScreen,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Guide lines
                    Positioned(top: 0, bottom: 0, child: Container(width: 1, color: dimColor.withOpacity(0.12))),
                    Positioned(left: 0, right: 0, child: Container(height: 1, color: dimColor.withOpacity(0.12))),

                    // ── Main word pivot-aligned + faded context left/right ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Previous word — faint, left edge, right-aligned so it hugs center
                          SizedBox(
                            width: 72,
                            child: _showContext && prevWord.isNotEmpty
                                ? Text(
                                    prevWord,
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    style: TextStyle(
                                      color: dimColor.withValues(alpha: 0.45),
                                      fontSize: _fontSize * 0.34,
                                      fontFamily: _fontFamily,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),

                          // Pivot-aligned center word
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Expanded(
                                  child: Text(leftPart,
                                    textAlign: TextAlign.right,
                                    softWrap: false,
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: _fontSize,
                                      fontFamily: _fontFamily,
                                      fontWeight: FontWeight.bold,
                                    )),
                                ),
                                Text(pivotChar,
                                  style: TextStyle(
                                    color: _pivotColor,
                                    fontSize: _fontSize,
                                    fontFamily: _fontFamily,
                                    fontWeight: FontWeight.bold,
                                    shadows: [Shadow(color: _pivotColor.withValues(alpha: 0.5), blurRadius: 8)],
                                  )),
                                Expanded(
                                  child: Text(rightPart,
                                    textAlign: TextAlign.left,
                                    softWrap: false,
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: _fontSize,
                                      fontFamily: _fontFamily,
                                      fontWeight: FontWeight.bold,
                                    )),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),
                          // Next word — faint, right edge, left-aligned so it hugs center
                          SizedBox(
                            width: 72,
                            child: _showContext && nextWord.isNotEmpty
                                ? Text(
                                    nextWord,
                                    textAlign: TextAlign.left,
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    style: TextStyle(
                                      color: dimColor.withValues(alpha: 0.45),
                                      fontSize: _fontSize * 0.34,
                                      fontFamily: _fontFamily,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),

                    // HUD (progress %) — dimly visible always
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      right: 16,
                      child: Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(color: dimColor.withOpacity(0.5), fontSize: 11, fontFamily: _fontFamily)),
                    ),
                  ],
                ),
              ),
            ),

            // ── Thin progress bar at very bottom (always visible) ─────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  _timer?.cancel();
                  setState(() {
                    _isPlaying = false;
                    final p = (d.localPosition.dx / MediaQuery.of(context).size.width).clamp(0.0, 1.0);
                    _currentIndex = (p * (widget.words.length - 1)).round();
                  });
                  widget.onProgress(_currentIndex);
                },
                child: Container(
                  height: 24,
                  color: Colors.transparent,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 3,
                    color: dimColor.withOpacity(0.12),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _pivotColor,
                          boxShadow: [BoxShadow(color: _pivotColor.withOpacity(0.5), blurRadius: 6)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Controls + settings (animated show/hide) ──────────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              bottom: _controlsVisible ? 0 : -200,
              left: 0, right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Settings panel
                  if (_showSettings)
                    Container(
                      color: surfaceColor,
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('SPEED', style: TextStyle(fontSize: 10, color: dimColor, letterSpacing: 2, fontWeight: FontWeight.bold)),
                            Text('$_wpm WPM', style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.bold)),
                          ]),
                          Slider(value: _wpm.toDouble(), min: 10, max: 1000, divisions: 99,
                            activeColor: _pivotColor, inactiveColor: borderColor,
                            onChanged: (v) => setState(() => _wpm = v.toInt())),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('FONT SIZE', style: TextStyle(fontSize: 10, color: dimColor, letterSpacing: 2, fontWeight: FontWeight.bold)),
                            Text('${_fontSize.toInt()}px', style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.bold)),
                          ]),
                          Slider(value: _fontSize, min: 24, max: 120, divisions: 24,
                            activeColor: _pivotColor, inactiveColor: borderColor,
                            onChanged: (v) => setState(() => _fontSize = v)),
                          Row(children: [
                            for (final c in [AppTheme.primary, Colors.blue, Colors.green, Colors.amber, Colors.purple, Colors.grey])
                              _colorBtn(c, dimColor),
                            const Spacer(),
                            Text('CONTEXT', style: TextStyle(fontSize: 10, color: dimColor)),
                            const SizedBox(width: 6),
                            Switch(value: _showContext, activeThumbColor: _pivotColor,
                              onChanged: (v) => setState(() => _showContext = v)),
                          ]),
                        ],
                      ),
                    ),
                  // Playback bar
                  Container(
                    color: surfaceColor,
                    padding: EdgeInsets.only(
                      top: 10, left: 24, right: 24,
                      bottom: MediaQuery.of(context).padding.bottom + 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _iconBtn(LucideIcons.rotateCcw, _restart, dimColor, borderColor),
                        const SizedBox(width: 28),
                        GestureDetector(
                          onTap: _togglePlay,
                          child: Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: _pivotColor,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: _pivotColor.withOpacity(0.35), blurRadius: 14)],
                            ),
                            child: Icon(_isPlaying ? LucideIcons.pause : LucideIcons.play, color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 28),
                        _iconBtn(LucideIcons.settings, _toggleSettings,
                          _showSettings ? _pivotColor : dimColor,
                          _showSettings ? _pivotColor : borderColor,
                          bg: _showSettings ? _pivotColor.withOpacity(0.15) : null),
                        if (widget.onFullscreen != null) ...[  
                          const SizedBox(width: 12),
                          _iconBtn(
                            _isFullscreen ? LucideIcons.minimize2 : LucideIcons.maximize2,
                            _onFullscreenTap,
                            _isFullscreen ? _pivotColor : dimColor,
                            _isFullscreen ? _pivotColor : borderColor,
                            bg: _isFullscreen ? _pivotColor.withOpacity(0.15) : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorBtn(Color c, Color dimColor) {
    final selected = _pivotColor == c;
    return GestureDetector(
      onTap: () => setState(() => _pivotColor = c),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: c, shape: BoxShape.circle,
          border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 2),
          boxShadow: selected ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)] : [],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, Color iconColor, Color borderColor, {Color? bg}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: bg ?? Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}
