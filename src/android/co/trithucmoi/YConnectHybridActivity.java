package co.trithucmoi;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.widget.TextView;

import jp.co.toiware.app.R;
import jp.co.yahoo.yconnect.YConnectHybrid;
import jp.co.yahoo.yconnect.core.oauth2.AuthorizationException;
import jp.co.yahoo.yconnect.core.oidc.OIDCDisplay;
import jp.co.yahoo.yconnect.core.oidc.OIDCPrompt;
import jp.co.yahoo.yconnect.core.oidc.OIDCScope;

/**
 * Hybrid Flow Sample Activity
 *
 * @author Copyright (C) 2017 Yahoo Japan Corporation. All Rights Reserved.
 */
public class YConnectHybridActivity extends Activity {

  private final static String TAG = YConnectHybridActivity.class.getSimpleName();

  // Client ID
  public final static String clientId = "dj00aiZpPTBNRHJsU0pDTnNmeSZzPWNvbnN1bWVyc2VjcmV0Jng9M2M-";

  //1を指定した場合、同意キャンセル時にredirect_uri設定先へ遷移する
  public final static String BAIL = "1";

  //最大認証経過時間
  public final static String MAX_AGE = "3600";

  public final static String customUriScheme = "yj-gdbn://cb";

  public final static String YCONNECT_PREFERENCE_NAME = "yconnect";

  @Override
  public void onCreate(Bundle savedInstanceState) {

    super.onCreate(savedInstanceState);

    SharedPreferences sharedPreferences = getSharedPreferences(YCONNECT_PREFERENCE_NAME, Activity.MODE_PRIVATE);

    // YConnectインスタンス取得
    YConnectHybrid yconnect = YConnectHybrid.getInstance();

    // ログレベル設定（必要に応じてレベルを設定してください）
    //YConnectLogger.setLogLevel(YConnectLogger.DEBUG);

    Intent intent = getIntent();

    if (Intent.ACTION_VIEW.equals(intent.getAction())) {

      /**************************************************
       Parse the Response Url and Save the Access Token.
       **************************************************/

      try {

        Log.i(TAG, "Get Response Url and parse it.");

        // stateの読み込み
        String state = sharedPreferences.getString("state", null);

        // response Url(Authorizationエンドポイントより受け取ったコールバックUrl)から各パラメーターを抽出
        Uri uri = intent.getData();
        yconnect.parseAuthorizationResponse(uri, customUriScheme, state);
        // 認可コード、Access Token、ID Tokenを取得
        String code = yconnect.getAuthorizationCode();
        String accessTokenString = yconnect.getAccessToken();
        String idTokenString = yconnect.getIdToken();

        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString("code", code);
        editor.putString("accessToken", accessTokenString);
        editor.putString("idToken", idTokenString);
        editor.commit();

        Intent returnIntent = new Intent();
        setResult(Activity.RESULT_OK, returnIntent);
        finish();

      } catch (AuthorizationException e) {
        Log.e(TAG, "error=" + e.getError() + ", error_description=" + e.getErrorDescription());
      } catch (Exception e) {
        e.printStackTrace();
        Log.e(TAG, "error!!");
      }

    } else {

      /********************************************************
       Request Authorization Endpoint for getting Access Token.
       ********************************************************/

      Log.i(TAG, "Request authorization.");

      // 各パラメーター初期化
      // リクエストとコールバック間の検証用のランダムな文字列を指定してください
      String state = "44GC44GC54Sh5oOF";
      // リプレイアタック対策のランダムな文字列を指定してください
      String nonce = "U0FNTCBpcyBEZWFkLg==";
      String display = OIDCDisplay.TOUCH;
      String[] prompt = {OIDCPrompt.LOGIN};
      String[] scope = {OIDCScope.OPENID, OIDCScope.PROFILE,
        OIDCScope.EMAIL, OIDCScope.ADDRESS};

      // state、nonceを保存
      SharedPreferences.Editor editor = sharedPreferences.edit();
      editor.putString("state", state);
      editor.putString("nonce", nonce);
      editor.commit();

      // 各パラメーターを設定
      yconnect.init(clientId, customUriScheme, state, display, prompt, scope, nonce, BAIL, MAX_AGE);
      // Authorizationエンドポイントにリクエスト
      // (ブラウザーを起動して同意画面を表示)
      yconnect.requestAuthorization(this);
    }
  }
}
