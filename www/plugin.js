
var exec = require('cordova/exec');

var PLUGIN_NAME = 'YahooConnect';

var YahooConnect = {
  login: function (successCallback, errorCallback) {
	exec(successCallback, errorCallback, 'YahooConnect', 'login', []);
  },
  logout: function (successCallback, errorCallback) {
	exec(successCallback, errorCallback, 'YahooConnect', 'logout', []);
  }
};

module.exports = YahooConnect;
