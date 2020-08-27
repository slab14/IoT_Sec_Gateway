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
    req_len: count &log;
    req_mult_pkt: bool &log;
    resp_len: count &log;
    resp_mult_pkt: bool &log;    
    req_method: string &log;
    req_uri: string &log;
    req_key: string &log;
    req_key_len: count &log;
    req_key_offset: count &log;
    resp_code: count &log;
    resp_msg: string &log;
    resp_key: string &log;
    resp_key_len: count &log;
    resp_key_offset: count &log;
    direction: string &log &optional;
  };
}

global req_data: string = "";
global req_len: count=0;
global req_off: count=0;
global resp_data: string = "";
global resp_len: count=0;
global resp_off: count=0;
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
      req_off=match$off;
    } else {
      resp_data+=match$str;
      resp_len+=|match$str|;
      resp_off=match$off;      
    }
    if (length>700) {
      not_large=F;
    }
  }
}

event http_message_done (c: connection, is_orig: bool, stat: http_message_stat){
  if(c$http?$status_code){
    local multiple_req_pkts: bool = F;
    local multiple_resp_pkts: bool = F;
    local dir: string = "->";
    if(|c$http$request_body_len|>0) {
      multiple_req_pkts = T;
    }
    if(|c$http$response_body_len|>0) {
      multiple_resp_pkts = T;
    }
    if(c$id$resp_p!=80/tcp){
      dir="<-";
    }
    Log::write(RADIO_HTTP::RADIO_HTTP_MSGS,
               [$uid=c$uid, $req_ip=c$id$orig_h, $req_port=c$id$orig_p,
                $resp_ip=c$id$resp_h, $resp_port=c$id$resp_p,
  		$req_len=c$http$request_body_len,
		$req_mult_pkt=multiple_req_pkts,
		$resp_len=c$http$response_body_len,
		$resp_mult_pkt=multiple_resp_pkts,
      		$req_method=c$http$method, $req_uri=c$http$uri,
		$req_key=req_data, $req_key_len=req_len,
		$req_key_offset=req_off,
                $resp_code=c$http$status_code, $resp_msg=c$http$status_msg,		
  		$resp_key=resp_data, $resp_key_len=req_len,
		$resp_key_offset=resp_off, $direction=dir]);    		
    not_large=T;
    req_data="";
    req_len=0;
    req_off=0;    
    resp_data="";
    resp_len=0;
    resp_off=0;    
  }
}