import 'dart:async';

import 'package:flutter/services.dart';
//import 'dart:async';
import 'dart:io';

//import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'VideoController.dart';

export 'VideoController.dart';
export 'ExWidgets.dart';

// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String CHANNEL = "example.com/ijkplayer4flutter";
const String CHANNEL_EVENTS = "example.com/ijkplayer4flutter/videoEvents";

final MethodChannel _channel = const MethodChannel(CHANNEL)..invokeMethod('init');

//EventChannel(CHANNEL_EVENTS+textureId.toString());

/// Displays the video controlled by [controller].
class VideoPlayer extends StatefulWidget {
  VideoPlayer(this.controller);

  final VideoPlayerController controller;

  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  _VideoPlayerState() {
    _listener = () {
      final int newTextureId = widget.controller.textureId;
      if (newTextureId != _textureId) {
        setState(() {
          _textureId = newTextureId;
        });
      }
    };
  }

  VoidCallback _listener;
  int _textureId;

  @override
  void initState() {
    super.initState();
    _textureId = widget.controller.textureId;
    // Need to listen for initialization events since the actual texture ID
    // becomes available after asynchronous initialization finishes.
    widget.controller.addListener(_listener);
  }

  @override
  void didUpdateWidget(VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller.removeListener(_listener);
    _textureId = widget.controller.textureId;
    widget.controller.addListener(_listener);
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.controller.removeListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
//    return Texture(textureId: _textureId);
    return _textureId == null ? Container() : Texture(textureId: _textureId);
  }

  @override
  void dispose(){

  }
}


/// Displays the video controlled by [controller].
class IjkPlayer extends StatefulWidget {
  IjkPlayer(this.dataSource);

//  final VideoPlayerController controller;
  final String dataSource;

  _IjkPlayerState _ijkPlayerState;

  @override
  State<StatefulWidget> createState() {
    _ijkPlayerState = _IjkPlayerState.network(dataSource);
    return _ijkPlayerState;
  }
//  @override
//  _IjkPlayerState createState() => _IjkPlayerState.network(dataSource);

//  PlayerValueNotifier getValueNotifier(){
//    if(_ijkPlayerState.valueNotifier != null){
//      return _ijkPlayerState.valueNotifier;
//    }else{
//      return null;
//    }
//  }


  addValueListener(PlayerValueCallback listener){
//    print("PlayerValueCallback,add1");
    _ijkPlayerState.addValueListener(listener);
  }

  addPositionListener(PositionCallback listener){
    _ijkPlayerState.addPositionListener(listener);
  }

  bool isPlaying(){
    return _ijkPlayerState.isPlaying();
  }
  play(){
    _ijkPlayerState.play();
  }
  pause(){
    _ijkPlayerState.pause();
  }

  setVolume(double volume){
    _ijkPlayerState.setVolume(volume);
  }
  setLooping(bool looping){
    _ijkPlayerState.setLooping(looping);
  }
  playerSeekTo(Duration moment){
    _ijkPlayerState.seekTo(moment);
  }
}

class _IjkPlayerState extends State<IjkPlayer>  with WidgetsBindingObserver{
  int _textureId;
  final String dataSource;

  /// Describes the type of data source this [VideoPlayerController]
  /// is constructed with.
  final DataSourceType dataSourceType;

  final String package;
  Timer _timer;
  bool _isDisposed = false;
  Completer<void> _creatingCompleter;
  StreamSubscription<dynamic> _eventSubscription;

  _IjkPlayerState.network(this.dataSource)
      : dataSourceType = DataSourceType.network,
        package = null;

//  VideoPlayerValue value;

  PlayerValueNotifier valueNotifier;

  bool _wasPlayingBeforePause = false;

  PlayerPositionValueNotifier positionNotifier;

  addValueListener(PlayerValueCallback listener){
    valueNotifier.addListener((){
//      print("PlayerValueCallback"+valueNotifier.value.position.toString());
//      print("PlayerValueCallback"+valueNotifier.value.isPlaying.toString());
      listener(valueNotifier.value);
    });
  }

  addPositionListener(PositionCallback listener){
    positionNotifier.addListener((){
      print(positionNotifier.value);
      listener(positionNotifier.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    print("_textureId:$_textureId");
    return _textureId == null ? Container() : Texture(textureId: _textureId);
  }

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    initialize();

    valueNotifier.addListener(() {
      if (valueNotifier.value.hasError) {
        print("valueNotifier:"+valueNotifier.value.errorDescription);
      }
    });

    setLooping(true);

    play();
  }

  @override
  void dispose(){
    WidgetsBinding.instance.removeObserver(this);

    disposeFuture();

    super.dispose();
  }

  @override
  Future<void> disposeFuture() async {
    if (_creatingCompleter != null) {
      await _creatingCompleter.future;
      if (!_isDisposed) {
        _isDisposed = true;
        _timer?.cancel();
        await _eventSubscription?.cancel();
        await _channel.invokeMethod(
          'dispose',
          <String, dynamic>{'textureId': _textureId},
        );
      }
//      _lifeCycleObserver.dispose();
    }
    _isDisposed = true;

  }


  ///WidgetsBindingObserver中方法
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("AppLifecycleState:"+state.toString());
    switch (state) {
      case AppLifecycleState.paused:
        _wasPlayingBeforePause = valueNotifier.value.isPlaying;
        pause();
        break;
      case AppLifecycleState.resumed:
        if (_wasPlayingBeforePause) {
          play();
        }
        break;
      default:
    }
  }

  Future<void> initialize() async {
//    value = new VideoPlayerValue(duration: null);
    valueNotifier = new PlayerValueNotifier();
//    value = valueNotifier.value;

    positionNotifier = new PlayerPositionValueNotifier();

    _creatingCompleter = Completer<void>();
    Map<dynamic, dynamic> dataSourceDescription;
    switch (dataSourceType) {
      case DataSourceType.asset:
        dataSourceDescription = <String, dynamic>{
          'asset': dataSource,
          'package': package
        };
        break;
      case DataSourceType.network:
        dataSourceDescription = <String, dynamic>{'uri': dataSource};
        break;
      case DataSourceType.file:
        dataSourceDescription = <String, dynamic>{'uri': dataSource};
    }
    final Map<dynamic, dynamic> response = await _channel.invokeMethod(
      'create',
      dataSourceDescription,
    );
    setState(() {
      _textureId = response['textureId'];
    });
    _creatingCompleter.complete(null);
    final Completer<void> initializingCompleter = Completer<void>();

    DurationRange toDurationRange(dynamic value) {
      final List<dynamic> pair = value;
      return DurationRange(
        Duration(milliseconds: pair[0]),
        Duration(milliseconds: pair[1]),
      );
    }

    void eventListener(dynamic event) {
      final Map<dynamic, dynamic> map = event;
//      if(value == null){
//        return;
//      }
      switch (map['event']) {
        case 'initialized':
          valueNotifier.value = valueNotifier.value.copyWith(
            duration: Duration(milliseconds: map['duration']),
            size: Size(map['width']?.toDouble() ?? 0.0,
                map['height']?.toDouble() ?? 0.0),
          );
          positionNotifier.value = positionNotifier.value.copyWith(
            duration: Duration(milliseconds: map['duration']),
          );
          try{
            initializingCompleter.complete(null);
          }catch(e){
            print(e.toString());
          }

          _applyLooping();
          _applyVolume();
          _applyPlayPause();
          break;
        case 'completed':
          valueNotifier.value = valueNotifier.value.copyWith(isPlaying: false);
          _timer?.cancel();
          break;
        case 'bufferingUpdate':
          final List<dynamic> values = map['values'];
          valueNotifier.value = valueNotifier.value.copyWith(
            buffered: values.map<DurationRange>(toDurationRange).toList(),
          );
          break;
        case 'bufferingStart':
          valueNotifier.value = valueNotifier.value.copyWith(isBuffering: true);
          break;
        case 'bufferingEnd':
          valueNotifier.value = valueNotifier.value.copyWith(isBuffering: false);
          break;
      }
      print("value:"+valueNotifier.value.toString());
    }

    void errorListener(Object obj) {
      final PlatformException e = obj;
//      if(value == null){
//        return;
//      }
      valueNotifier.value = VideoPlayerValue.erroneous(e.message);
      _timer?.cancel();
    }

    _eventSubscription = _eventChannelGetter(_textureId)
        .receiveBroadcastStream()
        .listen(eventListener, onError: errorListener);
    return initializingCompleter.future;
  }

  ///获取事件通道
  EventChannel _eventChannelGetter(int textureId) {
    return EventChannel(CHANNEL_EVENTS+textureId.toString());
  }

  @override
  void didUpdateWidget(IjkPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

  }

  @override
  void deactivate() {
    super.deactivate();

  }

//  Future<void> isPlaying() async {
//    value = value.copyWith(isPlaying: true);
//    await _applyPlayPause();
//  }

  bool isPlaying() {
    return valueNotifier.value.isPlaying;
  }

  Future<void> play() async {
    valueNotifier.value = valueNotifier.value.copyWith(isPlaying: true);
    await _applyPlayPause();
  }

  Future<void> setLooping(bool looping) async {
    valueNotifier.value = valueNotifier.value.copyWith(isLooping: looping);
    await _applyLooping();
  }

  Future<void> pause() async {
    valueNotifier.value = valueNotifier.value.copyWith(isPlaying: false);
    await _applyPlayPause();
  }

  Future<void> seekTo(Duration moment) async {
    if (_isDisposed) {
      return;
    }
    if (moment > valueNotifier.value.duration) {
      moment = valueNotifier.value.duration;
    } else if (moment < const Duration()) {
      moment = const Duration();
    }
    await _channel.invokeMethod('seekTo', <String, dynamic>{
      'textureId': _textureId,
      'location': moment.inMilliseconds,
    });
//    valueNotifier.value = valueNotifier.value.copyWith(position: moment);
    positionNotifier.value = positionNotifier.value.copyWith(position: moment);
  }

  /// Sets the audio volume of [this].
  ///
  /// [volume] indicates a value between 0.0 (silent) and 1.0 (full volume) on a
  /// linear scale.
  Future<void> setVolume(double volume) async {
    valueNotifier.value = valueNotifier.value.copyWith(volume: volume.clamp(0.0, 1.0));
    await _applyVolume();
  }

  Future<void> _applyLooping() async {
    if (!valueNotifier.value.initialized || _isDisposed) {
      return;
    }
    _channel.invokeMethod(
      'setLooping',
      <String, dynamic>{'textureId': _textureId, 'looping': valueNotifier.value.isLooping},
    );
  }

  Future<void> _applyPlayPause() async {
    if (!valueNotifier.value.initialized || _isDisposed) {
      return;
    }
    if (valueNotifier.value.isPlaying) {
      await _channel.invokeMethod(
        'play',
        <String, dynamic>{'textureId': _textureId},
      );
      _timer = Timer.periodic(
        //每500ms查询一次播放进度
        const Duration(milliseconds: 500),
            (Timer timer) async {
          if (_isDisposed) {
            return;
          }
          final Duration newPosition = await position;
          if (_isDisposed) {
            return;
          }
//          valueNotifier.value = valueNotifier.value.copyWith(position: newPosition);
          positionNotifier.value = positionNotifier.value.copyWith(position: newPosition);
        },
      );
    } else {
      _timer?.cancel();
      await _channel.invokeMethod(
        'pause',
        <String, dynamic>{'textureId': _textureId},
      );
    }
  }

  Future<void> _applyVolume() async {
    if (!valueNotifier.value.initialized || _isDisposed) {
      return;
    }
    await _channel.invokeMethod(
      'setVolume',
      <String, dynamic>{'textureId': _textureId, 'volume': valueNotifier.value.volume},
    );
  }

  /// The position in the current video.
  /// video当前的播放位置
  Future<Duration> get position async {
    if (_isDisposed) {
      return null;
    }
    return Duration(
      milliseconds: await _channel.invokeMethod(
        'position',
        <String, dynamic>{'textureId': _textureId},
      ),
    );
  }
}

class PlayerValueNotifier extends ValueNotifier<VideoPlayerValue> {
  PlayerValueNotifier() :super(VideoPlayerValue(duration: null));
}

typedef PositionCallback = void Function(PlayerPositionValue value);

typedef PlayerValueCallback = void Function(VideoPlayerValue value);

class PlayerPositionValueNotifier extends ValueNotifier<PlayerPositionValue> {
  PlayerPositionValueNotifier() :super(PlayerPositionValue(duration: null));
}

/// The duration, current position, buffering state, error state and settings
/// of a [VideoPlayerController].
class VideoPlayerValue {
  VideoPlayerValue({
    @required this.duration,
    this.size,
    this.position = const Duration(),
    this.buffered = const <DurationRange>[],
    this.isPlaying = false,
    this.isLooping = false,
    this.isBuffering = false,
    this.volume = 1.0,
    this.errorDescription,
  });

  VideoPlayerValue.uninitialized() : this(duration: null);

  VideoPlayerValue.erroneous(String errorDescription)
      : this(duration: null, errorDescription: errorDescription);

  /// The total duration of the video.
  ///
  /// Is null when [initialized] is false.
  final Duration duration;

  /// The current playback position.
  final Duration position;

  /// The currently buffered ranges.
  final List<DurationRange> buffered;

  /// True if the video is playing. False if it's paused.
  final bool isPlaying;

  /// True if the video is looping.
  final bool isLooping;

  /// True if the video is currently buffering.
  final bool isBuffering;

  /// The current volume of the playback.
  final double volume;

  /// A description of the error if present.
  ///
  /// If [hasError] is false this is [null].
  final String errorDescription;

  /// The [size] of the currently loaded video.
  ///
  /// Is null when [initialized] is false.
  final Size size;

  bool get initialized => duration != null;
  bool get hasError => errorDescription != null;
  double get aspectRatio => size.width / size.height;

  VideoPlayerValue copyWith({
    Duration duration,
    Size size,
    Duration position,
    List<DurationRange> buffered,
    bool isPlaying,
    bool isLooping,
    bool isBuffering,
    double volume,
    String errorDescription,
  }) {
    return VideoPlayerValue(
      duration: duration ?? this.duration,
      size: size ?? this.size,
      position: position ?? this.position,
      buffered: buffered ?? this.buffered,
      isPlaying: isPlaying ?? this.isPlaying,
      isLooping: isLooping ?? this.isLooping,
      isBuffering: isBuffering ?? this.isBuffering,
      volume: volume ?? this.volume,
      errorDescription: errorDescription ?? this.errorDescription,
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'duration: $duration, '
        'size: $size, '
        'position: $position, '
        'buffered: [${buffered.join(', ')}], '
        'isPlaying: $isPlaying, '
        'isLooping: $isLooping, '
        'isBuffering: $isBuffering'
        'volume: $volume, '
        'errorDescription: $errorDescription)';
  }
}

class PlayerPositionValue {
  PlayerPositionValue({
    @required this.duration,
    this.position = const Duration(),

  });

  PlayerPositionValue.uninitialized() : this(duration: null);

  /// The total duration of the video.
  ///
  /// Is null when [initialized] is false.
  final Duration duration;

  /// The current playback position.
  final Duration position;


  PlayerPositionValue copyWith({
    Duration duration,
    Duration position,
  }) {
    return PlayerPositionValue(
      duration: duration ?? this.duration,
      position: position ?? this.position,
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'duration: $duration, '
        'position: $position, ';
  }
}