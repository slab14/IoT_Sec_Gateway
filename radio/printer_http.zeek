module RADIO_HTTP;

@load base/utils/patterns

export {
  redef enum Log::ID += {RADIO_HTTP_MSGS};
  type HTTP_MSG:record {
    uid: string &log;
    req_ip: addr &log;
    req_port: port &log;
    resp_ip: addr &log;
    resp_port: port &log;    
    method: string &log;
    uri: string &log;
    code: count &log;
    msg: string &log;
    full_req_len: count &log;
    full_resp_len: count &log;    
    req_body_key: string &log;
    req_key_len: count &log;
    resp_body_key: string &log;
    resp_key_len: count &log;    
  };
}

global req_data: string = "";
global req_len: count=0;
global resp_data: string = "";
global resp_len: count=0;
global not_large: bool = T;

event zeek_init() {
  Log::create_stream(RADIO_HTTP_MSGS, [$columns=HTTP_MSG, $path="radio_http_msgs"]);  
}


event http_entity_data(c: connection, is_orig: bool, length: count, data: string){
  if (not_large) {
    local check_data: string = data[0:100];
    local match: PatternMatchResult;
    ##match = match_pattern(check_data,/^[a-zA-Z\{\"\_]*/);
    match = match_pattern(check_data,/^\{\"[a-zA-Z\"\_]*/);        
    if (|match$str|<=1) {
      match = match_pattern(check_data,/^[A-Z]*/);
    }
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

event http_message_done (c: connection, is_orig: bool, stat: http_message_stat){
  if(c$http?$status_code){
    Log::write(RADIO_HTTP::RADIO_HTTP_MSGS,
               [$uid=c$uid, $req_ip=c$id$orig_h, $req_port=c$id$orig_p,
                $resp_ip=c$id$resp_h, $resp_port=c$id$resp_p,
      		$method=c$http$method, $uri=c$http$uri,
                $code=c$http$status_code, $msg=c$http$status_msg,		
  		$full_req_len=c$http$request_body_len,
		$req_body_key=req_data, $req_key_len=req_len,
		$full_resp_len=c$http$response_body_len,
  		$resp_body_key=resp_data, $resp_key_len=req_len]);    		
    not_large=T;
    req_data="";
    req_len=0;
    resp_data="";
    resp_len=0;
  }
}