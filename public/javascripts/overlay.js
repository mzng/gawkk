function displayOverlayWithOffset(height, width, offset) {
	hideOverlay();
	
	var scrollY = 0;
	var top = 0;
	var viewportHeight = 0;
	var viewportWidth = 960;
	
	if(typeof(window.innerWidth) == 'number') {
		viewportHeight = window.innerHeight;
    viewportWidth = window.innerWidth;
  } else if(document.documentElement && (document.documentElement.clientWidth || document.documentElement.clientHeight)) {
		viewportHeight = document.documentElement.clientHeight;
    viewportWidth = document.documentElement.clientWidth;
  } else if(document.body && (document.body.clientWidth || document.body.clientHeight)) {
		viewportHeight = document.body.clientHeight;
    viewportWidth = document.body.clientWidth;
	}
	
	if(document.documentElement && document.documentElement.scrollTop)
      scrollY = document.documentElement.scrollTop;
  else if(document.body && document.body.scrollTop)
      scrollY = document.body.scrollTop;
  else if(window.pageYOffset)
      scrollY = window.pageYOffset;
  else if(window.scrollY)
      scrollY = window.scrollY;
	
	top = (viewportHeight / 2 + scrollY);
	
	// Make sure the overlay is visible in the current viewport
	top = (top - ((height + 12) / 2)) + offset;
	if(top < scrollY) {
		top = scrollY + 10;
	} else if(top + height > scrollY + viewportHeight) {
		top = scrollY + viewportHeight - height - 10;
	}
	
	$('overlay').style.height		= (height + 12) + 'px';
	$('overlay').style.width		= (width + 12) + 'px';
	$('overlay').style.left			= ((viewportWidth / 2) - ((width + 12) / 2)) + 'px';
	$('overlay').style.top			= top + 'px';
	$('overlay').style.display	= 'block';
	// Effect.Appear('overlay', { duration: 0.5 });
	
	$('overlayed-content').style.height	= height + 'px';
	$('overlayed-content').style.width	= width + 'px';
	// $('overlayed-content').src					= url;
	
	$('close').style.left			= ((viewportWidth / 2) + ((width + 12) / 2) - 18) + 'px';
	$('close').style.top			= (top - 12) + 'px';
	$('close').style.display	= 'inline';
}

function displayOverlay(height, width) {
	displayOverlayWithOffset(height, width, 0);
}

function hideOverlay() {
	$('close').style.display		= 'none';
	$('overlay').style.display	= 'none';
	$('overlayed-content').replace("<div id=\"overlayed-content\"></div>");
}

function resizeOverlay(height, width) {
	$('overlay').style.left		= (parseInt($('overlay').style.left) - ((width + 12) - parseInt($('overlay').style.width))) + 'px';
	$('overlay').style.height	= (height + 12) + 'px';
	$('overlay').style.width	= (width + 12) + 'px';
	
	$('overlayed-content').style.height	= height + 'px';
	$('overlayed-content').style.width	= width + 'px';
}