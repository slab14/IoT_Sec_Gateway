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
    req_len: count &log &optional;
    req_mult_pkt: bool &log &optional;
    resp_len: count &log &optional;
    resp_mult_pkt: bool &log &optional;
    req_method: string &log &optional;
    req_uri: string &log &optional;
    req_key: string &log &optional;
    req_key_len: count &log &optional;
    req_key_offset: count &log &optional;
    resp_code: count &log &optional;
    resp_msg: string &log &optional;
    resp_key: string &log &optional;
    resp_key_len: count &log &optional;
    resp_key_offset: count &log &optional;
    direction: string &log &optional;
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
      match = match_pattern(payload,/Method[\"\:]+/);    
      ##  find messages type
      if (match$matched) {
        local start: count=match$off+|match$str|;
        match = match_pattern(payload[start:],/[A-Z0-9\"\_]+/);
        if (match$matched) {
          if (is_orig) {
    	    if(got_req) {
              req_data2=match$str;
              req_offset2 = match$off+start;
              req_len2+=|payload|-(match$off+start);
              req_len+=start+match$off-|payload|;
	      repeat=T;
	      write=T;
	    } else {
              req_data=match$str;
              req_offset = match$off+start;
	      got_req=T;	    
            }
          } else {
            if(got_resp) {
              resp_data2=match$str;
              resp_offset2 = match$off+start;
              resp_len2+=|payload|-(match$off+start);
	      resp_len+=start+match$off-|payload|;
	      repeat=T;
  	      write=T;
	    } else {
              resp_data=match$str;
              resp_offset = match$off+start;
	      got_resp=T;
	    }
	  }
        }
      }
    }
    if ((got_req) && (got_resp)) {
      write=T;
    }
    if (write) {
      local mult_req: bool=F;
      local mult_resp: bool=F;
      local dir: string = "->";
      if(req_len>1460) {
        mult_req=T;
      }
      if(resp_len>1460) {
        mult_resp=T;
      }
      if(c$id$resp_p!=35/tcp) {
        dir="<-";
      }
      Log::write(RADIO_FORM2::RADIO_FORM2_MSGS,
                 [$uid=c$uid, $req_ip=c$id$orig_h, $req_port=c$id$orig_p,
                  $resp_ip=c$id$resp_h, $resp_port=c$id$resp_p,
                  $req_len=req_len, $req_mult_pkt=mult_req,
		  $resp_len=resp_len, $resp_mult_pkt=mult_resp,
                  $req_key=req_data, $req_key_len=|req_data|,
		  $req_key_offset=req_offset, 
  		  $resp_key=resp_data, $resp_key_len=|resp_data|,
		  $resp_key_offset=resp_offset, $direction=dir]);
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