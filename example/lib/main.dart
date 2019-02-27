// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An example of using the plugin, controlling lifecycle and playback of the
/// video.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ijkplayer4flutter/ijkplayer4flutter.dart';

import 'package:flutter/rendering.dart';

void main() {
//  debugPaintSizeEnabled = true;

  final String url1 = "http://flv2.bn.netease.com/videolib3/1611/28/GbgsL3639/SD/movie_index.m3u8";
  final String url2 = "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8";
  final String url3 = "http://qukufile2.qianqian.com/data2/video/f0b3f865a41736655ae535c3e2432f22/608007995/608007995.mp4";

//  runApp(
//    new MaterialApp(
//      title: 'Flutter教程',
//      home: test(),
//    ),
//  );

  runApp(
    new MaterialApp(
      title: 'Flutter教程',
      home: PlayerDemo(url1),
    ),
  );

//  debugDumpRenderTree();
}

class PlayerDemo extends StatefulWidget {
  PlayerDemo(this.dataSource,{Key key}) : super(key: key);

  final String dataSource;

  @override
  State<StatefulWidget> createState() {
    return new _PlayerDemoState(dataSource);
  }
}

class _PlayerDemoState extends State<PlayerDemo> {

  final DataSourceType dataSourceType;
  final String dataSource;

  IjkPlayer _ijkPlayer;
  Controller _controller;

  bool isBarVisiable;

  _PlayerDemoState(this.dataSource) : dataSourceType = DataSourceType.network;

  @override
  void initState() {
    super.initState();

    isBarVisiable = true;

    _controller = new Controller();

    _ijkPlayer = IjkPlayer(dataSource);
    _controller.bind(_ijkPlayer);

  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    Size screenSize=MediaQuery.of(context).size;

    return new Scaffold(
//      appBar: new AppBar(
//        title: new Text('ijkplayer'),
//      ),

      body: new Stack(
          alignment:Alignment.centerLeft,
          children: <Widget>[
            Container(
              height: 240,
              width: screenSize.width,
              child: GestureDetector(
                onTap:(){
                  setState(() {
                    isBarVisiable = !isBarVisiable;
                  });
                },
                child: _ijkPlayer,
              ),
            ),
            new Positioned(
              bottom : 0.0,
              child: Container(
                height: 50,
                width: screenSize.width,
                child: Offstage(
                  offstage: isBarVisiable,
                  child: VideoBottomBar(_controller),
                ),
              ),
            ),
            new Positioned(
              top: 0.0,
              child: Container(
                height: 50,
                width: screenSize.width,
                child: Offstage(
                  offstage: isBarVisiable,
                  child: VideoTopBar(),
                ),
              ),
            ),
          ]
      ),
    );
  }
}

class Controller{
  IjkPlayer ijkPlayer;

  bind(IjkPlayer ijkPlayer){
    this.ijkPlayer = ijkPlayer;
  }

  bool isPlaying(){
    return ijkPlayer.isPlaying();
  }

  ///after dispose,all call will be useless
  dispose(){
    ijkPlayer = null;
  }

  play(){
    if(ijkPlayer != null){
      ijkPlayer.play();
    }
  }
  pause(){
    if(ijkPlayer != null){
      ijkPlayer.pause();
    }
  }

  setVolume(double volume){
    if(ijkPlayer != null){
      ijkPlayer.setVolume(volume);
    }
  }
  setLooping(bool looping){
    if(ijkPlayer != null){
      ijkPlayer.setLooping(looping);
    }
  }
  playerSeekTo(Duration moment){
    if(ijkPlayer != null){
      ijkPlayer.playerSeekTo(moment);
    }
  }
}


class VideoBottomBar extends StatefulWidget {
  Controller _controller;
  VideoBottomBar(this._controller);

  @override
  State createState() {
    return _VideoBottomBarState(_controller);
  }
}

class _VideoBottomBarState extends State<VideoBottomBar> {
  Controller _controller;
  _VideoBottomBarState(this._controller);

  bool isPlaying = false;

  double _duration = 0;
  double _position = 0;

  bool onDrag = false;

  String _duration_s = '00:00';
  String _position_s = '00:00';

  @override
  void initState() {
    super.initState();
    _controller.ijkPlayer.addValueListener(
            (VideoPlayerValue value){
              print("PlayerValueCallback");
              print("isPlaying?"+value.isPlaying.toString());
              if(isPlaying != value.isPlaying ){
                setState(() {
                  isPlaying = value.isPlaying;
                });
              }
            },
    );
    _controller.ijkPlayer.addPositionListener(
            (PlayerPositionValue value){
//              print("positionX:"+value.position.toString().split("\\\.")[0]);
//              print("positionX:"+value.position.toString().split("\\\.")[1]);
              print("positionX:"+value.position.toString().split(".").toString());

              if((_position != value.position.inSeconds.toDouble()) && !onDrag){
                setState(() {
                  _position = value.position.inSeconds.toDouble();

//                  _position_s = value.position.inHours.toString()+":"
//                      +value.position.inMinutes.toString()+":"
//                      +value.position.inSeconds.toString();
                  _position_s = value.position.toString().split(".")[0];
//                  _position_s;
                });
              }
              if(_duration != value.duration.inSeconds.toDouble()){
                setState(() {
                  _duration = value.duration.inSeconds.toDouble();

//                  _duration_s = value.duration.inHours.toString()+":"
//                      +value.duration.inMinutes.toString()+":"
//                      +value.duration.inSeconds.toString();

                  _duration_s = value.duration.toString().split(".")[0];
                });
              }
            });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 1,
          child:Center(
            child: Text(
              _position_s,
              style: new TextStyle(
                fontSize: 10.0,
                fontFamily: 'serif',
                color: Colors.white,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child:buildPauseBt(),
        ),
        Expanded(
          flex: 3,
          child: Container(
            width: 120,
            child: Slider(
              max: _duration,
              min: 0,
              value: _position,
              onChangeStart: (double value){
                onDrag = true;
              },
              onChangeEnd: (double value){
                onDrag = false;
                _controller.playerSeekTo(Duration(seconds: _position.floor()));
              },
              onChanged: (double value){
                setState(() {
                  _position = value;
                });
              },
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child:Center(
            child: Text(
              _duration_s,
              style: new TextStyle(
                fontSize: 10.0,
                fontFamily: 'serif',
                color: Colors.white,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: FlatButton(
            child: Image.asset("image/ic_fullscreen.png",height: 20,width: 20,),
            onPressed: () =>{
            },
          ),
        ),

      ],
    );
  }

  buildPauseBt(){
    return Stack(
      children: <Widget>[
        Offstage(
          offstage: isPlaying,
          child: FlatButton(
            child: Image.asset("image/ic_video_play.png",height: 20,width: 20,),
            onPressed: () {
              _controller.play();
            },
          ),
        ),
        Offstage(
          offstage: !isPlaying,
          child: FlatButton(
            child: Image.asset("image/ic_video_pause.png",height: 20,width: 20,),
            onPressed: () {
              _controller.pause();
            },
          ),
        ),
      ],
    );
  }
}

class VideoTopBar extends StatefulWidget {

  @override
  State createState() {
    return _VideoTopBarState();
  }
}

class _VideoTopBarState extends State<VideoTopBar> {
  @override
  Widget build(BuildContext context) {

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 1,
          child: FlatButton(
            child: Image.asset("image/ic_return_back.png",height: 20,width: 20,),
            onPressed: () =>{

            },
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            "title",
            style: new TextStyle(
              fontSize: 20.0,
              fontFamily: 'serif',
              color: Colors.white,
            ),
          ),
        ),
//        Text(
//          "title",
//          style: new TextStyle(
//            fontSize: 20.0,
//            fontFamily: 'serif',
//            color: Colors.white,
//          ),
//        ),
      ],
    );
  }
}