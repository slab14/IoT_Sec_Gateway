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
  req_offset: count &default=0;
  mult_req_pkts: bool &default=F;  
  resp_data: string &default="";
  resp_len: count &default=0;
  resp_offset: count &default=0;
  mult_resp_pkts: bool &default=F;    
  got_req: bool &default=F;
};

global evalData: table[string] of trackingData;

event zeek_init() {
  Log::create_stream(RADIO_NETTCP_MSGS, [$columns=NETTCP_MSG, $path="radio_nettcp_msgs"]);  
}

event new_connection(c: connection){
  if(c$uid !in evalData) {
    evalData[c$uid]=trackingData();
  }
}

event tcp_packet  (c: connection, is_orig: bool, flags: string, seq: count, ack: count, len: count, payload: string) {
  if (|payload|>0) {
    if(is_orig) {
      if((!evalData[c$uid]$mult_req_pkts) &&  (|evalData[c$uid]$req_len|>0)){
        evalData[c$uid]$mult_req_pkts=T;
      }
      evalData[c$uid]$req_len+=|payload|;
    } else {
      if((!evalData[c$uid]$mult_resp_pkts) &&  (|evalData[c$uid]$resp_len|>0)){
        evalData[c$uid]$mult_resp_pkts=T;
      }    
      evalData[c$uid]$resp_len+=|payload|;      
    }    
    if ((|payload|>2) && (|payload|<500)) {
      local check_data: string = payload[0:500];
      local match: PatternMatchResult;
      ## nettcp start
      match = match_pattern(check_data,/^net\.tcp[a-zA-Z0-9\:\/\.]*/);
      if (match$matched) {
	evalData[c$uid]$req_data = match$str;
	evalData[c$uid]$req_offset = match$off;
      }
      ## nettcp cmds
      match = match_pattern(check_data,/www\.eos\.info[a-zA-Z0-9\:\/\.]*/);
      if (match$matched) {
        if (is_orig) {
          evalData[c$uid]$req_data=match$str;
	  evalData[c$uid]$req_offset = match$off;
        } else {
          evalData[c$uid]$resp_data=match$str;
	  evalData[c$uid]$resp_offset = match$off;
        }
      }
    }
    if ((|payload|>0) && (|payload|<=2)) {
      local dir: string = "->";
      if(c$id$resp_p!=8888/tcp) {
        dir="<-";
      }
      if ((|payload|==1) && (strcmp(string_to_ascii_hex(payload),"0b"))==0) {
        ##accept initial nettcp connectin
        Log::write(RADIO_NETTCP::RADIO_NETTCP_MSGS,
                   [$uid=c$uid, $req_ip=c$id$orig_h, $req_port=c$id$orig_p,
                    $resp_ip=c$id$resp_h, $resp_port=c$id$resp_p,
                    $req_len=evalData[c$uid]$req_len,
		    $req_mult_pkt=evalData[c$uid]$mult_req_pkts,
		    $resp_len=evalData[c$uid]$resp_len,
		    $resp_mult_pkt=evalData[c$uid]$mult_resp_pkts,
		    $req_key=evalData[c$uid]$req_data,
		    $req_key_len=|evalData[c$uid]$req_data|,
		    $req_key_offset=evalData[c$uid]$req_offset, 
  		    $resp_key=payload, $resp_key_len=|payload|,
		    $resp_key_offset=evalData[c$uid]$resp_offset,
		    $direction=dir]);
        evalData[c$uid]=trackingData();		    
      }
      if (((|payload|==2) && (strcmp(string_to_ascii_hex(payload),"0007")==0)) || ((|payload|==1) && (strcmp(string_to_ascii_hex(payload),"07")==0))) {
        ## end of nettcp session
	if (evalData[c$uid]$got_req) {
          Log::write(RADIO_NETTCP::RADIO_NETTCP_MSGS,
                     [$uid=c$uid, $req_ip=c$id$orig_h, $req_port=c$id$orig_p,
                      $resp_ip=c$id$resp_h, $resp_port=c$id$resp_p,
                      $req_len=evalData[c$uid]$req_len,
		      $req_mult_pkt=evalData[c$uid]$mult_req_pkts,
		      $resp_len=evalData[c$uid]$resp_len,
		      $resp_mult_pkt=evalData[c$uid]$mult_resp_pkts,
		      $req_key=evalData[c$uid]$req_data,
		      $req_key_len=|evalData[c$uid]$req_data|,
		      $req_key_offset=evalData[c$uid]$req_offset, 
  		      $resp_key=evalData[c$uid]$resp_data,
		      $resp_key_len=|evalData[c$uid]$req_data|,
		      $resp_key_offset=evalData[c$uid]$resp_offset,
		      $direction=dir]);
	evalData[c$uid]=trackingData();
        } else {
	  evalData[c$uid]$got_req=T;
	}
      }
    }
  }
}