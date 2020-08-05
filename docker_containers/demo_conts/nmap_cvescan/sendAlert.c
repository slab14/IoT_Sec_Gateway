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

#define SA struct sockaddr

int encrypt(unsigned char *plaintext, int plaintext_len, unsigned char *key,
            unsigned char *iv, unsigned char *ciphertext)
{
    EVP_CIPHER_CTX *ctx;
    int len;
    int ciphertext_len;

    /* Create and initialise the context */
    if(!(ctx = EVP_CIPHER_CTX_new()))
      abort();
    
    // Initialise the encryption operation.
    if(1 != EVP_EncryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, key, iv))
      abort();

    // Encrypt message
    if(1 != EVP_EncryptUpdate(ctx, ciphertext, &len, plaintext, plaintext_len))
      abort();
    ciphertext_len = len;

    // Finalise the encryption
    if(1 != EVP_EncryptFinal_ex(ctx, ciphertext + len, &len))
      abort();
    ciphertext_len += len;

    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);

    return ciphertext_len;
}



void reverse_data(char *buf, int len) {
    for(unsigned int i=0; i<len/2; ++i) {
        char tmp = buf[i];
        buf[i]=buf[len-1-i];
        buf[len-1-i]=tmp;
    }
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
  char encryptedBuff[calcSize(alertLen)+4];
  // char encryptedBuff[2000];
  int ciphertext_len = 0;
  unsigned char *key=(unsigned char *)"_My sUpEr sEcrEt kEy 1234567890_";
  unsigned char *iv=(unsigned char *)"0123456789012345";

  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd == -1) {
    exit(0);
  }

  // assign IP, PORT
  bzero(&servaddr, sizeof(servaddr));
  servaddr.sin_family = AF_INET;
  servaddr.sin_addr.s_addr = inet_addr("128.105.144.72");
  servaddr.sin_port = htons(9696);

  // connect the client socket to server socket
  if (connect(sockfd, (SA*)&servaddr, sizeof(servaddr)) != 0) {
    exit(0);
  }

  //reverse_data(alertData, alertLen);

  ciphertext_len = encrypt(alertData, alertLen, key,
			  iv, &encryptedBuff[4]);

  memcpy((char*)encryptedBuff,(char*)&ciphertext_len,sizeof(int));

  //send alert data to controller
  send(sockfd, encryptedBuff, (ciphertext_len+4), 0);

  close(sockfd);

  return ciphertext_len;
}
