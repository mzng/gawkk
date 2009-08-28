// Facebook Integration
function adjustFrameHeight() {
	FB_RequireFeatures(["CanvasUtil"], function(){
    FB.XdComm.Server.init('/xd_receiver.htm');
    FB.CanvasClient.startTimerToSizeToContent();
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

function watchVideo(videoId, videoSlug, containerId) {
	watchVideoAndScroll(videoId, videoSlug, true, containerId)
}

function watchVideoAndScroll(videoId, videoSlug, scroll, containerId) {
	if($('embed_for_' + videoId + containerId).style.display != 'none') {
		$('embed_for_' + videoId + containerId).hide();
		$('embed_for_' + videoId + containerId).update('');
	} else {
		new Ajax.Request('/' + videoSlug + '/watch?container_id=' + containerId, {asynchronous:true, evalScripts:false, onLoading:function(request){
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