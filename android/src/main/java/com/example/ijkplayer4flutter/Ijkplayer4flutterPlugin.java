package com.example.ijkplayer4flutter;

import android.content.Context;
import android.net.Uri;
import android.text.TextUtils;
import android.util.Log;
import android.view.Surface;

//import com.example.ijkplayer4flutter.ijklib.application.Settings;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.FlutterNativeView;
import io.flutter.view.TextureRegistry;
import tv.danmaku.ijk.media.player.IMediaPlayer;
import tv.danmaku.ijk.media.player.IjkMediaPlayer;
import tv.danmaku.ijk.media.player.TextureMediaPlayer;

/** Ijkplayer4flutterPlugin */
public class Ijkplayer4flutterPlugin implements MethodCallHandler {

  static final String TAG = "Ijkplayer.Plugin";
  
  private static final String CHANNEL = "example.com/ijkplayer4flutter";
  private static final String CHANNEL_EVENTS = "example.com/ijkplayer4flutter/videoEvents";



  private final Registrar registrar;
  private final Map<Long, VideoPlayer> videoPlayers;

  private Ijkplayer4flutterPlugin(Registrar registrar) {
    this.registrar = registrar;
    this.videoPlayers = new HashMap<>();
  }

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final Ijkplayer4flutterPlugin plugin = new Ijkplayer4flutterPlugin(registrar);

    final MethodChannel channel =
            new MethodChannel(registrar.messenger(), CHANNEL);
    channel.setMethodCallHandler(plugin);

    registrar.addViewDestroyListener(new PluginRegistry.ViewDestroyListener() {
      @Override
      public boolean onViewDestroy(FlutterNativeView view) {
//                plugin.onDestroy();
        return false; // We are not interested in assuming ownership of the NativeView.
      }
    });
  }


  @Override
  public void onMethodCall(MethodCall call, Result result) {
//    if (call.method.equals("getPlatformVersion")) {
//      result.success("Android " + android.os.Build.VERSION.RELEASE);
//    } else {
//      result.notImplemented();
//    }

    TextureRegistry textures = registrar.textures();
    if (textures == null) {
      result.error("no_activity", "video_player plugin requires a foreground activity", null);
      return;
    }
    Log.d(TAG,"call method:"+call.method);
    switch (call.method) {
      case "init":
//        for (VideoPlayer player : videoPlayers.values()) {
//          player.dispose();
//        }
//        videoPlayers.clear();
        break;
      case "create":
      {
        TextureRegistry.SurfaceTextureEntry textureEntry = textures.createSurfaceTexture();
        EventChannel eventChannel = new EventChannel(
                        registrar.messenger(), CHANNEL_EVENTS + textureEntry.id());

        VideoPlayer player;
        if (call.argument("asset") != null) {
          Log.d(TAG,"asset"+call.argument("asset"));
          String assetLookupKey;
          if (call.argument("package") != null) {
            Log.d(TAG,"package"+call.argument("package"));
            assetLookupKey = registrar.lookupKeyForAsset((String) call.argument("asset"),
                    (String) call.argument("package"));
          } else {
            Log.d(TAG,"don't have package");
            assetLookupKey = registrar.lookupKeyForAsset((String) call.argument("asset"));
          }

          player = new VideoPlayer(registrar.context(), eventChannel, textureEntry,
                          "asset:///" + assetLookupKey, result);
          videoPlayers.put(textureEntry.id(), player);
        } else {
          Log.d(TAG,"don't have asset");
          player = new VideoPlayer(registrar.context(), eventChannel, textureEntry,
                  (String) call.argument("uri"), result);
          videoPlayers.put(textureEntry.id(), player);
        }
        break;
      }
      default:
      {
        long textureId = ((Number) call.argument("textureId")).longValue();
        VideoPlayer player = videoPlayers.get(textureId);
        if (player == null) {
          result.error(
                  "Unknown textureId",
                  "No video player associated with texture id " + textureId,
                  null);
          return;
        }
        onMethodCall(call, result, textureId, player);
        break;
      }
    }
  }

  private void onMethodCall(MethodCall call, Result result, long textureId, VideoPlayer player) {
    switch (call.method) {
      case "setLooping":
        player.setLooping((Boolean) call.argument("looping"));
        result.success(null);
        break;
      case "setVolume":
        player.setVolume((Double) call.argument("volume"));
        result.success(null);
        break;
      case "play":
        player.play();
        result.success(null);
        break;
      case "pause":
        player.pause();
        result.success(null);
        break;
      case "seekTo":
        int location = ((Number) call.argument("location")).intValue();
        player.seekTo(location);
        result.success(null);
        break;
      case "position":
        result.success(player.getPosition());
        break;
      case "dispose":
        player.dispose();
        videoPlayers.remove(textureId);
        result.success(null);
        break;
      default:
        result.notImplemented();
        break;
    }
  }
}
