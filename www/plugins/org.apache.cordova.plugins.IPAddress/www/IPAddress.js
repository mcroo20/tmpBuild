cordova.define("org.apache.cordova.plugins.IPAddress.ipaddress", function(require, exports, module) { //
//  ActionSheet.js
//
// Created by Olivier Louvignes on 2011-11-27.
//
// Copyright 2011-2012 Olivier Louvignes. All rights reserved.
// MIT Licensed

(function(cordova) {

	function IPAddress() {}
 
 var IPAddressError = function(code, message) {
    this.code = code || null;
    this.message = message || '';
 };
 
 IPAddressError.NO_IP_ADDRESS = 0;
 
 IPAddress.prototype.get = function(success,fail) {
    cordova.exec(success,fail,"IPAddress", "get",[]);
 };

	cordova.addConstructor(function() {
		if(!window.plugins) window.plugins = {};
		window.plugins.ipaddress = new IPAddress();
	});

})(window.cordova || window.Cordova);
});
