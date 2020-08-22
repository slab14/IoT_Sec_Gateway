module RADIO_HTTP;

export {
  redef enum Log::ID += {RADIO_HTTP_DATA};
  type HTTP_DATA:record {
    uid: string &log;
    p: port &log;
    method: string &log;
    uri: string &log;
    req_len: count &log;
    code: count &log;
    msg: string &log;
    resp_len: count &log;
  };
}

export {
  redef enum Log::ID += {RADIO_HTTP_MSGS};
  type HTTP_MSG:record {
    uid: string &log;  
    uri: string &log &optional;
    code: count &log &optional;    
    body: string &log;
  };
}

event zeek_init() {
  Log::create_stream(RADIO_HTTP_DATA, [$columns=HTTP_DATA, $path="matt"]);
  Log::create_stream(RADIO_HTTP_MSGS, [$columns=HTTP_MSG, $path="msgs"]);  
}


event http_reply(c: connection, version: string, code: count, reason:string){
  Log::write(RADIO_HTTP::RADIO_HTTP_DATA,
               [$uid=c$uid, $p=c$id$resp_p,
                $method=c$http$method, $uri=c$http$uri,
	        $req_len=c$http$request_body_len, $code=c$http$status_code,
	        $msg=c$http$status_msg, $resp_len=c$http$response_body_len]);
}

global req_data: string = "";
global resp_data: string = "";

event http_entity_data(c: connection, is_orig: bool, length: count, data: string){
  if (length<500){
    if (is_orig) {
      req_data+=data;
    } else {
      resp_data+=data;
    }
  }
}

event http_end_entity (c: connection, is_orig: bool){
  if (is_orig){
    Log::write(RADIO_HTTP::RADIO_HTTP_MSGS,
               [$uid=c$uid, $uri=c$http$uri, $body=req_data]);
    req_data="";
  } else {
    Log::write(RADIO_HTTP::RADIO_HTTP_MSGS,
               [$uid=c$uid, $code=c$http$status_code, $body=resp_data]);
    resp_data="";
  }
}