module RADIO_NETTCP;

@load base/utils/patterns

export {
  redef enum Log::ID += {RADIO_NETTCP_MSGS};
  type NETTCP_MSG:record {
    uid: string &log;
    req_ip: addr &log;
    req_port: port &log;
    resp_ip: addr &log;
    resp_port: port &log;    
    full_req_len: count &log;
    full_resp_len: count &log;
    req_body_key: string &log;
    req_key_len: count &log;
    req_key_offset: count &log;
    resp_body_key: string &log;
    resp_key_len: count &log;
    resp_key_offset: count &log;    
  };
}

global req_data: string = "";
global req_offset: count = 0;
global req_len: count=0;
global resp_data: string = "";
global resp_len: count=0;
global resp_offset: count = 0;
global got_req: bool = F;

event zeek_init() {
  Log::create_stream(RADIO_NETTCP_MSGS, [$columns=NETTCP_MSG, $path="radio_nettcp_msgs"]);  
}

event tcp_packet  (c: connection, is_orig: bool, flags: string, seq: count, ack: count, len: count, payload: string) {
  if (|payload|>0) {
    if(is_orig) {
        req_len+=|payload|;
    } else {
        resp_len+=|payload|;      
    }    
    if ((|payload|>2) && (|payload|<500)) {
      local check_data: string = payload[0:500];
      local match: PatternMatchResult;
      ## nettcp start
      match = match_pattern(check_data,/^net\.tcp[a-zA-Z0-9\:\/\.]*/);
      if (match$matched) {
	req_data = match$str;
	req_offset = match$off;
      }
      ## nettcp cmds
      match = match_pattern(check_data,/www\.eos\.info[a-zA-Z0-9\:\/\.]*/);
      if (match$matched) {
        if (is_orig) {
          req_data=match$str;
	  req_offset = match$off;
        } else {
          resp_data=match$str;
	  resp_offset = match$off;
        }
      }
    }
    if ((|payload|>0) && (|payload|<=2)) {
      if ((|payload|==1) && (strcmp(string_to_ascii_hex(payload),"0b"))==0) {
        ##accept initial nettcp connectin
        Log::write(RADIO_NETTCP::RADIO_NETTCP_MSGS,
                   [$uid=c$uid, $req_ip=c$id$orig_h, $req_port=c$id$orig_p,
                    $resp_ip=c$id$resp_h, $resp_port=c$id$resp_p,
                    $full_req_len=req_len,
		    $req_body_key=req_data, $req_key_len=|req_data|,
		    $req_key_offset=req_offset, $full_resp_len=resp_len,
  		    $resp_body_key=payload, $resp_key_len=|payload|,
		    $resp_key_offset=resp_offset]);
        req_data="";
        req_len=0;
	req_offset=0;
        resp_data="";
        resp_len=0;
	resp_offset=0;
	got_req=F;
      }
      if (((|payload|==2) && (strcmp(string_to_ascii_hex(payload),"0007")==0)) || ((|payload|==1) && (strcmp(string_to_ascii_hex(payload),"07")==0))) {
        ## end of nettcp session
	if (got_req) {
          Log::write(RADIO_NETTCP::RADIO_NETTCP_MSGS,
                     [$uid=c$uid, $req_ip=c$id$orig_h, $req_port=c$id$orig_p,
                      $resp_ip=c$id$resp_h, $resp_port=c$id$resp_p,
                      $full_req_len=req_len,
		      $req_body_key=req_data, $req_key_len=|req_data|,
		      $req_key_offset=req_offset, $full_resp_len=resp_len,
  		      $resp_body_key=resp_data, $resp_key_len=|req_data|,
		      $resp_key_offset=resp_offset]);
        req_data="";
        req_len=0;
	req_offset=0;
        resp_data="";
        resp_len=0;
	resp_offset=0;
	got_req=F;
        } else {
	  got_req=T;
	}
      }
    }
  }
}