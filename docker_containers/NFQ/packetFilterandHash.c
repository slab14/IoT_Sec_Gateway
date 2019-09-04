#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <netinet/in.h>
#include <linux/types.h>
#include <linux/netfilter.h>
#include <libnetfilter_queue/libnetfilter_queue.h>
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

char * calcHmac(char * key, struct nfq_data *tb) {
  unsigned char* digest;
  char * data;
  int len;
  len = nfq_get_payload(tb, &data);
  digest=HMAC(EVP_md5(), key, strlen(key), (unsigned char*)data, len, NULL, NULL);
  return digest;
}

char * calcGMAC(char *key, struct nfq_data *tb) {
  struct nfqnl_msg_packet_hdr *ph;
  unsigned char* digest;
  char * data;
  int len, unused, rc=0;
  int id=0;
  char  iv[32];
  ph=nfq_get_msg_packet_hdr(tb);
  if(ph) {
    id=ntohl(ph->packet_id);
  }
  snprintf(iv, sizeof(iv), "%d", id);
  len = nfq_get_payload(tb, &data);
  char tag[16];
  EVP_CIPHER_CTX *ctx = NULL;
  ctx = EVP_CIPHER_CTX_new();
  rc = EVP_EncryptInit_ex(ctx, EVP_aes_128_gcm(), NULL, NULL, NULL);
  rc = EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, sizeof(iv), NULL);
  rc = EVP_EncryptInit_ex(ctx, NULL, NULL, key, iv);
  rc = EVP_EncryptUpdate(ctx, NULL, &unused, data, sizeof(data));
  rc = EVP_EncryptFinal_ex(ctx, NULL, &unused);
  rc = EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, sizeof(tag), tag);
}

/* Callback function */
static int cb(struct nfq_q_handle *qh, struct nfgenmsg *nfmsg, struct nfq_data *nfa, void *data) {
  //printf("pkt received\n");
  //print_pkt(nfa);
  unsigned char * hash;
  char key[]="super_secret_key_for_hmac";
  char iv[]="this is my iv";
  //hash = calcHmac(key, nfa);
  hash = calcGMAC(key, nfa);
  u_int32_t id;
  struct nfqnl_msg_packet_hdr *ph;
  ph=nfq_get_msg_packet_hdr(nfa);
  id=ntohl(ph->packet_id);
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
