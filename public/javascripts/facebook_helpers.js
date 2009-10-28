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

// subscriptions
function openSubscriptions() {
	if($('subscription-bookmarks').style.display == 'none') {
		new Effect.BlindDown('subscription-bookmarks', {duration: 0.2});
	} else {
		new Effect.BlindUp('subscription-bookmarks', {duration: 0.2});
	}
}

// Facebook Integration
function setupFacebook() {
	FB_RequireFeatures(["XFBML","CanvasUtil"], function(){
		FB.Facebook.init("093158e95304546cd3277069c250b15b", "/xd_receiver.htm");
    FB.XdComm.Server.init('/xd_receiver.htm');
    FB.CanvasClient.startTimerToSizeToContent();
		FB.CanvasClient.syncUrl();
		FB.CanvasClient.scrollTo(0,0);
  });
}

function streamPublish(videoId, containerId, videoUrl, title, description, thumbnailUrl) {
	var attachment = {'name':title,'description':description,'href':videoUrl,'media':[{'type':'image','src':thumbnailUrl,'href':videoUrl}]};
	FB.Connect.streamPublish('', attachment);
	
	var y = Element.cumulativeOffset($('video_' + videoId + containerId))[1] + 'px';
	$('RES_ID_fb_pop_dialog_table').style.top = y;
	FB.CanvasClient.scrollTo(0, y);
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
				
				Effect.BlindDown('embed_for_' + videoId + containerId, {duration: 0.5});
				
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

function more(videoId, containerId) {
	if($('more_for_' + videoId + containerId).style.display != 'none') {
		Effect.BlindUp('more_for_' + videoId + containerId, {duration: 0.1});
	} else {
		Effect.BlindDown('more_for_' + videoId + containerId, {duration: 0.1});
	}
}

// Comments
function showAllCommentsFor(videoId, containerId) {
	if($('show_all_comments_for_' + videoId + containerId)) {
		$('show_all_comments_for_' + videoId + containerId).hide();
	}
	
	comments = $$('#video_' + videoId + containerId + ' .hidden');
	for(i = 0; i < comments.length; i++) {
		comments[i].removeClassName('hidden');
	}
}

function openCommentArea(commentableId, containerId) {
	$('placeholder_comment_container_for_' + commentableId + containerId).hide();
	
	$('actual_comment_container_for_' + commentableId + containerId).show();
	$('post_container_for_' + commentableId + containerId).show();
	
	$('new_comment_text_for_' + commentableId + containerId).focus();
}

function autoResize(fieldId) {
	var str = $(fieldId).value;
	var cols = $(fieldId).cols;
	var rows = Math.floor(str.length / cols) + 1;
	
	if(str.length > 0 && rows > 1) {
		$(fieldId).rows = rows;
	} else {
		$(fieldId).rows = 2;
	}
}

function reloadComments(videoId, containerId, sessionId) {
	reloadCommentsAndComment(videoId, null, false, false, containerId, sessionId);
}

function reloadCommentsAndComment(videoId, videoSlug, comment, focus, containerId, sessionId) {
	if(typeof baseUser != 'undefined' && typeof includeFollowings != 'undefined') {
		var q = '?base_user=' + baseUser + '&include_followings=' + includeFollowings + '&container_id=' + containerId + '&_session_id=' + sessionId;
		
		new Ajax.Request('/videos/reload_comments/' + videoId + q, {method:'get', asynchronous:true, evalScripts:false, onLoading:function(request){
				work(videoId, containerId);
			}, onComplete:function(request){
				rest(videoId, containerId);

				if(comment == true && !$('new_comment_for_' + videoId + containerId)) {
					commentAndFocus(videoId, videoSlug, '!AUTO', focus, containerId, sessionId);
				}
			}}
		);
	} else if(comment == true) {
		commentAndFocus(videoId, videoSlug, '!AUTO', focus, containerId, sessionId);
	}
}

function comment(videoId, videoSlug, replyId, containerId, sessionId) {
	commentAndFocus(videoId, videoSlug, replyId, true, containerId, sessionId);
}

function commentAndFocus(videoId, videoSlug, replyId, focus, containerId, sessionId) {
	if($('new_comment_for_' + videoId + containerId)) {
		$('new_comment_for_' + videoId + containerId).remove();
	}
	
	var q = '';
	if($('last_comment_id_for_' + videoId + containerId) && $('last_comment_id_for_' + videoId + containerId).value != '') {
		q = "?reply_id=" + $('last_comment_id_for_' + videoId + containerId).value + '&explicit_reply=false' + '&container_id=' + containerId + '&_session_id=' + sessionId;
	} else {
		q = "?container_id=" + containerId + '&_session_id=' + sessionId;
	}

	new Ajax.Request('/' + videoSlug + '/comment' + q, {method:'get', asynchronous:true, evalScripts:false, onLoading:function(request){
			work(videoId, containerId);
		}, onComplete:function(request){
			rest(videoId, containerId);

			if(focus == true) {
				openCommentArea(videoId, containerId);
			}
		}}
	);
}

// Activity
function reloadActivity(videoId, containerId, sessionId) {
	if(typeof baseUser != 'undefined' && typeof includeFollowings != 'undefined') {
		var q = '?base_user=' + baseUser + '&include_followings=' + includeFollowings + '&container_id=' + containerId;
		
		new Ajax.Request('/videos/reload_activity/' + videoId + q + '&_session_id=' + sessionId, {method:'get', asynchronous:true, evalScripts:false, onLoading:function(request){
				work(videoId, containerId);
			}, onComplete:function(request){
				rest(videoId, containerId);
			}}
		);
	} else {
		rest(videoId, containerId);
	}
}

// Facebook share button
function fbs_click(u) {
	window.open('http://www.facebook.com/sharer.php?u='+encodeURIComponent(u),'sharer','toolbar=0,status=0,width=626,height=436');
	return false;
}