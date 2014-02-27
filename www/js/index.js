/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
var app = {
    // Application Constructor
    initialize: function() {
        this.bindEvents();
    },
    // Bind Event Listeners
    //
    // Bind any events that are required on startup. Common events are:
    // 'load', 'deviceready', 'offline', and 'online'.
    bindEvents: function() {
        document.addEventListener('deviceready', this.onDeviceReady, false);
    },
    // deviceready Event Handler
    //
    // The scope of 'this' is the event. In order to call the 'receivedEvent'
    // function, we must explicity call 'app.receivedEvent(...);'
    onDeviceReady: function() {
        app.receivedEvent('deviceready');
        
       
        plugins.ipaddress.get(function(ip){
            LocalIPAddress = ip;
            $('#IPAddressLabel').html(ip);
        },fail);
        
        GetLocalStreamStashBoxes();
            
        //plugins.allphotos.get(function(pics){
          //                      alert(JSON.stringify(pics));
        //});
    },
    // Update DOM on a Received Event
    receivedEvent: function(id) {
        /*var parentElement = document.getElementById(id);
        var listeningElement = parentElement.querySelector('.listening');
        var receivedElement = parentElement.querySelector('.received');

        listeningElement.setAttribute('style', 'display:none;');
        receivedElement.setAttribute('style', 'display:block;');

        console.log('Received Event: ' + id); */
    }
    
};

var SelectedIP = '10.0.0.3';
var LocalIPAddress;
function ShowPictureViewer(){
 	window.requestFileSystem(LocalFileSystem.TEMPORARY, 0, function(fileSystem){ // this returns the tmp folder
        var reader = fileSystem.root.createReader();
	    reader.readEntries(function(entries) {
	
	        var i;
	        for (i = 0; i < entries.length; i++) {
	            if (entries[i].name.toLowerCase().indexOf(".png") != -1 || entries[i].name.toLowerCase().indexOf(".jpg") != -1 || entries[i].name.toLowerCase().indexOf(".mov") != -1) {
                   entries[i].remove(function(success){
	                    console.log(success);
	                }, function(error){
	                    console.error("deletion failed: " + error);
	                });
	            }
	        }
	        
	        navigator.camera.getPicture(onSuccess, fail, {
               quality: 20,
               destinationType: Camera.DestinationType.FILE_URI,
               sourceType : Camera.PictureSourceType.PHOTOLIBRARY,
               mediaType: Camera.MediaType.ALLMEDIA
            });
	        
	    }, fail);  
	});
}

var URI;
var fileSystem;
function onSuccess(imageURI) {
    URI = imageURI.split('/tmp/')[1];
    //alert(imageURI);
    if(URI.toLowerCase().indexOf('.jpg') != -1 || URI.toLowerCase().indexOf('.png') != -1){
    	$('#Holder').html('<img style="max-height:100%; max-width:100%;" src="' + imageURI + '">');
        $.get('http://' + SelectedIP + ':9996/index.html?play=image&path=http://' + LocalIPAddress + ':12345/' + URI.replace('//', '/'));
    }
    else{
        $('#Holder').html('<video src="' + imageURI + '" controls></video>');
        $.get('http://' + SelectedIP + ':9996/index.html?play=video&path=http://' + LocalIPAddress + ':12345/' + URI.replace('//', '/'));
    }
    
    window.requestFileSystem(LocalFileSystem.TEMPORARY, 0, function(fileSystem){ // this returns the tmp folder                  
        fileSystem.root.getFile("index.html", {create: true}, function(fileEntry){
            fileEntry.createWriter(function(writer){
                var text = WriteHomePage();
            	writer.write(text);
            }, fail);
        }, fail);
    }, fail);
}


//Get StreamStash boxes
function GetLocalStreamStashBoxes(){
    $.get('http://access.streamstash.com/server/API/Basic/get_local_streamboxes.php', function(boxes){
          boxes = $.parseJSON(boxes).result;
          var html = '';
          for(var i in boxes){
	          html += '<div class="boxOption" onclick="SelectBox(this);" data-ip="' + boxes[i].local_ip + '">' + boxes[i].machine_name + ' <span>' + boxes[i].local_ip + '</span><span class="arrowRight"><i class="icon-chevron-right"></i></span></div>';
          }
          $('#BoxOptions').html(html);
    });
}

//Gets targets that have connected to the app
function GetBrowserTargets(){
	//read from temp directory
	window.requestFileSystem(LocalFileSystem.TEMPORARY, 0, function(fileSystem){ // this returns the tmp folder                  
        fileSystem.root.getFile("aMachines", {create: false}, function(fileEntry){
        	var reader = new FileReader();
            reader.onloadend = function (evt) {
		        var res = evt.target.result;
		        //parse results
		    };
		    reader.readAsText(file);
        }, fail);
    }, fail);
}

function fail(message) {
    alert('Failed because: ' + message);
}

function success(entries) {
    var i;
    for (i=0; i<entries.length; i++) {
        console.log(entries[i].name);
    }
}

function WriteHomePage(){
    var html = '<html>'+
    '<head>'+
    '<title>iPhone Content Server</title>'+
    '</head>'+
    '<body bgcolor="#FFFFFF">';
    if(URI.toLowerCase().indexOf('.jpg') != -1 || URI.toLowerCase().indexOf('.png') != -1)
    	html += '<img style="max-height:100%; max-width:100%;" src="' + URI + '">';
    else
        html += '<video src="' + URI + '" controls></video>';
       
    html += '</body></html>';
    
    return html;
}

function ToggleLeftPane(){
	if($('#MainPanel').hasClass('open'))
		$('#MainPanel').removeClass('open');
	else
		$('#MainPanel').addClass('open');
}

function SelectBox(elem){
	SelectedIP = $(elem).attr('data-ip');
	$('#MainPanel').removeClass('open');
}
