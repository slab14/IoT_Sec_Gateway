module RADIO_HTTP;

@load base/utils/patterns

export {
  redef enum Log::ID += {RADIO_HTTP_DATA};
  type HTTP_DATA:record {
    uid: string &log;
    p: port &log;
    method: string &log;
    uri: string &log;
    req_len: count &log;
    code: count &log;
    msg: string &log;
    resp_len: count &log;
  };
}

export {
  redef enum Log::ID += {RADIO_HTTP_MSGS};
  type HTTP_MSG:record {
    uid: string &log;
    p: port &log;
    method: string &log &optional;
    uri: string &log &optional;
    code: count &log &optional;
    msg: string &log &optional;
    body: string &log;
    len: count &log;
  };
}

event zeek_init() {
  Log::create_stream(RADIO_HTTP_DATA, [$columns=HTTP_DATA, $path="radio_http"]);
  Log::create_stream(RADIO_HTTP_MSGS, [$columns=HTTP_MSG, $path="radio_http_msgs"]);  
}


event http_reply(c: connection, version: string, code: count, reason:string){
  Log::write(RADIO_HTTP::RADIO_HTTP_DATA,
               [$uid=c$uid, $p=c$id$resp_p,
                $method=c$http$method, $uri=c$http$uri,
	        $req_len=c$http$request_body_len, $code=c$http$status_code,
	        $msg=c$http$status_msg, $resp_len=c$http$response_body_len]);
}

global req_data: string = "";
global req_len: count=0;
global resp_data: string = "";
global resp_len: count=0;
global not_large: bool = T;

event http_entity_data(c: connection, is_orig: bool, length: count, data: string){
  if (not_large) {
    local check_data: string = data[0:100];
    local match: PatternMatchResult;
    match = match_pattern(check_data,/^[a-zA-Z\{\"\_]*/);
    if (is_orig) {
      req_data+=match$str;
      req_len+=|match$str|;
    } else {
      resp_data+=match$str;
      resp_len+=|match$str|;      
    }
    if (length>700) {
      not_large=F;
    }
  }
}

event http_end_entity (c: connection, is_orig: bool){
  if (is_orig){
    Log::write(RADIO_HTTP::RADIO_HTTP_MSGS,
               [$uid=c$uid, $p=c$id$resp_p, $method=c$http$method,
	        $uri=c$http$uri, $body=req_data, $len=req_len]);
    req_data="";
    req_len=0;
  } else {
    Log::write(RADIO_HTTP::RADIO_HTTP_MSGS,
               [$uid=c$uid, $p=c$id$resp_p, $code=c$http$status_code,
	        $msg=c$http$status_msg, $body=resp_data, $len=resp_len]);
    resp_data="";
    resp_len=0;
  }
  not_large=T;
}