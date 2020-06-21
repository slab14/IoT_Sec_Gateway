#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>

#include "uhcall.h"
#include "utpmtest.h"

uint8_t g_aeskey[TPM_AES_KEY_LEN_BYTES] = {
  0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,
  0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18
};

uint8_t g_hmackey[TPM_HMAC_KEY_LEN] = {
  0x0a,0x0b,0x0c,0x0d,0x0d,0x0f,0x0a,0x02,
  0x1a,0x1b,0x1c,0x1d,0x1e,0x1f,0x11,0x12,
  0xaa,0xbb,0xcc,0xdd
};

uint8_t g_rsakey[4] = {0x00,0x00,0x00,0x00};

uint8_t digest[TPM_PCR_SIZE] = {
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01
};

__attribute__((aligned(4096))) __attribute__((section(".data"))) utpmtest_param_t utpmtest_param;

void setup(){
  utpmtest_param.magic=0xDEADBEEF;
  memcpy(&utpmtest_param.g_aeskey, &g_aeskey, TPM_AES_KEY_LEN_BYTES);
  memcpy(&utpmtest_param.g_hmackey, &g_hmackey, TPM_HMAC_KEY_LEN);
  memcpy(&utpmtest_param.g_rsakey, &g_aeskey, 4);
}

void initTPM(){
  uhcall(UAPP_UTPM_FUNCTION_INIT_MASTER_ENTROPY, &utpmtest_param, sizeof(utpmtest_param_t));
  if (utpmtest_param.result != UTPM_SUCCESS){
    //error
    exit(1);
  }
  uhcall(UAPP_UTPM_FUNCTION_INIT_INSTANCE, &utpmtest_param, sizeof(utpmtest_param_t));
}

uint8_t * hypReadPCR(int pcrNum) {
  char pcrVal[TPM_PCR_SIZE];
  utpmtest_param.pcr_num=pcrNum;
  uhcall(UAPP_UTPM_FUNCTION_PCRREAD, &utpmtest_param, sizeof(utpmtest_param_t));
  if(utpmtest_param.result != UTPM_SUCCESS) {
    //error
    exit(1);
  }
  /*
  memcpy(&pcrVal, &utpmtest_param.pcr0.value, TPM_PCR_SIZE);
  return &pcrVal;
  */
  memcpy(&digest, &utpmtest_param.pcr0.value, TPM_PCR_SIZE);
  return digest;
}

void hypExtendPCR(char *measurement, int pcrNum) {
  memcpy(&utpmtest_param.measurement.value, measurement, TPM_PCR_SIZE);
  utpmtest_param.pcr_num=pcrNum;
  uhcall(UAPP_UTPM_FUNCTION_EXTEND, &utpmtest_param, sizeof(utpmtest_param_t));
  if(utpmtest_param.result != UTPM_SUCCESS){
    //error
    exit(1);
  }
}


