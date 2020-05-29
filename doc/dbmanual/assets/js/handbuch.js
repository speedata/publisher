var menuIsOpen = false;
$(document).ready(function() {
    toggleMobileNav('#pull', '#navi');
});

function toggleMobileNav(selectorPull, selectorNavi) {
    $(selectorPull).on('click', function(e) {
        e.preventDefault();
        $(selectorNavi).toggleClass("open");
    });
}

$(document).ready(function() {
	$('h1[id], h2[id]').each(function() {
		id = $(this).attr("id");
		$("<a class=\"anchorLink\" href=\"#"+id+"\">#</a>").prependTo($(this));
	});

	// scroll body to 0px on click
	$('#topButton').click(function () {
		$('body,html').animate({
			scrollTop: 0
		}, 500);
		return false;
	});

	$(window).scroll(function () {
		if ($(this).scrollTop() > 0) {
			$('#topButton').addClass("show");
		} else {
			$('#topButton').removeClass("show");
		}
	});

});
