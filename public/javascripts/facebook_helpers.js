// Facebook Integration
function setupFacebook(announce, firstName, sessionId) {
	FB_RequireFeatures(["XFBML","CanvasUtil"], function(){
		FB.Facebook.init("3b73b34a3d750d20a4f4e86905459ad1", "/xd_receiver.htm");
    FB.XdComm.Server.init('/xd_receiver.htm');
    FB.CanvasClient.startTimerToSizeToContent();
		FB.CanvasClient.syncUrl();
		FB.CanvasClient.scrollTo(0,0);
		
		if(announce == true) {
			announceInstallationFor(firstName);
			new Ajax.Request('/facebook/announcement_proposed?_session_id=' + sessionId, {method:'get', asynchronous:true, evalScripts:false});
		}
  });
}

function announceInstallationFor(firstName) {
	var title;
	if(firstName != '') {
		title = firstName + " is now finding and sharing great videos with friends.";
	} else {
		title = "I'm now finding and sharing great videos with friends.";
	}
	
	var description = "Check out the latest funny and interesting videos at Gawkk, where you can find and share videos with your friends.";
	
	var appUrl = "http://apps.facebook.com/gawkkapp";
	var thumbnailUrl = "http://gawkk.com/images/logo-fb-announce-medium.png";
	
	var attachment = {'name':title,'description':description,'href':appUrl,'media':[{'type':'image','src':thumbnailUrl,'href':appUrl}]};
	var actionLinks = [{'text':'Learn','href':appUrl}];
	FB.Connect.streamPublish('', attachment, actionLinks);
}

function streamPublish(videoId, containerId, videoUrl, title, description, thumbnailUrl) {
	var attachment = {'name':title,'description':description,'href':videoUrl,'media':[{'type':'image','src':thumbnailUrl,'href':videoUrl}]};
	var actionLinks = [{'text':'Watch','href':videoUrl}];
	FB.Connect.streamPublish('', attachment, actionLinks);
	
	if($('RES_ID_fb_pop_dialog_table')) {
		var y = Element.cumulativeOffset($('video_' + videoId + containerId))[1] + 'px';
		$('RES_ID_fb_pop_dialog_table').style.top = y;
		FB.CanvasClient.scrollTo(0, y);
	}
}

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

// Forms
var currentFormId = null;

function disableForm(id) {
	currentFormId = id;
	
	$(currentFormId).hide();
	$(currentFormId + '_disabled').show();
}

function enableCurrentForm() {
	if(currentFormId != null) {
		$(currentFormId + '_disabled').hide();
		$(currentFormId).show();
		
		currentFormId = null;
	}
}

// Subscriptions
function openSubscriptions() {
	if($('subscription-bookmarks').style.display == 'none') {
		new Effect.BlindDown('subscription-bookmarks', {duration: 0.2});
	} else {
		new Effect.BlindUp('subscription-bookmarks', {duration: 0.2});
	}
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
	hideShareNudgers();
	
	if($('embed_for_' + videoId + containerId).style.display != 'none') {
		$('embed_for_' + videoId + containerId).hide();
		$('embed_for_' + videoId + containerId).update('');
	} else {
		new Ajax.Request('/' + videoSlug + '/watch?container_id=' + containerId + '&_session_id=' + sessionId, {asynchronous:true, evalScripts:false, onLoading:function(request){
				work(videoId, containerId);
			}, onComplete:function(request){	
				rest(videoId, containerId);
				
				Effect.BlindDown('embed_for_' + videoId + containerId, {duration: 0.5});
			}}
		);
	}
}

function hideShareNudgers() {
	var nudgers = $$('.share-nudger');
	for(i = 0; i < nudgers.length; i++) {
		nudgers[i].hide();
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