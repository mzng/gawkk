// common
function descriptiveField(field, description, focused) {
	if(focused) {
		if(field.value == description) {
			field.value = '';
			field.style.color = '#333';
		}
	} else {
		if(field.value == '') {
			field.style.color = 'gray';
			field.value = description;
		}
	}
}


// video
function work(videoId) {
	if($('loading_for_' + videoId)) {
		$('popular_for_' + videoId).style.display = 'none';
		$('loading_for_' + videoId).style.display = 'inline';
	}
}

function rest(videoId) {
	if($('loading_for_' + videoId)) {
		$('loading_for_' + videoId).style.display = 'none';
		$('popular_for_' + videoId).style.display = 'inline';
	}
}

function watchVideo(videoId, videoSlug) {
	watchVideoAndScroll(videoId, videoSlug, true)
}

function watchVideoAndScroll(videoId, videoSlug, scroll) {
	if($('embed_for_' + videoId).style.display != 'none') {
		$('embed_for_' + videoId).hide();
		
		if($('short_description_for_' + videoId) && $('short_description_for_' + videoId).style.display == 'none') {
			$('full_description_for_' + videoId).hide();
			$('short_description_for_' + videoId).show();
		}
		
		if($('new_comment_for_' + videoId) && $('new_comment_area_for_' + videoId).value == '') {
			$('new_comment_for_' + videoId).remove();
		}
	} else {
		new Ajax.Request('/' + videoSlug + '/watch', {asynchronous:true, evalScripts:false, onLoading:function(request){
				work(videoId);
			}, onComplete:function(request){	
				rest(videoId);
				
				Effect.BlindDown('embed_for_' + videoId, { duration: 0.5 });
				
				if(scroll) {
					Effect.ScrollTo('video_' + videoId, {offset: 5});
				}
				
				if(!$('new_comment_for_' + videoId)) {
					comment(videoId, videoSlug, '!AUTO');
				}
			}}
		);
	}
}

function readMore(videoId) {
	if($('short_description_for_' + videoId)) {
		$('short_description_for_' + videoId).hide();
		$('full_description_for_' + videoId).show();
	}
}


// activity
function reloadActivity(videoId) {
	if(typeof baseUser != 'undefined' && typeof includeFollowings != 'undefined') {
		var q = '?base_user=' + baseUser + '&include_followings=' + includeFollowings;
		
		new Ajax.Request('/videos/reload_activity/' + videoId + q, {method:'get', asynchronous:true, evalScripts:false, onLoading:function(request){
				work(videoId);
			}, onComplete:function(request){
				rest(videoId);
			}}
		);
	} else {
		rest(videoId);
	}
}


// comments
function reloadComments(videoId) {
	if(typeof baseUser != 'undefined' && typeof includeFollowings != 'undefined') {
		var q = '?base_user=' + baseUser + '&include_followings=' + includeFollowings;
		
		new Ajax.Request('/videos/reload_comments/' + videoId + q, {method:'get', asynchronous:true, evalScripts:false, onLoading:function(request){
				work(videoId);
			}, onComplete:function(request){
				rest(videoId);
			}}
		);
	} else {
		rest(videoId);
	}
}

function comment(videoId, videoSlug, replyId) {
	if($('new_comment_for_' + videoId)) {
		$('new_comment_for_' + videoId).remove();
	}
	
	var q = '';
	if(replyId == '!AUTO') {
		if($('last_comment_id_for_' + videoId) && $('last_comment_id_for_' + videoId).value != '') {
			q = "?reply_id=" + $('last_comment_id_for_' + videoId).value;
		}
	} else if(replyId != null) {
		q = "?reply_id=" + replyId;
	}

	new Ajax.Request('/' + videoSlug + '/comment' + q, {method:'get', asynchronous:true, evalScripts:false, onLoading:function(request){
			work(videoId);
		}, onComplete:function(request){
			rest(videoId);

			Effect.BlindDown('new_comment_for_' + videoId, { duration: 0.3, afterFinish: function(){$('new_comment_area_for_' + videoId).focus();} });
		}}
	);
}

function updateCharacterCount(commentableId, field) {
	var charactersLeft = 140 - field.value.length;
	$('characters_left_for_' + commentableId).update(charactersLeft);
	
	if(charactersLeft < 0) {
		$('submit_for_' + commentableId).disable();
		$('characters_left_for_' + commentableId).addClassName('over-limit');
	} else {
		$('submit_for_' + commentableId).enable();
		$('characters_left_for_' + commentableId).removeClassName('over-limit');
	}
}


// tips
function revealTip(fieldId) {
	revealTipWithOffset(fieldId, 0);
}

function revealTipWithOffset(fieldId, offset) {
	$('tip_arrow').style.top		= (Position.cumulativeOffset($(fieldId))[1]) + 'px';
	$('tip_arrow').style.visibility	= 'visible';
	$(fieldId + '_tip').style.top					= (Position.cumulativeOffset($(fieldId))[1] - 5 - offset) + 'px';
	$(fieldId + '_tip').style.visibility	= 'visible';
}

function hideTips() {
	$('tip_arrow').style.visibility = 'hidden';
	tips = $$('.tip');
	for(i = 0; i < tips.length; i++) {
		if(tips[i].hasClassName('delay-hide') && tips[i].style.visibility == 'visible') {
			setTimeout('hide(\'' + tips[i].id + '\')', 100)
		} else {
			tips[i].style.visibility = 'hidden';
		}
	}
}

function hide(tipId) {
	$(tipId).style.visibility = 'hidden';
}


// service avatars
function selectServiceAvatar(container, service) {
	var serviceAvatars = $$('.service-avatar');
	
	for(i = 0; i < serviceAvatars.length; i++) {
		serviceAvatars[i].removeClassName('selected');
	}
	
	if($('use_service').value == service) {
		$('use_service').value = '';
		container.removeClassName('selected')
	} else {
		$('use_service').value = service;
		container.addClassName('selected')
	}
}