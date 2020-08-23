module RADIO_CMB;

@load base/utils/patterns

export {
  redef enum Log::ID += {RADIO_CMB_MSGS};
  type CMB_MSG:record {
    uid: string &log;
    req_ip: addr &log;
    req_port: port &log;
    resp_ip: addr &log;
    resp_port: port &log;    
    full_req_len: count &log &optional;
    full_resp_len: count &log &optional;
    req_body_key: string &log &optional;
    req_key_len: count &log &optional;
    resp_body_key: string &log &optional;
    resp_key_len: count &log &optional;
    initiator: string &log;
  };
}

global req_data: string = "";
global req_len: count=0;
global req_key_len: count=0;
global resp_data: string = "";
global resp_len: count=0;
global resp_key_len: count=0;
global got_log_item: bool = F;
global got_large: bool=F;
global long_file: bool = F;
global direction: string = "";

event zeek_init() {
  Log::create_stream(RADIO_CMB_MSGS, [$columns=CMB_MSG, $path="radio_cmb_msgs"]);  
}

event new_connection (c: connection) {
  got_large = F;
}

event tcp_packet  (c: connection, is_orig: bool, flags: string, seq: count, ack: count, len: count, payload: string) {
  if (|payload|>0) {
    if(is_orig) {
        req_len+=|payload|;
    } else {
        resp_len+=|payload|;      
    }
    local match: PatternMatchResult;
    local check_data: string = payload[0:32];
    if (|payload|<=64) {
      ## find codes    
      match = match_pattern(check_data,/^[a-zA-Z\:\/\.]+/);
      if ((match$matched) && (|match$str|>=2) && (match$off==1)) {
          got_log_item=T;
        if(is_orig){
          req_data = match$str;
          req_key_len=|match$str|;	  
        } else {
          resp_data = match$str;
          resp_key_len=|match$str|;	  	  
	}
      }
      match = match_pattern(check_data, /^[0-9]+/);
      ## found numbers (e.g., file size)
      if ((match$matched) && (match$off==1)){
        got_log_item=T;
	if(is_orig){
	  req_data = "/[0-9]+/";
          req_key_len=|match$str|;	  	  
	} else {
	  resp_data = "/[0-9]+/";
          resp_key_len=|match$str|;	  	  
	}
      }
      match = match_pattern(check_data, /^[_]+/);
      if ((match$matched)){
        got_log_item=T;      
	if(is_orig){
	  req_data = "/[a-zA-Z]+\_/";
          req_key_len=|match$off|;	  	  
	} else {
	  resp_data = "/[a-zA-Z]+\_/";
          resp_key_len=|match$off|;	  
	}	
      }
    }
    if (!long_file) {
      match = match_pattern(check_data,/^set[ a-zA-Z\:\/\.\(\)\{]+/);
      if ((match$matched) && (|match$str|>=2) && (match$off==1)) {
        long_file=T;
        if(is_orig){
          req_data = match$str;
          req_key_len=|match$str|;	  	  
        } else {
          resp_data = match$str;
          resp_key_len=|match$str|;	  	  
	}
      }    
      match = match_pattern(check_data, /^\x1f\x8b/);
      ## found gz
      if ((match$matched)){
        long_file=T;      
	if(is_orig){
	  req_data = match$str;
          req_key_len=|match$str|;	  	  
	} else {
	  resp_data = match$str;
          resp_key_len=|match$str|;	  	  
	}	
      }
      match = match_pattern(check_data, /^\xff\xd8\xff\xe0\x00\x10JFIF/);
      ## found JPEG
      if ((match$matched)){
        long_file=T;            
	if(is_orig){
	  req_data = "JFIF";
          req_key_len=|match$str|;
	} else {
	  resp_data = "JFIF";
          resp_key_len=|match$str|;	  	  
	}	
      }            
    }
    if(|payload|>65){
      got_large=T;
    }
    if (strcmp(direction, "")==0){
      if(is_orig) {
        direction="->";
      } else {
        direction="<-";
      }
    }
    if (got_log_item) {
      Log::write(RADIO_CMB::RADIO_CMB_MSGS,
                 [$uid=c$uid, $req_ip=c$id$orig_h, $req_port=c$id$orig_p,
                  $resp_ip=c$id$resp_h, $resp_port=c$id$resp_p,
                  $full_req_len=req_len,
                  $req_body_key=req_data, $req_key_len=req_key_len,
		  $full_resp_len=resp_len,
  		  $resp_body_key=resp_data, $resp_key_len=resp_key_len,
		  $initiator=direction]);
      req_data="";
      req_len=0;
      resp_data="";
      resp_len=0;
      got_log_item=F;
      long_file=F;
      direction="";
    }
  }
}