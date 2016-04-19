var NAG = (function(){
	this.url = 'http://monitor.merion.com/nagios/cgi-bin/statusjson.cgi?query=';
	//var status = new Map();
	
	Object.size = function(obj) {
		var size = 0, key;
		for (key in obj) {
			if(obj.hasOwnProperty(key)) size++;
		}
		return size;
	}
	
	function make(el, val) {
		var node = document.createElement(el);
		if (val) node.innerHTML = val;
		return node;
	}

	function changes(o) {
		//console.log(o);
		var changed = false;
		var delta = new Map();
		for (var host in o) {
			delta.set(host, o[host]);
			if(!status.has(host)) changed = true;
		}
		delta.forEach(function(v,k){
			var sk = status.get(k)
			if (sk || JSON.stringify(v) !== JSON.stringify(sk)) changed = true;
			//console.log(JSON.stringify(v), sk);
		}, delta);
			//for (var service in o[host]) {
			//	delta[host][service] = o[host][service].plugin_output;
			//}
		//}
		//var changed = (JSON.stringify(delta) !== JSON.stringify(status));
		//console.log(delta, status);
		status = delta;
		return true; //changed;
	}
	
	function parse(o) {
		var i = 0;
		var data = o.data[o.result.query];
		//if (!changes(data)) 
		//	return;
		var main = document.getElementById('main');
		main.innerHTML = '';
		for (let host in data) {
			var div = make('div');
			div.appendChild(make('h2', host));
			var s = data[host];
			for (let svc in s) {
				i++;
				state = s[svc].last_hard_state;
				var pc = make('span', svc + ': ' + s[svc].plugin_output + '<br>');
				div.className = (state === 2) ? 'critical' : (state === 3) ? 'unknown' : 'warning';
				div.appendChild(pc);
			}
			main.appendChild(div);
		}
		document.title = "!:" + i;
	}
	
	function parseHelp(o) {
		document.getElementById('main').innerHTML = '';
		var options = o.data.options;
		var response = o.response;
		for (var option in options) {
			var c = options[option];
			var o = c.optional || [];
			var r = c.required || [];
			var v = c.valid_values || [];
			var div = make('div');
			var h = make('h2', option + '<i> ' + c.type + '</i>');
			var p = make('p', c.label + '<br>' + c.description + '<br>');
			
			if (r.length > 0) {
				if (r[0] === 'all') {
					h.className = 'required';
				} else {
					p.appendChild(make('b', '<br><span class="required">Required:</span>'));
					var u = make('ul');
					r.forEach(function(ro) { u.appendChild(make('li', ro)); });
					p.appendChild(u);
				}
			}
			
			if (o.length > 0) {
				p.appendChild(make('b', '<br>Optional:'));
				var u = make('ul');
				o.forEach(function(oo) { u.appendChild(make('li', oo)); });
				p.appendChild(u);
			}
		
			if(Object.size(v) > 0) {
				p.appendChild(make('b', '<br>Valid Values:'));
				var u = make('ul');
				for (var vv in v) {
					u.appendChild(make('li', "<b>" + vv + '</b>: ' + v[vv].description));
				}
				p.appendChild(u);
			}
			div.appendChild(h);
			div.appendChild(p);
			document.getElementById('main').appendChild(div);
		}
	}

	this.run = function() {
		var g = document.getElementById('group');
		var cmd = g.options[g.selectedIndex].value;
		if (cmd === 'help') {
			fetch(this.url + 'help').then(r => r.json()).then(parseHelp);
		} else {
			var opt = 'servicelist&servicestatus=critical%20warning%20unknown&details=true';
			fetch(this.url + opt).then(r => r.json()).then(parse);
			window.setTimeout(this.run, 60000);
		}
	}
	
	fetch(url + 'help').then(r => r.json()).then(parseHelp);
	
	return this.run;
	
})();