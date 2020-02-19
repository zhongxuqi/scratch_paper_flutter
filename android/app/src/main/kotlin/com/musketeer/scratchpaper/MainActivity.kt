package com.musketeer.scratchpaper

import android.os.SystemClock
import android.util.Log
import androidx.annotation.NonNull;
import com.qq.e.ads.rewardvideo.RewardVideoAD
import com.qq.e.ads.rewardvideo.RewardVideoADListener
import com.qq.e.comm.util.AdError
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import com.umeng.analytics.MobclickAgent
import com.umeng.commonsdk.UMConfigure
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity(), RewardVideoADListener {
    private val CHANNEL = "com.musketeer.scratchpaper"

    val rewardVideoAD: RewardVideoAD by lazy {
        RewardVideoAD(this, "1103577955", "3071204170293278", this, true)
    }

    var adLoaded: Boolean = false
    var videoCached: Boolean = false

    var callbackResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        UMConfigure.init(this, "56ecff3ce0f55ac331000a80", "main", UMConfigure.DEVICE_TYPE_PHONE, null)
        MobclickAgent.setPageCollectionMode(MobclickAgent.PageMode.MANUAL)

        // load reward video
        rewardVideoAD.loadAD()

        MethodChannel(flutterEngine.dartExecutor, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "checkVideoAds") {
                if (adLoaded) {
                    result.success("success")
                } else {
                    callbackResult = result
                }
            } else if (call.method == "showVideoAds") {
                callbackResult = null
                if (adLoaded) {
                    if (rewardVideoAD.hasShown()) {
                        rewardVideoAD.loadAD()
                        adLoaded =false
                        result.success("wait")
                    } else {
                        callbackResult = result
                        rewardVideoAD.showAD()
                    }
                } else {
                    result.success("wait")
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        MobclickAgent.onResume(this)
    }

    override fun onPause() {
        super.onPause()
        MobclickAgent.onPause(this)
    }

    override fun onADExpose() {

    }

    override fun onADClick() {

    }

    override fun onVideoCached() {
        videoCached = true
    }

    override fun onReward() {

    }

    override fun onADClose() {
        callbackResult?.success("fail")
        callbackResult = null
    }

    override fun onADLoad() {
        adLoaded = true
        callbackResult?.success("success")
        callbackResult = null
    }

    override fun onVideoComplete() {
        callbackResult?.success("success")
        callbackResult = null
    }

    override fun onError(p0: AdError?) {

    }

    override fun onADShow() {

    }
}
