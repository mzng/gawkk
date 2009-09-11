// Common
function descriptiveField(field, description, focused) {
	if(focused) {
		if(field.value == description) {
			field.value = '';
			field.style.color = '#333333';
		}
	} else {
		if(field.value == '') {
			field.style.color = '#837d87';
			field.value = description;
		}
	}
}

// Facebook Integration
function adjustFrameHeight() {
	FB_RequireFeatures(["CanvasUtil"], function(){
    FB.XdComm.Server.init('/xd_receiver.htm');
    FB.CanvasClient.startTimerToSizeToContent();
		FB.CanvasClient.syncUrl();
		FB.CanvasClient.scrollTo(0,0);
  });
}

// Videos
function work(videoId, containerId) {
	if($('loading_for_' + videoId + containerId)) {
		$('popular_for_' + videoId + containerId).style.display = 'none';
		$('loading_for_' + videoId + containerId).style.display = 'inline';
	}
}

function rest(videoId, containerId) {
	if($('loading_for_' + videoId + containerId)) {
		$('loading_for_' + videoId + containerId).style.display = 'none';
		$('popular_for_' + videoId + containerId).style.display = 'inline';
	}
}

function watchVideo(videoId, videoSlug, containerId, sessionId) {
	watchVideoAndScroll(videoId, videoSlug, true, containerId, sessionId)
}

function watchVideoAndScroll(videoId, videoSlug, scroll, containerId, sessionId) {
	if($('embed_for_' + videoId + containerId).style.display != 'none') {
		$('embed_for_' + videoId + containerId).hide();
		$('embed_for_' + videoId + containerId).update('');
	} else {
		new Ajax.Request('/' + videoSlug + '/watch?container_id=' + containerId + '&_session_id=' + sessionId, {asynchronous:true, evalScripts:false, onLoading:function(request){
				work(videoId, containerId);
			}, onComplete:function(request){	
				rest(videoId, containerId);
				
				Effect.BlindDown('embed_for_' + videoId + containerId, { duration: 0.5 });
				
				if(scroll) {
					// Effect.ScrollTo('video_' + videoId + containerId, {offset: -5});
					
					// Google Anylytics tracking
					// if(typeof pageTracker != 'undefined') {
					// 	pageTracker._trackPageview("/watched-video");
					// }
				}
			}}
		);
	}
}