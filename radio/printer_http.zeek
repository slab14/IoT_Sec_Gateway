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

type trackingData: record {
  req_data: string &default="";
  req_len: count &default=0;
  req_off: count &default=0;
  req_total: count &default=0;
  resp_data: string &default="";
  resp_len: count &default=0;
  resp_off: count &default=0;
  resp_total: count &default=0;
  not_large_req: bool &default=T;
  not_large_resp: bool &default=T;  
};

global evalData: table[string] of trackingData;

event zeek_init() {
  Log::create_stream(RADIO_HTTP_MSGS, [$columns=HTTP_MSG, $path="radio_http_msgs"]);  
}

event new_connection(c: connection){
  if(c$uid !in evalData) {
    evalData[c$uid]=trackingData();
  }
}

event tcp_packet  (c: connection, is_orig: bool, flags: string, seq: count, ack: count, len: count, payload: string) {
  if(is_orig){
    evalData[c$uid]$req_total+=|payload|;
  } else {
    evalData[c$uid]$resp_total+=|payload|;  
  }
}

event http_entity_data(c: connection, is_orig: bool, length: count, data: string){
  if (((evalData[c$uid]$not_large_req) && (is_orig)) ||
      (( evalData[c$uid]$not_large_resp) && (!is_orig))){
    local check_data: string = data[0:100];
    local match: PatternMatchResult;
    match = match_pattern(check_data,/^\{\"[a-zA-Z\"\_]+/);
    if (|match$str|<=1) {
      match = match_pattern(check_data,/[;A-Z=]+/);
    }
    if (|match$str|<=1) {
      match = match_pattern(check_data, /^\x1f\x8b/);
    }    
    if (is_orig) {
      evalData[c$uid]$req_data=match$str;
      evalData[c$uid]$req_len=|match$str|;
      evalData[c$uid]$req_off=match$off;
      if(evalData[c$uid]$req_data[0]==";") {
        evalData[c$uid]$req_off+=146;
	evalData[c$uid]$req_data=evalData[c$uid]$req_data[1:];
      }
      if(evalData[c$uid]$req_data[0]=="\x1f") {
        evalData[c$uid]$req_off+=434;
      }      
    } else {
      if(match$str!="DOCTYPE") {
        evalData[c$uid]$resp_data=match$str;
        evalData[c$uid]$resp_len=|match$str|;
        evalData[c$uid]$resp_off=match$off;
      }
    }
    if (length>700) {
      if(is_orig) {
        evalData[c$uid]$not_large_req=F;
      } else {
        evalData[c$uid]$not_large_resp=F;
      }
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
               [$uid=c$uid, $req_ip=c$id$orig_h,
	        $req_port=c$id$orig_p,
                $resp_ip=c$id$resp_h, $resp_port=c$id$resp_p,
		$req_len=evalData[c$uid]$req_total,
		$req_mult_pkt=multiple_req_pkts,
		$resp_len=evalData[c$uid]$resp_total,
		$resp_mult_pkt=multiple_resp_pkts,
      		$req_method=c$http$method, $req_uri=c$http$uri,
		$req_key=evalData[c$uid]$req_data,
		$req_key_len=evalData[c$uid]$req_len,
		$req_key_offset=evalData[c$uid]$req_off,
                $resp_code=c$http$status_code,
		$resp_msg=c$http$status_msg,		
  		$resp_key=evalData[c$uid]$resp_data,
		$resp_key_len=evalData[c$uid]$resp_len,
		$resp_key_offset=evalData[c$uid]$resp_off,
		$direction=dir]);
    evalData[c$uid]=trackingData();
  }
}