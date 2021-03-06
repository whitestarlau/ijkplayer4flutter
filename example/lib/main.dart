// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An example of using the plugin, controlling lifecycle and playback of the
/// video.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ijkplayer4flutter/ijkplayer4flutter.dart';

import 'package:flutter/rendering.dart';

import 'dart:io';
import 'package:flutter/services.dart';

void main() {
//  debugPaintSizeEnabled = true;

  final String url1 = "http://flv2.bn.netease.com/videolib3/1611/28/GbgsL3639/SD/movie_index.m3u8";
  final String url2 = "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8";
  final String url3 = "http://qukufile2.qianqian.com/data2/video/f0b3f865a41736655ae535c3e2432f22/608007995/608007995.mp4";

  runApp(
    new MaterialApp(
      title: 'ijkplayer4flutter',
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

  Size _screenSize;
  bool _full = false;

  @override
  void initState() {
    super.initState();

    isBarVisiable = true;

    _controller = new Controller();

    _ijkPlayer = IjkPlayer(dataSource);
    _controller.bindPlayer(_ijkPlayer);
    _controller.bind(this);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void rotate(){
    setState(() {
      _full = !_full;
    });
    if (Platform.isAndroid) {
      //设置全屏,隐藏状态栏和虚拟按键
      if(_full){
        SystemChrome.setEnabledSystemUIOverlays([]);
      }else{
        SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    _screenSize =MediaQuery.of(context).size;

    return new Scaffold(
      //多种在全屏模式下隐藏appbar的方式，均不太完美
//      appBar: PreferredSize(
//        preferredSize: new Size(_screenSize.width, _full?0:50),
//        child: Offstage(
//            offstage: _full,
//            child: AppBar(
//              centerTitle:true,
//            )
//        )
//      ),
//      appBar: PreferredSize(
//          preferredSize: new Size(_screenSize.width, _full?0:50),
//          child: new AnimatedOpacity(// 使用一个AnimatedOpacity Widget
//              opacity: _full?1.0:0,
//              duration: new Duration(seconds: 1),//过渡时间：1
//              child:new AppBar(
//                centerTitle: true,
//
//              )
//          ),
//      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody(){
    int rotate = 0;
    double width;
    double height;
    if(_full){
      rotate = 1;
      width = _screenSize.height;
       height = _screenSize.width;
    }else{
      rotate = 0;
      width = _screenSize.width;
//      height = _screenSize.height;
      height = width*9/16;
    }

    if(_full){

    }else{

    }
    return RotatedBox(
      quarterTurns: rotate,
      child: new Stack(
          alignment:Alignment.centerLeft,
          children: <Widget>[
            Container(
              height: height,
              width: width,
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
                width: width,
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
                width: width,
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
  _PlayerDemoState demo;

  bind(_PlayerDemoState demo){
    this.demo = demo;
  }

  rotate(){
    if(demo != null){
      demo.rotate();
    }
  }

  bindPlayer(IjkPlayer ijkPlayer){
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
            onPressed: (){
              setState(() {
                _controller.rotate();
              });
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