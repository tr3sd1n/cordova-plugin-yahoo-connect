/**
 */
package co.trithucmoi;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.util.Log;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class YahooConnect extends CordovaPlugin {
  private static final String TAG = "YahooConnect";
  private String action;
  private CallbackContext callbackContext;
  public final static String YCONNECT_PREFERENCE_NAME = "yconnect";
  public final static int REQUEST_LOGIN = 100;
  public final static int REQUEST_LOGOUT = 200;

  public void initialize(CordovaInterface cordova, CordovaWebView webView) {
    super.initialize(cordova, webView);
  }

  public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
    Log.v(TAG, "Received: " + action);
    this.action = action;
    this.callbackContext = callbackContext;
    final Activity activity = this.cordova.getActivity();
    cordova.setActivityResultCallback(this);
    if (action.equals("login")) {
      login(activity);
      return true;
    }
    if (action.equals("logout")) {
      logout(callbackContext);
      return true;
    }

    return false;
  }

  private void login(final Activity activity) {
    cordova.getThreadPool().execute(new Runnable() {
      @Override
      public void run() {
        Intent intent = new Intent();
        intent.setClassName(cordova.getContext(),
          "co.trithucmoi.YConnectHybridActivity");
        cordova.getActivity().startActivityForResult(intent, REQUEST_LOGIN);
      }
    });
  }

  private void logout(final CallbackContext callbackContext) {
    cordova.getThreadPool().execute(new Runnable() {
      @Override
      public void run() {

      }
    });
  }

  public void onActivityResult(int requestCode, int resultCode, Intent intent) {
    super.onActivityResult(requestCode, resultCode, intent);
    Log.v(TAG, "activity result: " + requestCode + ", code: " + resultCode);
    if (action.equals("login") && requestCode == REQUEST_LOGIN) {
      JSONObject jo = new JSONObject();
      SharedPreferences sharedPreferences = cordova.getActivity().getSharedPreferences(YCONNECT_PREFERENCE_NAME, Activity.MODE_PRIVATE);
      try {
        jo.put("accessToken", sharedPreferences.getString("accessToken", ""));
        jo.put("idToken", sharedPreferences.getString("idToken", ""));
        jo.put("code", sharedPreferences.getString("code", ""));
      } catch (JSONException e) {
        e.printStackTrace();
      }

      callbackContext.success(jo);
    }
	else if (action.equals("logout") && requestCode == REQUEST_LOGOUT) {

	}
  }
}
