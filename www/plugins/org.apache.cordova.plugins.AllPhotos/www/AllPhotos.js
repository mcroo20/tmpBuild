cordova.define("org.apache.cordova.plugins.AllPhotos.allphotos", function(require, exports, module) { //
//  ActionSheet.js
//
// Created by Olivier Louvignes on 2011-11-27.
//
// Copyright 2011-2012 Olivier Louvignes. All rights reserved.
// MIT Licensed

(function(cordova) {

	function AllPhotos() {}
 
 var AllPhotosError = function(code, message) {
    this.code = code || null;
    this.message = message || '';
 };
 
 AllPhotos.prototype.get = function(success,fail) {
    cordova.exec(success,fail,"AllPhotos", "get",[]);
 };

	cordova.addConstructor(function() {
		if(!window.plugins) window.plugins = {};
		window.plugins.allphotos = new AllPhotos();
	});

})(window.cordova || window.Cordova);
});
