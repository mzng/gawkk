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

// forms
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


// video
var consumesGroupedActivity = true;

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
		
		if($('short_description_for_' + videoId + containerId) && $('short_description_for_' + videoId + containerId).style.display == 'none') {
			$('full_description_for_' + videoId + containerId).hide();
			$('short_description_for_' + videoId + containerId).show();
		}
		
		if($('share_for_' + videoId + containerId).style.display != 'none') {
			Effect.BlindUp('share_for_' + videoId + containerId, { duration: 0.3 });
			
			if($('more_link_arrow_for_' + videoId + containerId)) {
				$('more_link_arrow_for_' + videoId + containerId).src = '/images/menu-arrow.png';
			}
		}
		
		if(consumesGroupedActivity == true) {
			if($('new_comment_for_' + videoId + containerId) && $('new_comment_area_for_' + videoId + containerId).value == '') {
				$('new_comment_for_' + videoId + containerId).remove();
			}
		} else {
			if($('activity_for_' + videoId + containerId)) {
				$('activity_for_' + videoId + containerId).update('');
			}
		
			if($('reply_link_for_' + videoId + containerId)) {
				$('reply_link_for_' + videoId + containerId).remove();
			}
		
			if($('new_comment_for_' + videoId + containerId) && $('new_comment_area_for_' + videoId + containerId).value == '') {
				$('new_comment_for_' + videoId + containerId).remove();
			
				if($('comment_container_for_' + videoId + containerId)) {
					$('comment_container_for_' + videoId + containerId).update('');
				}
			}
		}
		
	} else {
		new Ajax.Request('/' + videoSlug + '/watch?container_id=' + containerId, {asynchronous:true, evalScripts:false, onLoading:function(request){
				work(videoId, containerId);
			}, onComplete:function(request){	
				rest(videoId, containerId);
				
				Effect.BlindDown('embed_for_' + videoId + containerId, { duration: 0.5 });
				
				if(scroll) {
					Effect.ScrollTo('video_' + videoId + containerId, {offset: -5});
					
					if(typeof pageTracker != 'undefined') {
						pageTracker._trackPageview("/watched-video");
					}
				}
				
				if(consumesGroupedActivity == true) {
					showAllCommentsFor(videoId, containerId);
					
	        if(!$('new_comment_for_' + videoId + containerId)) {
	          commentAndFocus(videoId, videoSlug, '!AUTO', false, containerId);
	        }
				} else {
					reloadActivity(videoId, containerId);
					
					if(!$('new_comment_for_' + videoId + containerId)) {
						reloadCommentsAndComment(videoId, videoSlug, true, false, containerId);
					}
				}
			}}
		);
	}
}

function readMore(videoId, containerId) {
	if($('short_description_for_' + videoId + containerId)) {
		$('short_description_for_' + videoId + containerId).hide();
		$('full_description_for_' + videoId + containerId).show();
	}
}

function read(videoId, videoSlug, containerId) {
	readMore(videoId, containerId);
	if($('embed_for_' + videoId + containerId).style.display == 'none') {
		watchVideo(videoId, videoSlug, containerId);
	}
}

function watchYouTubeVideo(youTubeUnqiueId) {
	var embed_code = "<object width=\"425\" height=\"350\"><param name=\"movie\" value=\"http://www.youtube.com/v/" + youTubeUnqiueId + "\"></param><param name=\"wmode\" value=\"transparent\"></param><embed src=\"http://www.youtube.com/v/" + youTubeUnqiueId + "\" type=\"application/x-shockwave-flash\" wmode=\"transparent\" width=\"425\" height=\"350\"></embed></object>"
	
	if($('embed_for_youtube_video_' + youTubeUnqiueId).style.display != 'none') {
		$('embed_for_youtube_video_' + youTubeUnqiueId).hide();
	} else {
		$('embed_code_for_youtube_video_' + youTubeUnqiueId).update(embed_code);
		Effect.BlindDown('embed_for_youtube_video_' + youTubeUnqiueId, { duration: 0.5 });
		Effect.ScrollTo('youtube_video_' + youTubeUnqiueId, {offset: 5});
	}
}


// activity
function reloadActivity(videoId, containerId) {
	if(typeof baseUser != 'undefined' && typeof includeFollowings != 'undefined') {
		var q = '?base_user=' + baseUser + '&include_followings=' + includeFollowings + '&container_id=' + containerId;
		
		new Ajax.Request('/videos/reload_activity/' + videoId + q, {method:'get', asynchronous:true, evalScripts:false, onLoading:function(request){
				work(videoId, containerId);
			}, onComplete:function(request){
				rest(videoId, containerId);
			}}
		);
	} else {
		rest(videoId, containerId);
	}
}


// comments
function showAllCommentsFor(videoId, containerId) {
	if($('show_all_comments_for_' + videoId + containerId)) {
		$('show_all_comments_for_' + videoId + containerId).hide();
	}
	
	comments = $$('#video_' + videoId + containerId + ' .hidden');
	for(i = 0; i < comments.length; i++) {
		comments[i].removeClassName('hidden');
	}
}

function reloadComments(videoId, containerId) {
	reloadCommentsAndComment(videoId, null, false, false, containerId);
}

function reloadCommentsAndComment(videoId, videoSlug, comment, focus, containerId) {
	if(typeof baseUser != 'undefined' && typeof includeFollowings != 'undefined') {
		var q = '?base_user=' + baseUser + '&include_followings=' + includeFollowings + '&container_id=' + containerId;
		
		new Ajax.Request('/videos/reload_comments/' + videoId + q, {method:'get', asynchronous:true, evalScripts:false, onLoading:function(request){
				work(videoId, containerId);
			}, onComplete:function(request){
				rest(videoId, containerId);

				if(comment == true && !$('new_comment_for_' + videoId + containerId)) {
					commentAndFocus(videoId, videoSlug, '!AUTO', focus, containerId);
				}
			}}
		);
	} else if(comment == true) {
		commentAndFocus(videoId, videoSlug, '!AUTO', focus, containerId);
	}
}

function comment(videoId, videoSlug, replyId, containerId) {
	commentAndFocus(videoId, videoSlug, replyId, true, containerId);
}

function commentAndFocus(videoId, videoSlug, replyId, focus, containerId) {
	if($('new_comment_for_' + videoId + containerId)) {
		$('new_comment_for_' + videoId + containerId).remove();
	}
	
	var q = '';
	if(replyId == '!AUTO') {
		if($('last_comment_id_for_' + videoId + containerId) && $('last_comment_id_for_' + videoId + containerId).value != '') {
			q = "?reply_id=" + $('last_comment_id_for_' + videoId + containerId).value + '&explicit_reply=false' + '&container_id=' + containerId;
		} else {
			q = "?container_id=" + containerId;
		}
	} else if(replyId != null) {
		q = "?reply_id=" + replyId + '&explicit_reply=true' + '&container_id=' + containerId;
	} else {
		q = "?container_id=" + containerId;
	}

	new Ajax.Request('/' + videoSlug + '/comment' + q, {method:'get', asynchronous:true, evalScripts:false, onLoading:function(request){
			work(videoId, containerId);
		}, onComplete:function(request){
			rest(videoId, containerId);

			if(focus == true) {
				$('placeholder_comment_for_' + videoId + containerId).hide();
				
				Effect.BlindDown('actual_comment_for_' + videoId + containerId, {duration: 0.3, afterFinish: function(){
					$('new_comment_area_for_' + videoId + containerId).focus();
					$('new_comment_area_for_' + videoId + containerId).value = $('new_comment_area_text_for_' + videoId + containerId).value;
				}});
			}
		}}
	);
}

function updateCharacterCount(commentableId, field, containerId) {
	var charactersLeft = 140 - field.value.length;
	
	var tweetIt = $('tweet_it_for_' + commentableId + containerId);
	if(tweetIt != null && tweetIt.checked) {
		charactersLeft = charactersLeft - 26;
	}
	
	$('characters_left_for_' + commentableId + containerId).update(charactersLeft);
	
	if(charactersLeft < 0) {
		$('submit_button_for_' + commentableId + containerId).disable();
		$('characters_left_for_' + commentableId + containerId).addClassName('over-limit');
	} else {
		$('submit_button_for_' + commentableId + containerId).enable();
		$('characters_left_for_' + commentableId + containerId).removeClassName('over-limit');
	}
}

function revealActualCommentForm(commentableId, containerId) {
	$('placeholder_comment_for_' + commentableId + containerId).hide();
	
	Effect.BlindDown('actual_comment_for_' + commentableId + containerId, {duration: 0.3, afterFinish: function(){
		$('new_comment_area_for_' + commentableId + containerId).focus();
		$('new_comment_area_for_' + commentableId + containerId).value = $('new_comment_area_text_for_' + commentableId + containerId).value;
	}});
}

function revealPlaceholderCommentForm(commentableId, containerId) {
	if($('new_comment_area_for_' + commentableId + containerId) && $F('new_comment_area_for_' + commentableId + containerId) == '') {
		$('actual_comment_for_' + commentableId + containerId).hide();
		$('placeholder_comment_for_' + commentableId + containerId).show();
	}
}

// thumbnail search
function setThumbnail(videoId, containerId, thumbnailUrl) {
	if($('thumbnail_for_video_' + videoId + containerId) != null) {
		$('thumbnail_for_video_' + videoId + containerId).value = thumbnailUrl;
	}
	
	if($('thumbnail_for_video_' + videoId + containerId + '_container') != null) {
		$('thumbnail_for_video_' + videoId + containerId + '_container').style.backgroundImage = 'none';
		$('thumbnail_for_video_' + videoId + containerId + '_preview').src = thumbnailUrl;
	}
	
	if($('loading_selected_thumbnail_' + videoId + containerId) != null) {
		$('loading_selected_thumbnail_' + videoId + containerId).style.visibility = 'visible';
		window.setTimeout(function(){$('loading_selected_thumbnail_' + videoId + containerId).style.visibility = 'hidden';}, 2500);
	}
	
	hideOverlay();
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

// registration overlay
function chooseService(serviceName, focusField) {
	var serviceSelecors = $$('.service');
	for(i = 0; i < serviceSelecors.length; i++) {
		serviceSelecors[i].removeClassName('selected-service');
	}
	
	var serviceForms = $$('.signup_form');
	for(i = 0; i < serviceForms.length; i++) {
		serviceForms[i].hide();
	}
	
	$(serviceName + '-selector').addClassName('selected-service');
	$(serviceName + '-form').appear({duration: .2, afterFinish: function(){if(focusField != '') {$(focusField).focus();}}});
}

function checkValidity(fields, objectType) {
	var valid = true;
	
	for(i = 0; i < fields.length; i++) {
		if($F('valid_' + fields[i]) == 'false') {
			$(objectType + '_' + fields[i]).style.border = '1px solid red';
			valid = false;
		} else {
			$(objectType + '_' + fields[i]).style.border = '1px solid #999999';
		}
	}
	
	return valid;
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

// suggestions
function selectUsers(selected) {
	var users = $$('.user_selector');
	
	for(i = 0; i < users.length; i++) {
		if(selected.checked == true) {
			users[i].checked = 'checked';
		} else {
			users[i].checked = '';
		}
	}
}

function selectChannels(selected) {
	var channels = $$('.channel_selector');
	
	for(i = 0; i < channels.length; i++) {
		if(selected.checked == true) {
			channels[i].checked = 'checked';
		} else {
			channels[i].checked = '';
		}
	}
}

// contact importer
function allowLoginOrShowMessage(importable) {
	if(importable == false) {
		$('importable').hide();
		$('not-importable').show();
	} else {
		$('not-importable').hide();
		$('importable').show();
	}
}

function hideErrorMessage() {
	new Effect.Opacity('error-message', { from: 1.0, to: 0, duration: 0.5 });
}

function selectContacts(selected) {
	var contacts = $$('.contact_selector');
	
	for(i = 0; i < contacts.length; i++) {
		if(selected.checked == true) {
			contacts[i].checked = 'checked';
		} else {
			contacts[i].checked = '';
		}
	}
}

// facebook
function fbs_click(u) {
	window.open('http://www.facebook.com/sharer.php?u='+encodeURIComponent(u),'sharer','toolbar=0,status=0,width=626,height=436');
	return false;
}