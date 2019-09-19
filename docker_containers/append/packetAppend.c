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


static u_int32_t print_pkt(struct nfq_data *tb){
  int id=0;
  struct nfqnl_msg_packet_hdr *ph;
  struct nfqnl_msg_packet_hw *hwph;
  u_int32_t mark, ifi;
  int ret;
  char *data;

  ph=nfq_get_msg_packet_hdr(tb);
  if(ph) {
    id=ntohl(ph->packet_id);
    printf("hw_protocol=0x%04x hook=%u id=%u ", ntohs(ph->hw_protocol), ph->hook, id);
  }
  hwph=nfq_get_packet_hw(tb);
  if(hwph) {
    int i, hlen=ntohs(hwph->hw_addrlen);
    printf("hw_src_addr=");
    for(i=0;i<hlen-1;i++){
      printf("%02x:", hwph->hw_addr[i]);
    }
    printf("%02x ", hwph->hw_addr[hlen-1]);
  }
  mark=nfq_get_nfmark(tb);
  if(mark) {
    printf("mark=%u ", mark);
  }
  ifi=nfq_get_indev(tb);
  if(ifi){
    printf("indev=%u ",ifi);
  }
  ifi=nfq_get_outdev(tb);
  if(ifi){
    printf("outdev=%u ",ifi);
  }
  ifi=nfq_get_physindev(tb);
  if(ifi){
    printf("physindev=%u ",ifi);
  }
  ifi=nfq_get_physoutdev(tb);
  if(ifi){
    printf("physoutdev=%u ",ifi);
  }
  ret=nfq_get_payload(tb, &data);
  if(ret>0) {
    printf("payload_len=%d ", ret);
  }
  fputc("\n", stdout);

  return id;
}

char * calcHmac(char *key, struct nfq_data *tb) {
  unsigned char *digest;
  char *data;
  int len;
  len = nfq_get_payload(tb, &data);
  digest=HMAC(EVP_md5(), key, strlen(key), (unsigned char*)data, len, NULL, NULL);
  return digest;
}

/* Callback function */
static int cb(struct nfq_q_handle *qh, struct nfgenmsg *nfmsg, struct nfq_data *nfa, void *data) {
  unsigned char * hash;
  char key[]="super_secret_key_for_hmac";
  char iv[]="this is my iv";
  hash = calcHmac(key, nfa);
  u_int32_t id;
  struct nfqnl_msg_packet_hdr *ph;
  ph=nfq_get_msg_packet_hdr(nfa);
  id=ntohl(ph->packet_id);

  //testing
  unsigned char *rawData;
  int len = nfq_get_payload(nfa, &rawData);
  struct pkt_buff *pkBuff=pktb_alloc(AF_INET, rawData, len, 0x10);
  struct iphdr* ip=nfq_ip_get_hdr(pkBuff);
  nfq_ip_set_transport_header(pkBuff, ip);
  if(ip->protocol == IPPROTO_TCP) {
    struct tcphdr *tcp = nfq_tcp_get_hdr(pkBuff);    
    unsigned int payloadLen = nfq_tcp_get_payload_len(tcp, pkBuff);
    payloadLen -= 4*tcp->th_off;
    if(payloadLen>0){
      char *newData="a secret";
      //nfq_tcp_mangle_ipv4(pkBuff, 0, 0, newData, 8);

      char *payload = nfq_tcp_get_payload(tcp, pkBuff);
      for(unsigned int i = 0; i < payloadLen/2; ++i) {
	char tmp = payload[i];
	payload[i] = payload[payloadLen-1-i];
	payload[payloadLen-1-i]=tmp;
       }
      //nfq_tcp_compute_checksum_ipv4(tcp,ip);

    }
    return nfq_set_verdict(qh, id, NF_ACCEPT, pktb_len(pkBuff), pktb_data(pkBuff));
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
