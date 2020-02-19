package com.musketeer.scratchpaper

import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import com.qq.e.ads.rewardvideo.RewardVideoAD
import com.qq.e.ads.rewardvideo.RewardVideoADListener
import com.qq.e.comm.util.AdError
import com.sina.weibo.sdk.WbSdk
import com.sina.weibo.sdk.auth.AuthInfo
import com.sina.weibo.sdk.auth.Oauth2AccessToken
import com.sina.weibo.sdk.auth.WbAuthListener
import com.sina.weibo.sdk.auth.WbConnectErrorMessage
import com.sina.weibo.sdk.auth.sso.SsoHandler
import com.tencent.tauth.IUiListener
import com.tencent.tauth.Tencent
import com.tencent.tauth.UiError
import com.umeng.analytics.MobclickAgent
import com.umeng.commonsdk.UMConfigure
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import org.json.JSONObject


class MainActivity: FlutterActivity(), RewardVideoADListener, IUiListener, WbAuthListener {
    private val CHANNEL = "com.musketeer.scratchpaper"

    val rewardVideoAD: RewardVideoAD by lazy {
        RewardVideoAD(this, "1103577955", "3071204170293278", this, true)
    }

    val mTencent: Tencent by lazy {
        Tencent.createInstance("101853900", this.applicationContext)
    }

    val mAuthInfo: AuthInfo by lazy {
        AuthInfo(this, "2709929479", "http://sns.whalecloud.com/sina2/callback", "all")
    }
    var mSsoHandler: SsoHandler? = null

    var adLoaded: Boolean = false
    var videoCached: Boolean = false

    var callbackResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        UMConfigure.init(this, "56ecff3ce0f55ac331000a80", "main", UMConfigure.DEVICE_TYPE_PHONE, null)
        MobclickAgent.setPageCollectionMode(MobclickAgent.PageMode.MANUAL)

        // load reward video
        rewardVideoAD.loadAD()

        WbSdk.install(this, mAuthInfo)

        MethodChannel(flutterEngine.dartExecutor, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "checkVideoAds") {
                if (adLoaded) {
                    result.success("success")
                } else {
                    rewardVideoAD.loadAD()
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
            } else if (call.method == "loginQQ") {
                if (!mTencent.isSessionValid) {
                    mTencent.login(this, "all", this)
                }
            } else if (call.method == "loginWeibo") {
                mSsoHandler = SsoHandler(this)
                mSsoHandler?.authorize(this)
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

    // 广告sdk
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
        callbackResult?.success("fail")
        callbackResult = null
    }

    override fun onADShow() {

    }

    // QQ登录
    override fun onError(p0: UiError?) {

    }

    override fun onComplete(p0: Any?) {
        Log.d("===>>>", p0.toString())
        if (p0 is JSONObject) {
            Log.d("===>>> JSONObject", p0.toString())
        }
    }

    override fun onCancel() {

    }

    // 微博
    override fun onSuccess(p0: Oauth2AccessToken?) {
        Log.d("===>>>", p0!!.uid)
    }

    override fun onFailure(p0: WbConnectErrorMessage?) {

    }

    override fun cancel() {

    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        val ssoHandler = mSsoHandler
        if (ssoHandler != null) {
            ssoHandler.authorizeCallBack(resultCode, resultCode, data)
        }
    }
}
