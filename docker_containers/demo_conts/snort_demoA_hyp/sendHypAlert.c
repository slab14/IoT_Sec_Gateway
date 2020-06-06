#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h> 
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>
#include <openssl/conf.h>
#include <openssl/evp.h>
#include <openssl/err.h>

#include <stdbool.h>
#include <stdint.h>
#include "uhcall.h"
#include "uagent.h"

#define SA struct sockaddr

__attribute__((aligned(4096))) __attribute__((section(".data"))) uagent_param_t uhcp_pkt;

void hypEncrypt(void *bufptr) {
  uagent_param_t *ptr_uhcp = (uagent_param_t *)bufptr;
  uhcall(UAPP_UAGENT_FUNCTION_SIGN, ptr_uhcp, sizeof(uagent_param_t));
}


int calcSize(int in){
  int rem=in%16;
  if(rem)
    in+=(16-rem);
  return in;
}

int sendEncryptedAlert(char * alertData, int alertLen){
  int sockfd;
  struct sockaddr_in servaddr;
  int ciphertext_len = calcSize(alertLen);
  char encryptedBuff[ciphertext_len+4];

  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd == -1) {
    exit(0);
  }

  // assign IP, PORT
  bzero(&servaddr, sizeof(servaddr));
  servaddr.sin_family = AF_INET;
  servaddr.sin_addr.s_addr = inet_addr("192.168.1.86");
  servaddr.sin_port = htons(9696);

  // connect the client socket to server socket
  if (connect(sockfd, (SA*)&servaddr, sizeof(servaddr)) != 0) {
    exit(0);
  }


  memcpy(&uhcp_pkt.pkt_data, alertData, alertLen);
  uhcp_pkt.pkt_size=alertLen;
  uhcp_pkt.vaddr = (uint32_t)&uhcp_pkt;
  uhcp_pkt.op=1;
  hypDecrpyt((void *) &uhcp_pkt);

  // copy encrypted data
  memcpy((char*)&encryptedBuff[4], (char*)&uhcp_pkt.pkt_data, ciphertext_len);
  // start data with size of encrypted data
  memcpy((char*)encryptedBuff,(char*)&ciphertext_len,sizeof(int));

  //send alert data to controller
  send(sockfd, encryptedBuff, (ciphertext_len+4), 0);

  close(sockfd);

  return ciphertext_len;
}
