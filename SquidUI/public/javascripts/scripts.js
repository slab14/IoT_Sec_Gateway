var dockerHost = "";
const proxyurl = "https://cors-anywhere.herokuapp.com/";

var numContainers = 0;

function getConts() {
    var host = window.location.hostname;
    console.log(host);
    dockerHost="http://"+host+":4243";
    fetch(proxyurl+dockerHost+'/containers/json')
	.then(response => response.json())
	.then(data => {
	    console.log(data);
	    numContainers = data.length;
	    var contInfo=parseJSON(data);
	    drawContainers_parsed(contInfo);
	})
	.catch(err => console.error('An error occurred', err));
}

function drawContainer_learning(words) {
    var output="";
    output="<div class=\"box col-sx-3 rows\"><div class=\"containerImage\" id=\"0\">\
            <div class=\"front\"><span class=\"words\"</span>"+words+"</div></div></div>";
    $("#viewer").html(output);
}

function drawContainers_JSON(json) {
    var output="";
    for (var i=0; i<json.length; i++) {
	output+="<div class=\"box col-sx-3 rows\"><div class=\"containerImage\" id=\""+i+"\" onClick=\"getInfo(this)\">\
                 <div class=\"front\"><span class=\"words\"</span>"+json[i].Names[0]+"</div></div></div>";
    }
    $("#viewer").html(output);
}

function drawContainers_parsed(data) {
    var output="";
    for (var i=0; i<data.length; i++) {
	if (data[i].Type == "Proxy") {
	    output+="<div class=\"box col-sx-3 rows\"><div class=\"containerImage\" id=\""+data[i].Id+"\"> \
                     <button onclick=\"getInfo(this.parentNode)\">Get Users & Passwords</button> \
                     <button onclick=\"newPassword(this.parentNode)\">Update Users & Passwords</button> \
                     <div class=\"front\"><span class=\"words\"</span>"+data[i].Name+" \
                     </div></div></div>";
	} else {
	    output+="<div class=\"box col-sx-3 rows\"><div class=\"containerImage\" id=\""+data[i].Id+"\">\
                     <div class=\"front\"><span class=\"words\"</span>"+data[i].Name+"</div></div></div>";
	}
    }
    $("#viewer").html(output);
}


function parseJSON(jsonData) {
    var parsedData=[];
    for (var i=0; i<jsonData.length; i++) {
	var find_proxy = jsonData[i].Names[0].match("squid");
//	var find_proxy = jsonData[i].Names[0].match("hello_world_container");
	var isProxy=null;
	if (find_proxy) {
	    isProxy="Proxy";
	}
	parsedData.push({
	    "Name": jsonData[i].Names[0].replace("/",""),
	    "Id": jsonData[i].Id,
	    "Image": jsonData[i].Image,
	    "Type": isProxy
	});
    }
    return parsedData;
}

function getInfo(info) {
    var url = proxyurl+dockerHost+'/containers/'+info.id+'/exec';
    postData(url, {
	"Cmd": ["cat", "/etc/squid/passwords"],
	"Tty": true,
	"AttachStdout": true
    })
	.then(response => response.json())
	.then(data=> {
	    console.log(data.Id);
	    url=proxyurl+dockerHost+'/exec/'+data.Id+'/start';
	    postData(url, {"Tty": true})
		.then(output => output.text())
		.then(text_output => {
		      console.log(text_output);
		    alert("Current Users:Passwords \n"+text_output)
		})
		.catch(error=> console.error(error));
	})
	.catch(error => console.error(error));
}

function newPassword(info) {
    console.log("Hello World");
    console.log(info.id);
    var uname = prompt("Please enter your username:", "");
    if (uname == null || uname == "") {
	return;
    }
    var password = prompt("Please enter your password:", "");
    console.log(uname, password);
    if (password == null || password == "") {
	return;
    }
    var url = proxyurl+dockerHost+'/containers/'+info.id+'/exec';
    postData(url, {
	"Cmd": ["/update_password.sh", uname, password],
	"Tty": true,
	"AttachStdout": true
    })
	.then(response => response.json())
	.then(data=> {
	    console.log(data.Id);
	    url=proxyurl+dockerHost+'/exec/'+data.Id+'/start';
	    postData(url, {"Tty": true})
		.then(output => output.text())
		.then(text_output => {
		      console.log(text_output);
		    alert(text_output)
		})
		.catch(error=> console.error(error));
	})
	.catch(error => console.error(error));
 }

const postData = (url, data = {}) => {
    return fetch(url, {
	method: "POST",
	mode: "cors",
	cache: "no-cache",
	headers: {
	    "Content-Type": "application/json"
	},
	body: JSON.stringify(data)
    })
	.catch(err => console.error('An error occurred: \n', err));
};

    
