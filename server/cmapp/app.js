/**
 * Module dependencies.
 */
var os = require('os');
console.log(getLocalAddress());

function getLocalAddress() {
    var ifacesObj = {}
    ifacesObj.ipv4 = [];
    ifacesObj.ipv6 = [];
    var interfaces = os.networkInterfaces();
    
    for (var dev in interfaces) {
        interfaces[dev].forEach(function(details){
                                if (!details.internal){
                                switch(details.family){
                                case "IPv4":
                                ifacesObj.ipv4.push({name:dev, address:details.address});
                                break;
                                case "IPv6":
                                ifacesObj.ipv6.push({name:dev, address:details.address})
                                break;
                                }
                                }
                                });
    }
    return ifacesObj.ipv4[0].address;
};


var express = require('express')
, http = require('http')
, path = require('path')
, io = require('socket.io')
, routes = require('./routes')
, favicon = require('serve-favicon')
, logger = require('morgan')
, methodOverride = require('method-override')
, session = require('express-session')
, bodyParser = require('body-parser')
, multer = require('multer')
, errorHandler = require('errorhandler');

var app = express()
, server = http.createServer(app)
, io = io.listen(server);

app.set('port', process.env.PORT || 3000);
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
//app.use(favicon(__dirname + '/public/favicon.ico'));
app.use(logger('dev'));
app.use(methodOverride());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: true}));
app.use(express.static(path.join(__dirname, 'public')));


if ('development' == app.get('env')){
    app.use(errorHandler());
}

server.listen(app.get('port'))

io.sockets.on('connection', function(socket) {
    socket.on('message:send', function(data) {
	io.sockets.emit('message:receive', { message: data.message });
    });
});
