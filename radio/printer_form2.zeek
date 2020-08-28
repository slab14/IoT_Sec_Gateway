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

type trackingData: record {
  req_data: string &default="";
  req_len: count &default=0;
  req_offset: count &default=0;
  got_req: bool &default=F;
  resp_data: string &default="";
  resp_len: count &default=0;
  resp_offset: count &default=0;
  got_resp: bool &default=F;
  write: bool &default=F;
  repeat: bool &default=F;
};

global evalData: table[string] of trackingData;
global evalData2: table[string] of trackingData;

event zeek_init() {
  Log::create_stream(RADIO_FORM2_MSGS, [$columns=FORM2_MSG, $path="radio_form2_msgs"]);
}

event new_connection (c: connection) {
  if(c$uid !in evalData) {
    evalData[c$uid]=trackingData();
    evalData2[c$uid]=trackingData();
  }
}

event tcp_packet  (c: connection, is_orig: bool, flags: string, seq: count, ack: count, len: count, payload: string) {
  if (|payload|>0) {
    if(is_orig) {
      evalData[c$uid]$req_len+=|payload|;
    } else {
      evalData[c$uid]$resp_len+=|payload|;
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
    	    if(evalData[c$uid]$got_req) {
              evalData2[c$uid]$req_data=match$str;
              evalData2[c$uid]$req_offset = match$off+start;
              evalData2[c$uid]$req_len+=|payload|-(match$off+start);
	      evalData2[c$uid]$got_req=T;
              evalData[c$uid]$req_len+=start+match$off-|payload|;
	      evalData[c$uid]$repeat=T;
	      evalData[c$uid]$write=T;
	    } else {
              evalData[c$uid]$req_data=match$str;
              evalData[c$uid]$req_offset = match$off+start;
	      evalData[c$uid]$got_req=T;	    
            }
          } else {
            if(evalData[c$uid]$got_resp) {
              evalData2[c$uid]$resp_data=match$str;
              evalData2[c$uid]$resp_offset = match$off+start;
              evalData2[c$uid]$resp_len+=|payload|-(match$off+start);
	      evalData2[c$uid]$got_resp=T;
	      evalData[c$uid]$resp_len+=start+match$off-|payload|;
	      evalData[c$uid]$repeat=T;
  	      evalData[c$uid]$write=T;
	    } else {
              evalData[c$uid]$resp_data=match$str;
              evalData[c$uid]$resp_offset = match$off+start;
	      evalData[c$uid]$got_resp=T;
	    }
	  }
        }
      }
    }
    if ((evalData[c$uid]$got_req) && (evalData[c$uid]$got_resp)) {
      evalData[c$uid]$write=T;
    }
    if (evalData[c$uid]$write) {
      local mult_req: bool=F;
      local mult_resp: bool=F;
      local cleanRepeat: bool=F;
      local dir: string = "->";
      if(evalData[c$uid]$req_len>1460) {
        mult_req=T;
      }
      if(evalData[c$uid]$resp_len>1460) {
        mult_resp=T;
      }
      if(c$id$resp_p!=35/tcp) {
        dir="<-";
      }
      if((evalData[c$uid]$got_resp)&&(!evalData[c$uid]$got_req)){
        dir="<-";
      }
      if(evalData[c$uid]$repeat){
        cleanRepeat=T;
      }
      Log::write(RADIO_FORM2::RADIO_FORM2_MSGS,
                 [$uid=c$uid, $req_ip=c$id$orig_h, $req_port=c$id$orig_p,
                  $resp_ip=c$id$resp_h, $resp_port=c$id$resp_p,
                  $req_len=evalData[c$uid]$req_len, $req_mult_pkt=mult_req,
		  $resp_len=evalData[c$uid]$resp_len, $resp_mult_pkt=mult_resp,
                  $req_key=evalData[c$uid]$req_data,
		  $req_key_len=|evalData[c$uid]$req_data|,
		  $req_key_offset=evalData[c$uid]$req_offset, 
  		  $resp_key=evalData[c$uid]$resp_data,
		  $resp_key_len=|evalData[c$uid]$resp_data|,
		  $resp_key_offset=evalData[c$uid]$resp_offset,
		  $direction=dir]);
      evalData[c$uid]=trackingData();
      if (cleanRepeat) {
        if (|evalData2[c$uid]$req_data|>0) {
	  evalData[c$uid]=evalData2[c$uid];
	} else {
	  evalData[c$uid]=evalData2[c$uid];
        }
	evalData2[c$uid]=trackingData();
      }
    }
  }
}