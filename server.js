var os = require('os');
var http = require('http');
var port = (process.argv[2] ? process.argv[2] : 9090);

var server = http.createServer(function(req, res) {
        req.on('data', function(data) {
                console.log(data);
        });
        req.on('end', function() {
                var response = {};
                response.host = os.hostname();
                response.ostype = os.type();
                response.up = os.uptime();
                response.load = os.loadavg();
                response.ram = os.totalmem();
                response.free = os.freemem();
                response.cpu = os.cpus();
                res.writeHead(200, 'OK', {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'});
                res.end(JSON.stringify(response));
        });
});
server.listen(port);
