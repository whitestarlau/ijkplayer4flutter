package com.example.ijkplayer4flutter;

import android.content.Context;
import android.util.Log;
import android.view.Surface;
import android.view.SurfaceHolder;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.TextureRegistry;
import tv.danmaku.ijk.media.player.IMediaPlayer;
import tv.danmaku.ijk.media.player.IjkMediaPlayer;
import tv.danmaku.ijk.media.player.IjkTimedText;
import tv.danmaku.ijk.media.player.TextureMediaPlayer;



public class VideoPlayer {
    static final String TAG = "NavtiveVideoPlayer";

    private IMediaPlayer player;

    private Surface surface;

    private final TextureRegistry.SurfaceTextureEntry textureEntry;

    private QueuingEventSink eventSink = new QueuingEventSink();

    private final EventChannel eventChannel;

    private boolean isInitialized = false;

//    private Settings mSettings;

    VideoPlayer(Context context, EventChannel eventChannel,
                TextureRegistry.SurfaceTextureEntry textureEntry, String dataSource, MethodChannel.Result result) {

//        IjkMediaPlayer.loadLibrariesOnce(null);
//        IjkMediaPlayer.native_profileBegin("libijkplayer.so");

        this.eventChannel = eventChannel;
        this.textureEntry = textureEntry;

//      TrackSelector trackSelector = new DefaultTrackSelector();
//      player = ExoPlayerFactory.newSimpleInstance(context, trackSelector);

        player = createPlayer();

//      Uri uri = Uri.parse(dataSource);
        try {
            Log.d(TAG,"dataSource:"+dataSource);
            player.setDataSource(dataSource);

            player.prepareAsync();
        }catch (IOException e){
            e.printStackTrace();
        }

//      setupVideoPlayer(eventChannel, textureEntry, result);

        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink sink) {
                eventSink.setDelegate(sink);
            }

            @Override
            public void onCancel(Object o) {
                eventSink.setDelegate(null);
            }
        });

        surface = new Surface(textureEntry.surfaceTexture());
        player.setSurface(surface);

        VideoPlayerListener listener = new VideoPlayerListener(){
            @Override
            public void onPrepared(IMediaPlayer iMediaPlayer) {
                super.onPrepared(iMediaPlayer);

            }

            @Override
            public void onVideoSizeChanged(IMediaPlayer iMediaPlayer, int i, int i1, int i2, int i3) {
                super.onVideoSizeChanged(iMediaPlayer, i, i1, i2, i3);
                isInitialized = true;
                sendInitialized();
            }
        };
        player.setOnInfoListener(listener);
        player.setOnPreparedListener(listener);
        player.setOnCompletionListener(listener);
        player.setOnErrorListener(listener);
        player.setOnVideoSizeChangedListener(listener);
//        mPlayer.setOnNativeInvokeListener(listener);
        player.setOnBufferingUpdateListener(listener);
        player.setOnSeekCompleteListener(listener);
        player.setOnTimedTextListener(listener);

        Map<String, Object> reply = new HashMap<>();
        reply.put("textureId", textureEntry.id());
        Log.d(TAG,"reply:  textureId-"+textureEntry.id());
        result.success(reply);

    }

    void play() {
        Log.d(TAG,"play command");
//      player.setPlayWhenReady(true);
        player.start();
    }

    void pause() {
        Log.d(TAG,"pause command");
//      player.setPlayWhenReady(false);
        player.pause();
    }

    void setLooping(boolean value) {
        Log.d(TAG,"setLooping command");
//      player.setRepeatMode(value ? REPEAT_MODE_ALL : REPEAT_MODE_OFF);
        player.setLooping(value);
    }

    void setVolume(double value) {
        Log.d(TAG,"setVolume command");
//      float bracketedValue = (float) Math.max(0.0, Math.min(1.0, value));
//      player.setVolume(bracketedValue);
        player.setVolume((float) value,(float) value);
    }

    void seekTo(int location) {
        Log.d(TAG,"seekTo command");
        player.seekTo(location);
    }

    long getPosition() {
        return player.getCurrentPosition();
    }

    private void sendInitialized() {
        Log.d(TAG,"sendInitialized,isInitialized?"+isInitialized);
        if (isInitialized) {
            Map<String, Object> event = new HashMap<>();
            event.put("event", "initialized");
            event.put("duration", player.getDuration());

            if (player.isPlaying()) {
                int width = player.getVideoWidth();
                int height = player.getVideoHeight();
                Log.d(TAG,"width:"+width+"height:"+height);
                event.put("width", width);
                event.put("height", height);
            }else {
                Log.d(TAG,"player not playing");
            }
            eventSink.success(event);
        }
    }

    //release resources
    void dispose() {
        if (isInitialized) {
            player.stop();
        }
        textureEntry.release();
        eventChannel.setStreamHandler(null);
        if (surface != null) {
            surface.release();
        }
        if (player != null) {
            player.release();
        }
    }

    public IMediaPlayer createPlayer() {
        IjkMediaPlayer.loadLibrariesOnce(null);
        IjkMediaPlayer.native_profileBegin("libijkplayer.so");

        IMediaPlayer mediaPlayer = null;

        IjkMediaPlayer ijkMediaPlayer = null;

//      if (mUri != null)
        {
            ijkMediaPlayer = new IjkMediaPlayer();
            ijkMediaPlayer.native_setLogLevel(IjkMediaPlayer.IJK_LOG_DEBUG);

            ijkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "framedrop", 1);
            ijkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "start-on-prepared", 0);

            ijkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "http-detect-range-support", 0);

            ijkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_CODEC, "skip_loop_filter", 48);
        }
        mediaPlayer = ijkMediaPlayer;

//      if (mSettings.getEnableDetachedSurfaceTextureView()) {
//        mediaPlayer = new TextureMediaPlayer(mediaPlayer);
//      }

        mediaPlayer = new TextureMediaPlayer(mediaPlayer);

        return mediaPlayer;
    }
}

class VideoPlayerListener implements
        IMediaPlayer.OnBufferingUpdateListener,
        IMediaPlayer.OnCompletionListener,
        IMediaPlayer.OnPreparedListener,
        IMediaPlayer.OnInfoListener,
        IMediaPlayer.OnVideoSizeChangedListener,
        IMediaPlayer.OnErrorListener,
        IMediaPlayer.OnSeekCompleteListener,
        IMediaPlayer.OnTimedTextListener{
    static final String TAG = "NavtiveVideoPlayer";

    @Override
    public void onBufferingUpdate(IMediaPlayer iMediaPlayer, int i) {
        Log.d(TAG,"onBufferingUpdate");
    }

    @Override
    public void onCompletion(IMediaPlayer iMediaPlayer) {
        Log.d(TAG,"onCompletion");
    }

    @Override
    public boolean onError(IMediaPlayer iMediaPlayer, int what, int extra) {
        Log.d(TAG, "OnError - Error code: " + what + " Extra code: " + extra);
        switch (what) {
            case -1004:
                Log.d(TAG, "MEDIA_ERROR_IO");
                break;
            case -1007:
                Log.d(TAG, "MEDIA_ERROR_MALFORMED");
                break;
            case 200:
                Log.d(TAG, "MEDIA_ERROR_NOT_VALID_FOR_PROGRESSIVE_PLAYBACK");
                break;
            case 100:
                Log.d(TAG, "MEDIA_ERROR_SERVER_DIED");
                break;
            case -110:
                Log.d(TAG, "MEDIA_ERROR_TIMED_OUT");
                break;
            case 1:
                Log.d(TAG, "MEDIA_ERROR_UNKNOWN");
                break;
            case -1010:
                Log.d(TAG, "MEDIA_ERROR_UNSUPPORTED");
                break;
        }
        switch (extra) {
            case 800:
                Log.d(TAG, "MEDIA_INFO_BAD_INTERLEAVING");
                break;
            case 702:
                Log.d(TAG, "MEDIA_INFO_BUFFERING_END");
                break;
            case 701:
                Log.d(TAG, "MEDIA_INFO_METADATA_UPDATE");
                break;
            case 802:
                Log.d(TAG, "MEDIA_INFO_METADATA_UPDATE");
                break;
            case 801:
                Log.d(TAG, "MEDIA_INFO_NOT_SEEKABLE");
                break;
            case 1:
                Log.d(TAG, "MEDIA_INFO_UNKNOWN");
                break;
            case 3:
                Log.d(TAG, "MEDIA_INFO_VIDEO_RENDERING_START");
                break;
            case 700:
                Log.d(TAG, "MEDIA_INFO_VIDEO_TRACK_LAGGING");
                break;
        }
        return false;
//        return false;
    }

    @Override
    public boolean onInfo(IMediaPlayer iMediaPlayer, int arg1, int arg2) {
        Log.d(TAG,"onInfo----");
//        if (mOnInfoListener != null) {
//            mOnInfoListener.onInfo(mp, arg1, arg2);
//        }
        switch (arg1) {
            case IMediaPlayer.MEDIA_INFO_VIDEO_TRACK_LAGGING:
                Log.d(TAG, "MEDIA_INFO_VIDEO_TRACK_LAGGING:");
                break;
            case IMediaPlayer.MEDIA_INFO_VIDEO_RENDERING_START:
                Log.d(TAG, "MEDIA_INFO_VIDEO_RENDERING_START:");
                break;
            case IMediaPlayer.MEDIA_INFO_BUFFERING_START:
                Log.d(TAG, "MEDIA_INFO_BUFFERING_START:");
                break;
            case IMediaPlayer.MEDIA_INFO_BUFFERING_END:
                Log.d(TAG, "MEDIA_INFO_BUFFERING_END:");
                break;
            case IMediaPlayer.MEDIA_INFO_NETWORK_BANDWIDTH:
                Log.d(TAG, "MEDIA_INFO_NETWORK_BANDWIDTH: " + arg2);
                break;
            case IMediaPlayer.MEDIA_INFO_BAD_INTERLEAVING:
                Log.d(TAG, "MEDIA_INFO_BAD_INTERLEAVING:");
                break;
            case IMediaPlayer.MEDIA_INFO_NOT_SEEKABLE:
                Log.d(TAG, "MEDIA_INFO_NOT_SEEKABLE:");
                break;
            case IMediaPlayer.MEDIA_INFO_METADATA_UPDATE:
                Log.d(TAG, "MEDIA_INFO_METADATA_UPDATE:");
                break;
            case IMediaPlayer.MEDIA_INFO_UNSUPPORTED_SUBTITLE:
                Log.d(TAG, "MEDIA_INFO_UNSUPPORTED_SUBTITLE:");
                break;
            case IMediaPlayer.MEDIA_INFO_SUBTITLE_TIMED_OUT:
                Log.d(TAG, "MEDIA_INFO_SUBTITLE_TIMED_OUT:");
                break;
            case IMediaPlayer.MEDIA_INFO_VIDEO_ROTATION_CHANGED:
//                mVideoRotationDegree = arg2;
                Log.d(TAG, "MEDIA_INFO_VIDEO_ROTATION_CHANGED: " + arg2);
//                if (mRenderView != null)
//                    mRenderView.setVideoRotation(arg2);
                break;
            case IMediaPlayer.MEDIA_INFO_AUDIO_RENDERING_START:
                Log.d(TAG, "MEDIA_INFO_AUDIO_RENDERING_START:");
                break;
        }
        return true;
//        return false;
    }

    @Override
    public void onPrepared(IMediaPlayer iMediaPlayer) {
        Log.d(TAG,"onPrepared");
    }

    @Override
    public void onSeekComplete(IMediaPlayer iMediaPlayer) {
        Log.d(TAG,"onSeekComplete");
    }

    @Override
    public void onVideoSizeChanged(IMediaPlayer iMediaPlayer, int i, int i1, int i2, int i3) {
        Log.d(TAG,"onVideoSizeChanged");
    }

    @Override
    public void onTimedText(IMediaPlayer iMediaPlayer, IjkTimedText ijkTimedText) {
        Log.d(TAG,"onTimedText,"+ijkTimedText);
    }
}