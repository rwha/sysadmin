// window.RT already declared
RT.rtnot = RT.rtnot || {};

function enableNotifications() {
	if(!("Notification" in window)) {
		console.log('notifications not supported');
	} else if (Notification.permission !== 'denied') {
		Notification.requestPermission(function(perm) {
			if(perm === "granted") {
				console.log('notifications enabled.');
			}
		});
	}
}

function notify(count){
	var title;
	var options = {
	  tag: 'new-unseen-tickets',
	  body: window.location.href,
	  icon: '/info/logo.png'
	}; 
	if(count === 1 && RT.rtnot && RT.rtnot.tx) {
		title = RT.rtnot.tx[RT.rtnot.tx.length-1].split(':')[1];
	} else {
		title = 'There are ' + count + ' new tickets';
	}

	var n = new Notification(title, options);
	n.addEventListener('click', function(e) {
		window.focus();
		this.close();
	});
}

function getTickets() {
	var url = "/rt/REST/1.0/search/ticket?query=Owner+%3D+%27Nobody%27+AND+Status+%3D+%27new%27+AND+Queue+%3D+%27Help+Desk%27";
	fetch(url, { credentials: 'include' })
		.then(r => r.text())
		.then(function(t) {
			var tx = t.split("\n");
			var ntx = tx.filter(function(e){
					return e.match(/^[0-9]{5}.*/);
				});
			if (!RT.rtnot.tx) {
				RT.rtnot.tx = ntx || [];
				return;
			} else if (ntx.length > RT.rtnot.tx.length) {
				let lg = (ntx.length - RT.rtnot.tx.length);
				RT.rtnot.tx = ntx || [];
				notify(lg);
			}
		});
}

document.addEventListener('DOMContentLoaded',function() {
	if(RT.CurrentUser.Name === "XXX") {  // if(RT && RT.CurrentUser && RT.CurrentUser.Privileged) {
		enableNotifications();
		getTickets();
		window.setInterval(getTickets, 60000);
	}
}, false);
