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
    req_len: count &log;
    req_mult_pkt: bool &log;
    resp_len: count &log;
    resp_mult_pkt: bool &log;
    req_method: string &log &optional;
    req_uri: string &log &optional;
    req_key: string &log;
    req_key_len: count &log;
    req_key_offset: count &log;
    resp_code: count &log &optional;
    resp_msg: string &log &optional;
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
  req_mult: bool &default=F;
  resp_data: string &default="";
  resp_len: count &default=0;
  resp_off: count &default=0;
  resp_mult: bool &default=F;
  got_req: bool &default=F;
  got_resp: bool &default=F;  
};

global evalData: table[string] of trackingData;

event zeek_init() {
  Log::create_stream(RADIO_GCODE_MSGS, [$columns=GCODE_MSG, $path="radio_gcode_msgs"]);  
}

event new_connection(c: connection){
  if(c$uid !in evalData) {
    evalData[c$uid]=trackingData();
  }
}

event tcp_packet  (c: connection, is_orig: bool, flags: string, seq: count, ack: count, len: count, payload: string) {
  if (|payload|>0) {
    if(is_orig) {
      if((!evalData[c$uid]$req_mult) && (|evalData[c$uid]$req_len|>0)){
        evalData[c$uid]$req_mult=T;
      }
      evalData[c$uid]$req_len+=|payload|;
    } else {
      if((!evalData[c$uid]$resp_mult) && (|evalData[c$uid]$resp_len|>0)){
        evalData[c$uid]$resp_mult=T;
      }    
      evalData[c$uid]$resp_len+=|payload|;      
    }
    local check_data: string = payload[0:50];
    local match: PatternMatchResult;
    if ((|payload|>2) && (|payload|<500)) {
      ## find codes
      match = match_pattern(check_data,/^\~?[GM][0-9]{1,3}[a-zA-Z0-9\:\/\.]*/);
      if (match$matched) {
        if(is_orig){
	  evalData[c$uid]$got_req=T;
          evalData[c$uid]$req_data = match$str;
	  evalData[c$uid]$req_off=match$off;
	} else {
	  evalData[c$uid]$got_resp=T;
          evalData[c$uid]$resp_data = match$str;
	  evalData[c$uid]$resp_off=match$off;
	}
      }
    }
    ## receiving G-Code file
    if ((is_orig) && (|payload|>1400)) {
      match = match_pattern(check_data,/^ZZ/);
      if (match$matched) {
        evalData[c$uid]$got_req=T;      
        evalData[c$uid]$req_data=match$str;
	evalData[c$uid]$req_off=match$off;
      }
    }
    if ((!is_orig) && (|payload|<50)) {
      match = match_pattern(check_data,/ok\./);
      if (match$matched) {
        evalData[c$uid]$got_resp=T;
        evalData[c$uid]$resp_data=match$str;
	evalData[c$uid]$resp_off=match$off;
      }
    }
    if ((evalData[c$uid]$got_req) && (evalData[c$uid]$got_resp)) {
      local dir: string = "->";
      if(c$id$resp_p!=8899/tcp) {
        dir="<-";
      }
      Log::write(RADIO_GCODE::RADIO_GCODE_MSGS,
                 [$uid=c$uid, $req_ip=c$id$orig_h, $req_port=c$id$orig_p,
                  $resp_ip=c$id$resp_h, $resp_port=c$id$resp_p,
                  $req_len=evalData[c$uid]$req_len,
		  $req_mult_pkt=evalData[c$uid]$req_mult,
		  $resp_len=evalData[c$uid]$resp_len,
		  $resp_mult_pkt=evalData[c$uid]$resp_mult,
                  $req_key=evalData[c$uid]$req_data,
		  $req_key_len=|evalData[c$uid]$req_data|,
		  $req_key_offset=evalData[c$uid]$req_off,
  		  $resp_key=evalData[c$uid]$resp_data,
		  $resp_key_len=|evalData[c$uid]$resp_data|,
		  $resp_key_offset=evalData[c$uid]$resp_off,
		  $direction=dir]);
      evalData[c$uid]=trackingData();
    }
  }
}