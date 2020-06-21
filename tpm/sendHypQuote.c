#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h> 
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>

#include <stdbool.h>
#include "uhcall.h"
#include "uagent.h"

#define SA struct sockaddr

__attribute__((aligned(4096))) __attribute__((section(".data"))) uagent_param_t uhcp;

void hypEncrypt(void *bufptr) {
  uagent_param_t *ptr_buf = (uagent_param_t *)bufptr;
  uhcall(UAPP_UAGENT_FUNCTION_SIGN, ptr_buf, sizeof(uagent_param_t));
}

int calcSize(int in){
  int rem;
  rem=in%16;
  if (rem)
    in+=(16-rem);
  return in;
}

int sendEncrypted(char * data, int len){
  int sockfd;
  struct sockaddr_in servaddr;
  int ciphertext_len=calcSize(len);
  char encryptedBuff[ciphertext_len+4];

  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd == -1) {
    exit(0);
  }

  // assign IP, PORT
  bzero(&servaddr, sizeof(servaddr));
  servaddr.sin_family = AF_INET;
  servaddr.sin_addr.s_addr = inet_addr("192.168.1.87");
  servaddr.sin_port = htons(38687);

  // connect the client socket to server socket
  if (connect(sockfd, (SA*)&servaddr, sizeof(servaddr)) != 0) {
    exit(0);
  }

  memcpy(&uhcp.pkt_data, data, len);
  uhcp.pkt_size=len;
  uhcp.vaddr=(uint32_t)&uhcp;
  uhcp.op=1;
  hypEncrypt((void *)&uhcp);

  memcpy((char*)&encryptedBuff[4], (char*)&uhcp.pkt_data, ciphertext_len);
  memcpy((char*)&encryptedBuff,(char*)&ciphertext_len,sizeof(int));

  //send alert data to controller
  send(sockfd, encryptedBuff, (ciphertext_len+4), 0);

  close(sockfd);

  return ciphertext_len;
}
