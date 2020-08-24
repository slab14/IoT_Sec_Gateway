module RADIO_FORM2;

@load base/utils/patterns

export {
  redef enum Log::ID += {RADIO_FORM2_MSGS};
  type FORM2_MSG:record {
    uid: string &log;
    req_ip: addr &log;
    req_port: port &log;
    resp_ip: addr &log;
    resp_port: port &log;    
    full_req_len: count &log &optional;
    full_resp_len: count &log &optional;
    req_body_key: string &log &optional;
    req_key_len: count &log &optional;
    req_key_offset: count &log &optional;
    resp_body_key: string &log &optional;
    resp_key_len: count &log &optional;
    resp_key_offset: count &log &optional;
  };
}

global req_data: string = "";
global req_offset: count = 0;
global req_len: count=0;
global resp_data: string = "";
global resp_len: count=0;
global resp_offset: count = 0;
global req_data2: string = "";
global req_offset2: count = 0;
global req_len2: count=0;
global resp_data2: string = "";
global resp_len2: count=0;
global resp_offset2: count = 0;
global got_req: bool = F;
global got_resp: bool = F;
global write: bool = F;
global repeat: bool = F;

event zeek_init() {
  Log::create_stream(RADIO_FORM2_MSGS, [$columns=FORM2_MSG, $path="radio_form2_msgs"]);
}

event tcp_packet  (c: connection, is_orig: bool, flags: string, seq: count, ack: count, len: count, payload: string) {
  if (|payload|>0) {
    if(is_orig) {
      req_len+=|payload|;
    } else {
      resp_len+=|payload|;
    }
    ##  find start
    local match: PatternMatchResult;
    match = match_pattern(payload,/\{\x0a[ a-zA-Z0-9\"\_\:\{]+/);
    if (match$matched) {
      ##  find messages type
      match = match_pattern(payload,/Method[ a-zA-Z0-9\"\_\:]+/);
      if (match$matched) {
        if (is_orig) {
	  if(got_req) {
            req_data2=match$str;
            req_offset2 = match$off;
            req_len2+=|payload|-match$off;
            req_len+=match$off-|payload|;
	    repeat=T;
	    write=T;
	  } else {
            req_data=match$str;
            req_offset = match$off;
	    got_req=T;	    
          }
        } else {
          if(got_resp) {
            resp_data2=match$str;
            resp_offset2 = match$off;
            resp_len2+=|payload|-match$off;
	    resp_len+=match$off-|payload|;
	    repeat=T;
  	    write=T;
	  } else {
            resp_data=match$str;
            resp_offset = match$off;
	    got_resp=T;
	  }
        }
      }
    }
    if ((got_req) && (got_resp)) {
      write=T;
    }
    if (write) {
      Log::write(RADIO_FORM2::RADIO_FORM2_MSGS,
                 [$uid=c$uid, $req_ip=c$id$orig_h, $req_port=c$id$orig_p,
                  $resp_ip=c$id$resp_h, $resp_port=c$id$resp_p,
                  $full_req_len=req_len,
                  $req_body_key=req_data, $req_key_len=|req_data|,
		  $req_key_offset=req_offset, $full_resp_len=resp_len,
  		  $resp_body_key=resp_data, $resp_key_len=|resp_data|,
		  $resp_key_offset=resp_offset]);
      req_data="";
      req_len=0;
      req_offset=0;
      resp_data="";
      resp_len=0;
      resp_offset=0;
      write=F;
      got_req=F;
      got_resp=F;
      if (repeat) {
        if (|req_data2|>0) {
	  req_data=req_data2;
	  req_offset=req_offset2;
	  req_len=req_len2;
	  req_data2="";
	  req_offset2=0;
	  req_len2=0;
	  got_req=T;
	} else {
	  resp_data=resp_data2;
	  resp_offset=resp_offset2;
	  resp_len=resp_len2;
	  resp_data2="";
	  resp_offset2=0;
	  resp_len2=0;
	  got_resp=T;
        }
	repeat=F;
      }
    }
  }
}