in_device :: FromDump("cisco-ios-snmp-1280.pcap", STOP true)
gateway :: Gateway(FSMFILE "snmp_fsm.txt", PROTOCOL 0);
in_device -> Strip(14) -> CheckIPHeader2 -> gateway;
gateway[0] -> Print(notok) -> Discard;
gateway[1] -> Print(ok) -> Discard;
/*
FromDevice(DEV1) -> -> gateway;
//FromDevice(DEV1) -> Strip(14) -> CheckIPHeader2 -> gateway -> ToDevice(DEV2)
gateway[0] -> Discard
gateway[1] -> Queue -> ToDevice(DEV2)
//FromDevice(DEV1) -> Strip(14) -> CheckIPHeader2 -> gateway;
//FromDevice(DEV2) -> Strip(14) -> CheckIPHEader2 -> gateway -> ToDevice(DEV1);
FromDevice(DEV2) -> Queue -> ToDevice(DEV1);
*/






