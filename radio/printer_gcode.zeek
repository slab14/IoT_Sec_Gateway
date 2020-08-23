module RADIO_GCODE;

@load base/utils/patterns

export {
  redef enum Log::ID += {RADIO_GCODE_MSGS};
  type GCODE_MSG:record {
    uid: string &log;
    req_ip: addr &log;
    req_port: port &log;
    resp_ip: addr &log;
    resp_port: port &log;    
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
global got_req: bool = F;
global got_resp: bool=F;

event zeek_init() {
  Log::create_stream(RADIO_GCODE_MSGS, [$columns=GCODE_MSG, $path="radio_gcode_msgs"]);  
}

event tcp_packet  (c: connection, is_orig: bool, flags: string, seq: count, ack: count, len: count, payload: string) {
  if (|payload|>0) {
    if(is_orig) {
        req_len+=|payload|;
    } else {
        resp_len+=|payload|;      
    }
    local check_data: string = payload[0:50];
    local match: PatternMatchResult;
    if ((|payload|>2) && (|payload|<500)) {
      ## find codes
      match = match_pattern(check_data,/^\~?[GM][0-9]{1,3}[a-zA-Z0-9\:\/\.]*/);
      if (match$matched) {
        if(is_orig){
	  got_req=T;
          req_data = match$str;
	} else {
	  got_resp=T;
          resp_data = match$str;
	}
      }
    }
    ## receiving G-Code file
    if ((is_orig) && (|payload|>1400)) {
      match = match_pattern(check_data,/^ZZ/);
      if (match$matched) {
        got_req=T;      
        req_data=match$str;
      }
    }
    if ((!is_orig) && (|payload|<50)) {
      match = match_pattern(check_data,/ok\./);
      if (match$matched) {
        got_resp=T;
        resp_data=match$str;
      }
    }
    if ((got_req) && (got_resp)) {
      Log::write(RADIO_GCODE::RADIO_GCODE_MSGS,
                 [$uid=c$uid, $req_ip=c$id$orig_h, $req_port=c$id$orig_p,
                  $resp_ip=c$id$resp_h, $resp_port=c$id$resp_p,
                  $full_req_len=req_len,
                  $req_body_key=req_data, $req_key_len=|req_data|,
		  $full_resp_len=resp_len,
  		  $resp_body_key=resp_data, $resp_key_len=|resp_data|]);
      req_data="";
      req_len=0;
      resp_data="";
      resp_len=0;
      got_req=F;
      got_resp=F;	
    }
  }
}