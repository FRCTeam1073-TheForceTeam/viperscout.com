"use strict"

$.ajaxSetup({
	cache: true
})

$(document).ready(function(){
	$.getScript("/local.js", window.onLocalJs)
	if (!inIframe()){
		var hamburger = $('<div id=hamburger class=show-only-when-connected>☰</div>'),
		mainMenu = $('<div id=mainMenu class=lightBoxCenterContent>')
		$('body').append(hamburger).append(mainMenu)
		hamburger.click(function(){showLightBox(mainMenu)})

		populateMainMenu()

		function populateMainMenu(){
			var isStats = /stats/.test(location.href),
			menu=(isStats?"//viperscout.com":"")+"/main-menu.html"
			$.get(menu,function(data){
				if (isStats) data = data.replace(/href\=\//g,"href=//viperscout.com/")
				mainMenu.html(data)
			})
		}
		$('body').append($('<div id=lightBoxBG>').click(closeLightBox)).on('keyup',function(e){
			if (e.key=='Escape' && $('#lightBoxBG').is(":visible")){
				e.preventDefault()
				closeLightBox()
			}
		})
	}
})

function closeLightBox(){
	$('#lightBoxBG,.lightBoxCenterContent,.lightBoxFullContent').hide()
}

function showLightBox(content){
	closeLightBox()
	$('#lightBoxBG').show()
	content.show()
}

function inIframe(){
	try {
		return window.self !== window.top
	} catch (e) {
		return true
	}
}
