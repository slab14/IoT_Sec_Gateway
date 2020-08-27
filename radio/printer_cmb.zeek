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
    req_len: count &log &optional;
    req_mult_pkt: bool &log;
    resp_len: count &log &optional;
    resp_mult_pkt: bool &log;
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
    direction: string &log;
  };
}

type trackingData: record {
  req_data: string &default="";
  req_len: count &default=0;
  req_key_len: count &default=0;
  req_key_off: count &default=0;
  got_req: bool &default=F;
  resp_data: string &default="";
  resp_len: count &default=0;
  resp_key_len: count &default=0;
  resp_key_off: count &default=0;  
  got_resp: bool &default=F;
  got_log_item: bool &default=F;
  got_large: bool &default=F;
  long_file: bool &default=F;
  got_repeat: bool &default=F;
  direction: string &default="";
};

global evalData: table[string] of trackingData;
global evalData2: table[string] of trackingData;

event zeek_init() {
  Log::create_stream(RADIO_CMB_MSGS, [$columns=CMB_MSG, $path="radio_cmb_msgs"]);  
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
    local match: PatternMatchResult;
    local check_data: string = payload[0:32];
    if (|payload|<=64) {
      ## find codes
      match = match_pattern(check_data, /^[_]+/);
      if ((match$matched)){
	if(is_orig){
	  if(evalData[c$uid]$got_req) {
            evalData2[c$uid]$req_data="/[a-zA-Z]+\_/";
            evalData2[c$uid]$req_key_len=|match$off|;
	    evalData2[c$uid]$req_key_off=match$off;
	    evalData2[c$uid]$req_len+=|payload|;
	    evalData2[c$uid]$got_req=T;   
	    evalData[c$uid]$req_len-=|payload|;
	    evalData[c$uid]$got_repeat=T;
	    evalData[c$uid]$got_log_item=T;
	  } else {
            evalData[c$uid]$req_data = "/[a-zA-Z]+\_/";
            evalData[c$uid]$req_key_len=|match$off|;
	    evalData[c$uid]$req_key_off=match$off;
	    evalData[c$uid]$got_req=T;
	  }
	} else {
	  if(evalData[c$uid]$got_resp) {
            evalData2[c$uid]$resp_data = "/[a-zA-Z]+\_/";
            evalData2[c$uid]$resp_key_len=|match$off|;
	    evalData2[c$uid]$resp_key_off=match$off;
	    evalData2[c$uid]$resp_len+=|payload|;
	    evalData2[c$uid]$got_resp=T;	    	    
	    evalData[c$uid]$resp_len-=|payload|;
	    evalData[c$uid]$got_repeat=T;
	    evalData[c$uid]$got_log_item=T;
	  } else {
            evalData[c$uid]$resp_data = "/[a-zA-Z]+\_/";
            evalData[c$uid]$resp_key_len=|match$off|;
	    evalData[c$uid]$resp_key_off=match$off;
	    evalData[c$uid]$got_resp=T;
	  }
	}	
      } else {
        match = match_pattern(check_data,/^[a-zA-Z\:\/\.]+/);
        if ((match$matched) && (|match$str|>=2) && (match$off==1)) {
          if(is_orig){
  	    if(evalData[c$uid]$got_req){
              evalData2[c$uid]$req_data = match$str;
              evalData2[c$uid]$req_key_len=|match$str|;
	      evalData2[c$uid]$req_key_off=match$off;
  	      evalData2[c$uid]$req_len+=|payload|;
	      evalData2[c$uid]$got_req=T;	    	      
	      evalData[c$uid]$req_len-=|payload|;
	      evalData[c$uid]$got_repeat=T;
	      evalData[c$uid]$got_log_item=T;
	    } else {
              evalData[c$uid]$req_data = match$str;
              evalData[c$uid]$req_key_len=|match$str|;
	      evalData[c$uid]$req_key_off=match$off;
	      evalData[c$uid]$got_req=T;
	    }
          } else {
  	    if(evalData[c$uid]$got_resp){	
              evalData2[c$uid]$resp_data = match$str;
              evalData2[c$uid]$resp_key_len=|match$str|;
	      evalData2[c$uid]$resp_key_off=match$off;
  	      evalData2[c$uid]$resp_len+=|payload|;
	      evalData2[c$uid]$got_resp=T;	    
	      evalData[c$uid]$resp_len-=|payload|;
	      evalData[c$uid]$got_repeat=T;
	      evalData[c$uid]$got_log_item=T;
	    }else{
              evalData[c$uid]$resp_data = match$str;
              evalData[c$uid]$resp_key_len=|match$str|;
	      evalData[c$uid]$resp_key_off=match$off;
	      evalData[c$uid]$got_resp=T;
	    }
	  }
	}
      }
      match = match_pattern(check_data, /^[0-9]+/);
      ## found numbers (e.g., file size)
      if ((match$matched) && (match$off==1) && (|match$str|>1)){
	if(is_orig){
	  if (evalData[c$uid]$got_req) {
 	    evalData2[c$uid]$req_data = "/[0-9]+/";
            evalData2[c$uid]$req_key_len=|match$str|;
	    evalData2[c$uid]$req_key_off=match$off;
	    evalData2[c$uid]$req_len+=|payload|;
	    evalData2[c$uid]$got_req=T;	    
	    evalData[c$uid]$req_len-=|payload|;	    
	    evalData[c$uid]$got_repeat=T;
	    evalData[c$uid]$got_log_item=T;
	  } else {
 	    evalData[c$uid]$req_data = "/[0-9]+/";
            evalData[c$uid]$req_key_len=|match$str|;
	    evalData[c$uid]$req_key_off=match$off;
	    evalData[c$uid]$got_req=T;
 	  }
	} else {
	  if(evalData[c$uid]$got_resp) {
            evalData2[c$uid]$resp_data = "/[0-9]+/";
            evalData2[c$uid]$resp_key_len=|match$str|;
	    evalData2[c$uid]$resp_key_off=match$off;
	    evalData2[c$uid]$resp_len+=|payload|;
	    evalData2[c$uid]$got_resp=T;	    
	    evalData[c$uid]$resp_len-=|payload|;	    
	    evalData[c$uid]$got_repeat=T;
	    evalData[c$uid]$got_log_item=T;
	  } else {
            evalData[c$uid]$resp_data = "/[0-9]+/";
            evalData[c$uid]$resp_key_len=|match$str|;
	    evalData[c$uid]$resp_key_off=match$off;
	    evalData[c$uid]$got_resp=T;
	  }
	}
      }

    }
    if (!evalData[c$uid]$long_file) {
      match = match_pattern(check_data,/^set[ a-zA-Z\:\/\.\(\)\{]+/);
      if ((match$matched) && (|match$str|>=2) && (match$off==1)) {
        evalData[c$uid]$long_file=T;
        if(is_orig){
          evalData[c$uid]$req_data = match$str;
          evalData[c$uid]$req_key_len=|match$str|;
	  evalData[c$uid]$req_key_off=match$off;
	  evalData[c$uid]$got_req=T;
        } else {
          evalData[c$uid]$resp_data = match$str;
          evalData[c$uid]$resp_key_len=|match$str|;
	  evalData[c$uid]$resp_key_off=match$off;
	  evalData[c$uid]$got_resp=T;
	}
      }    
      match = match_pattern(check_data, /^\x1f\x8b/);
      ## found gz
      if ((match$matched)){
        evalData[c$uid]$long_file=T;      
 	if(is_orig){
	  evalData[c$uid]$req_data = match$str;
          evalData[c$uid]$req_key_len=|match$str|;
	  evalData[c$uid]$req_key_off=match$off;
	  evalData[c$uid]$got_req=T;
	} else {
	  evalData[c$uid]$resp_data = match$str;
          evalData[c$uid]$resp_key_len=|match$str|;
	  evalData[c$uid]$resp_key_off=match$off;
	  evalData[c$uid]$got_resp=T;
	}	
      }
      match = match_pattern(check_data, /^\xff\xd8\xff\xe0\x00\x10JFIF/);
      ## found JPEG
      if ((match$matched)){
        evalData[c$uid]$long_file=T;            
	if(is_orig){
	  evalData[c$uid]$req_data = "JFIF";
          evalData[c$uid]$req_key_len=|match$str|;
	  evalData[c$uid]$req_key_off=match$off;
	  evalData[c$uid]$got_req=T;
	} else {
	  evalData[c$uid]$resp_data = "JFIF";
          evalData[c$uid]$resp_key_len=|match$str|;
	  evalData[c$uid]$resp_key_off=match$off;
	  evalData[c$uid]$got_resp=T;
	}	
      }            
    }
    if(|payload|>65){
      evalData[c$uid]$got_large=T;
    }
    if (strcmp(evalData[c$uid]$direction, "")==0){
      if(is_orig) {
        evalData[c$uid]$direction="->";
      } else {
        evalData[c$uid]$direction="<-";
      }
    }
    if((evalData[c$uid]$got_req) && (evalData[c$uid]$got_resp)){
      evalData[c$uid]$got_log_item=T;
    }
    if (evalData[c$uid]$got_log_item) {
      local mult_req=F;
      local mult_resp=F;
      local cleanRepeat=F;
      if(evalData[c$uid]$req_len>64) {
        mult_req=T;
      }
      if(evalData[c$uid]$resp_len>64) {
        mult_resp=T;
      }
      if(evalData[c$uid]$got_repeat){
        cleanRepeat=T;
      }
      Log::write(RADIO_CMB::RADIO_CMB_MSGS,
                 [$uid=c$uid, $req_ip=c$id$orig_h, $req_port=c$id$orig_p,
                  $resp_ip=c$id$resp_h, $resp_port=c$id$resp_p,
                  $req_len=evalData[c$uid]$req_len, $req_mult_pkt=mult_req,
		  $resp_len=evalData[c$uid]$resp_len,$resp_mult_pkt=mult_resp,
                  $req_key=evalData[c$uid]$req_data,
		  $req_key_len=evalData[c$uid]$req_key_len,
		  $req_key_offset=evalData[c$uid]$req_key_off,
  		  $resp_key=evalData[c$uid]$resp_data,
		  $resp_key_len=evalData[c$uid]$resp_key_len,
		  $resp_key_offset=evalData[c$uid]$resp_key_off,
		  $direction=evalData[c$uid]$direction]);
      evalData[c$uid]=trackingData();
      if (cleanRepeat) {
        evalData[c$uid]=evalData2[c$uid];
        if (|evalData2[c$uid]$req_data|>0) {
	  evalData[c$uid]$direction="->";
	} else {
	  evalData[c$uid]$direction="<-";	  
	}
	evalData2[c$uid]=trackingData();
      }
    }
  }
}