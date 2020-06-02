#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <openssl/conf.h>
#include <openssl/evp.h>
#include <openssl/err.h>

#define SA struct sockaddr

void sendEncryptedAlert(char * ID, int IDlen, char * alertData, int alertLen){
  int sockfd;
  struct sockaddr_in servaddr;

  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd == -1) {
    exit(0);
  }

  // assign IP, PORT
  bzero(&servaddr, sizeof(servaddr));
  servaddr.sin_family = AF_INET;
  servaddr.sin_addr.s_addr = inet_addr("128.105.145.22");
  servaddr.sin_port = htons(9696);

  // connect the client socket to server socket
  if (connect(sockfd, (SA*)&servaddr, sizeof(servaddr)) != 0) {
    exit(0);
  }

  //send alert data to controller
  send(sockfd, ID, IDlen, 0);
  send(sockfd, alertData, alertLen, 0);

  close(sockfd);
}
