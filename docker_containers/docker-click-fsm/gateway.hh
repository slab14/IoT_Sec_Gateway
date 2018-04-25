#ifndef CLICK_GATEWAY_HH
#define CLICK_GATEWAY_HH
#include <click/element.hh>
#include <clicknet/ip.h>
#include <clicknet/tcp.h>
#include <clicknet/udp.h>
#include <click/args.hh>
#include <map>
#include <iostream>
#include <vector>
#include <queue>
#include <fstream>
CLICK_DECLS

typedef enum {
    SNMP = 0, 
    HTTP
}Protocol;


using namespace std;

typedef struct {
    int val;
    char *rule;
}Edge;


class Graph{
private:
    int number_vertices;
    int current_state;
    vector<vector<Edge> > edges;
    map<String, String> hash_map;
    Protocol proto;

public:

    std::map<String, int> map_states;
    Graph();
    Graph(int number_vertices);
    ~Graph();
    void addTransition(int current, int next, String content);
    bool transition( char* content);
    void addState();
    void setCurrentState(int state);
    void addHash(String key, String value);
    String getHash(String key);
    void setProto(Protocol proto);
    Protocol getProto();
    bool transition_snmp(char* content);
    void printHashes();
   
};



class Gateway : public Element {
private:
    Graph* g;
public:
    Gateway();
    ~Gateway();

    int configure(Vector<String> &conf, ErrorHandler *errh);
    const char* class_name() const { return "Gateway";}
    const char* port_count() const { return "1/2";}
    const char* processing() const {return PUSH;}
    const char* flags() const { return "";}
    void parseFSM(FILE* fp, int protocol);
    void push(int port, Packet*);


    
};

CLICK_ENDDECLS
#endif

