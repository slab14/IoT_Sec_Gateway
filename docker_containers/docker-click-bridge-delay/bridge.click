FromDevice(DEV1) -> Queue -> DelayUnqueue(0.1) -> Queue -> ToDevice(DEV2);

FromDevice(DEV2) -> Queue -> DelayUnqueue(1) -> Queue -> ToDevice(DEV1);

