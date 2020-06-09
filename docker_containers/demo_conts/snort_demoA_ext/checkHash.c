#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdbool.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <linux/types.h>
#include <linux/netfilter.h>
#include <libnetfilter_queue/libnetfilter_queue.h>
#include <libnetfilter_queue/pktbuff.h>
#include <libnetfilter_queue/libnetfilter_queue_ipv4.h>
#include <libnetfilter_queue/libnetfilter_queue_tcp.h>
#include <openssl/hmac.h>
#include <openssl/aes.h>
#include <openssl/evp.h>
#include <inttypes.h>

#define DIGEST_SIZE 20

int compare(unsigned char *a, unsigned char *b, int size) {
    while(size-- > 0) {
      printf("%x | %x \n", *a, *b);
        if ( *a != *b ) { return (*a < *b ) ? -1 : 1; }
        a++; b++;
    }
    return 0;
}

void reverseData(char *payload, int payloadLen){
  for(unsigned int i = 0; i < payloadLen/2; ++i) {
    char tmp = payload[i];
    payload[i] = payload[payloadLen-1-i];
    payload[payloadLen-1-i]=tmp;
  }
}

unsigned char * calcHmac(char *key, struct nfq_data *tb) {
  unsigned char *digest;
  char *data;
  int len;
  len = nfq_get_payload(tb, &data);
  digest=HMAC(EVP_sha1(), key, strlen(key), (unsigned char*)data, len, NULL, NULL);
  return digest;
}

unsigned char * newCalcHmac(char *key, uint8_t *data, uint32_t len) {
  unsigned char *digest;
  digest=HMAC(EVP_sha1(), key, strlen(key), (unsigned char*)data, len, NULL, NULL);
  return digest;
}

/* Callback function */
static int cb(struct nfq_q_handle *qh, struct nfgenmsg *nfmsg, struct nfq_data *nfa, void *data) {
  unsigned char * hash;
  char key[]="super_secret_key_for_hmac";
  u_int32_t id;
  struct nfqnl_msg_packet_hdr *ph;
  ph=nfq_get_msg_packet_hdr(nfa);
  id=ntohl(ph->packet_id);

  //testing
  unsigned char *rawData;
  int len = nfq_get_payload(nfa, &rawData);
  struct pkt_buff *pkBuff=pktb_alloc(AF_INET, rawData, len, 0x0); /* create buffer with extra space for hash value */
  struct iphdr* ip=nfq_ip_get_hdr(pkBuff);
  nfq_ip_set_transport_header(pkBuff, ip);
  if(ip->protocol == IPPROTO_TCP) {
    struct tcphdr *tcp = nfq_tcp_get_hdr(pkBuff);    
    unsigned int payloadLen = nfq_tcp_get_payload_len(tcp, pkBuff);
    payloadLen -= 4*tcp->th_off;
    if(payloadLen>DIGEST_SIZE){
      /* received hash */
      unsigned char oldHash[DIGEST_SIZE];
      char *payload = nfq_tcp_get_payload(tcp, pkBuff);
      //raspberry pi adding 2 bytes to end of packet
      memcpy(oldHash, payload+payloadLen-DIGEST_SIZE+2, DIGEST_SIZE);
      /* Remove first 16 data Bytes */
      //memmove(payload, payload, payloadLen-DIGEST_SIZE);
      
      /* Set final 16 byes (tag) to 0 */
      memset(payload+payloadLen-DIGEST_SIZE, 0x00, DIGEST_SIZE);
      pktb_trim(pkBuff, pktb_len(pkBuff)-DIGEST_SIZE);
      ip->tot_len=htons(pktb_len(pkBuff));
      nfq_tcp_compute_checksum_ipv4(tcp,ip);
      nfq_ip_set_checksum(ip);

      /* Cacl hash of data */
      hash = newCalcHmac(key, pktb_data(pkBuff), pktb_len(pkBuff));
      //hash = newCalcHmac(key, payload, payloadLen-DIGEST_SIZE);
      int k=0;
      for (k=0; k<DIGEST_SIZE; k++){
	printf("%x | %x \n", oldHash[k], hash[k]);
      }
      if(compare(hash, oldHash, DIGEST_SIZE)==0) {
        return nfq_set_verdict(qh, id, NF_ACCEPT, pktb_len(pkBuff), pktb_data(pkBuff));
      }else {
        return nfq_set_verdict(qh, id, NF_DROP, 0, NULL);
      }
    }
  }
  return nfq_set_verdict(qh, id, NF_ACCEPT, 0, NULL);
}


int main(int argc, char **argv) {
  struct nfq_handle *h;
  struct nfq_q_handle *qh;
  int fd;
  int rv;
  char buf[4096] __attribute__ ((aligned));

  h=nfq_open();
  if(!h) {
    fprintf(stderr, "error during nfq_open()\n");
    exit(1);
  }
  if(nfq_unbind_pf(h, AF_INET) < 0) {
    fprintf(stderr, "error during nfq_unfind_pf()\n");
    exit(1);
  }
  if(nfq_bind_pf(h, AF_INET) < 0) {
    fprintf(stderr, "error during nfq_bind_pf()\n");
    exit(1);
  }
  /* Set callback function */
  qh=nfq_create_queue(h,1,&cb, NULL);
  if(!qh) {
    fprintf(stderr, "error during nfq_create_queue()\n");
    exit(1);
  }
  if(nfq_set_mode(qh, NFQNL_COPY_PACKET, 0xffff) < 0){
    fprintf(stderr, "can't set packet_copy mode\n");
    exit(1);
  }
  fd=nfq_fd(h);
  
  while((rv=recv(fd,buf, sizeof(buf),0))) {
    nfq_handle_packet(h, buf, rv);
  }

  nfq_destroy_queue(qh);
  nfq_close(h);

  exit(0);
}
