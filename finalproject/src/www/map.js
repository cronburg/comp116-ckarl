var map = null;
var pointArray = null;
var heatmap = null;
var map_data = null;
var refresh_interval = null;
var shapes = [];

function default_rectangle() {
	var bounds = new google.maps.LatLngBounds(
		new google.maps.LatLng(44.490, -78.649),
		new google.maps.LatLng(44.599, -78.443)
	);
	return new google.maps.Rectangle({
		bounds: bounds,
		editable: true,
		draggable: true
	});
}

function new_rectangle() {
	console.log('Inside new_rectangle()');
	var rect = default_rectangle();
	rect.setMap(map);
	shapes.push(rect);
}

function new_circle() {
	console.log('Inside new_circle()');
}

function submit_list(type) {
	console.log('Inside submit_list('+type+')');
	
	var shapes_array = new Array();
	for (i = 0; i < shapes.length; i++) {
		b = shapes[i].bounds;
		e = [b.ea.b, b.ea.d, b.fa.b, b.fa.d];
		shapes_array.push(e);
	}
	$.ajax({
		type: "POST",
		url: "/comp116/submit_list.php",
		contentType: "application/json; charset=utf-8",
		data: JSON.stringify(shapes_array),
		success: function(data) { console.log('Success: '+data); }
	})

}

function update_refresh(value) {
	console.log('Updating refresh interval to ' + value + ' milliseconds.');
	clearInterval(refresh_interval);
	refresh_interval = setInterval(function(){ update_map(map) }, value);	 
}

// Blue-Purple-Red Gradient:
function setGradient(heatmap) {
	var gradient = [
	'rgba(0, 255, 255, 0)',
	'rgba(0, 255, 255, 1)',
	'rgba(0, 191, 255, 1)',
	'rgba(0, 127, 255, 1)',
	'rgba(0, 63, 255, 1)',
	'rgba(0, 0, 255, 1)',
	'rgba(0, 0, 223, 1)',
	'rgba(0, 0, 191, 1)',
	'rgba(0, 0, 159, 1)',
	'rgba(0, 0, 127, 1)',
	'rgba(63, 0, 91, 1)',
	'rgba(127, 0, 63, 1)',
	'rgba(191, 0, 31, 1)',
	'rgba(255, 0, 0, 1)'
	]
	heatmap.setOptions({
		gradient: gradient
	});
}

function update_map(map) {
	
	/* Retrieve latest Lat/Lng data */	
	req = new XMLHttpRequest();
	var locn = "/comp116/get_data.php"; /* location.hostname */
	req.open("POST", locn, false);
	req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
	var encoded = "t=" + escape(Math.round(Date.now()/1000));
	req.send(encoded);
	if (req.status != 200) {
		alert("Communication error: " + req.responseText);
		return;
	}
	var data = req.responseText.split("\n");

	/* Parse Lat/Lng data into google.maps.LatLng objects */
	map_data = new Array(data.length-1);
	var pair, lat, lng;
	for (i = 0; i < data.length-1; i++) {
		pair = data[i].split(",");
		lat = parseFloat(pair[0]); lng = parseFloat(pair[1]);
		map_data[i] = new google.maps.LatLng(lat, lng);
	}

	/* Prepare Heatmap */
	pointArray = new google.maps.MVCArray(map_data);
	var heatmap2 = new google.maps.visualization.HeatmapLayer({
		data: pointArray
	});
	heatmap2.setMap(map);
	heatmap2.setOptions({radius: 20});
	setGradient(heatmap2);

	/* Remove previous heatmap: */
	if (heatmap != null) heatmap.setMap(null);
	heatmap = heatmap2;
	
}

function initialize() {
	var mapOptions = {
		//zoom: 13,
		zoom: 2,
		center: new google.maps.LatLng(42.38759994506836, -71.09950256347656),
		mapTypeId: google.maps.MapTypeId.ROADMAP
	};
	map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);
	update_map(map);
	
	// Update the map once every 1000 ms
	refresh_interval = setInterval(function(){ update_map(map) }, 10000);	 

}

google.maps.event.addDomListener(window, 'load', initialize);
google.maps.visualRefresh = true;


