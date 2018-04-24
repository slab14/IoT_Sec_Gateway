#include <click/config.h>
#include <click/confparse.hh>
#include <map>
#include "gateway.hh"

/* Add header files as required */
CLICK_DECLS

using namespace std;

// Fills lps[] for given patttern pat[0..M-1]
void computeLPSArray(char *pat, int M, int *lps)
{
    // length of the previous longest prefix suffix
    int len = 0;
 
    lps[0] = 0; // lps[0] is always 0
 
    // the loop calculates lps[i] for i = 1 to M-1
    int i = 1;
    while (i < M)
    {
        if (pat[i] == pat[len])
        {
            len++;
            lps[i] = len;
            i++;
        }
        else // (pat[i] != pat[len])
        {
            // This is tricky. Consider the example.
            // AAACAAAA and i = 7. The idea is similar 
            // to search step.
            if (len != 0)
            {
                len = lps[len-1];
 
                // Also, note that we do not increment
                // i here
            }
            else // if (len == 0)
            {
                lps[i] = 0;
                i++;
            }
        }
    }
}


// Prints occurrences of txt[] in pat[]
bool KMPSearch(char *pat, char *txt)
{
    int M = strlen(pat);
    int N = strlen(txt);
 
    // create lps[] that will hold the longest prefix suffix
    // values for pattern
    int lps[M];
 
    // Preprocess the pattern (calculate lps[] array)
    computeLPSArray(pat, M, lps);
 
    int i = 0;  // index for txt[]
    int j  = 0;  // index for pat[]
    while (i < N)
    {
        if (pat[j] == txt[i])
        {
            j++;
            i++;
        }
 
        if (j == M)
        {
            j = lps[j-1];
	    return true;
        }
 
        // mismatch after j matches
        else if (i < N && pat[j] != txt[i])
        {
            // Do not match lps[0..lps[j-1]] characters,
            // they will match anyway
            if (j != 0)
                j = lps[j-1];
            else
                i = i+1;
        }
    }
    return false;
}
 



Graph::Graph(){
    this->number_vertices = 0;
}

Graph::Graph(int number_vertices){
   this->number_vertices = number_vertices;
}


Graph::~Graph(){
}

void Graph::addTransition(int current, int next, String content){
    size_t len = content.length();
    edges[current][next].val = 1;
    edges[current][next].rule = new char[len];
    strncpy(edges[current][next].rule, content.c_str(), len);
}


int getTypeSNMP(char* rule){
    char* copy_rule = new char[strlen(rule)];
    const char* delim = "_1";
    char* token, *st;
    strncpy(copy_rule, rule, strlen(rule));
    st = copy_rule;
    token = strsep(&copy_rule, delim);
    token = strsep(&copy_rule, delim);
    token = strsep(&copy_rule, delim);

    if(strcmp(token, "request") == 0){
        delete(st);
        return 0xA0;
    }
    else if(strcmp(token, "response") == 0){
        delete(st);
        return 0xA2;
    }
    else {
        delete(st);
        return -1;
    }
}

/*
 * Type means whether the type of snmp is request or response
 */
int compare_objectId(char* content, char* rule){
    char* token;
    char* copy_rule = new char[strlen(rule)];
    char* st = copy_rule;
    strncpy(copy_rule, rule, strlen(rule));
    token = strsep(&copy_rule, "1");
    //This means that it starts with 1.3.
    if((content[20] & 0xFF) == 0x2b){
        copy_rule = copy_rule + 3; //Now rule starts pointing with 6
        content = content + 21;//content also starts with object id
        token = strsep(&copy_rule, ".");
        while((*content & 0xFF) != 0x00 && token != NULL){
            if((*content & 0xFF) == atoi(token)){
                content++;
                token = strsep(&copy_rule, ".");
            }
            else{
                delete(st);
                return false;
            }
        }
        delete(st);
        return true;
    }
    delete(st);
    return false;
}



//Currently only supporting ASN.1 header
bool Graph::transition_snmp(char* content){
    
    int type_snmp_content;    
    int length_community_name;

    //click_chatter("Content is %x", *content);
    //click_chatter("Number of vertices are %d", number_vertices);
    for(int i=0; i<number_vertices;i++){
        char* rule = edges[current_state][i].rule;
        if(rule == NULL){
            continue;
        }
        //click_chatter("Rule is %s", rule);
        length_community_name = (int)content[6];
        if((content[length_community_name+7] & 0xFF) != 0xa0 && ((content[length_community_name+7] & 0xFF) != 0xa2)){
            length_community_name = (int)content[8]+2;
        }
        //click_chatter("The length of community rule is %d", length_community_name);
        if((content[length_community_name + 7] & 0xFF) == getTypeSNMP(rule)){
            if(compare_objectId(&content[length_community_name+7], rule)){
                current_state = i;
                return true;
            }
        }
    }
    return false;
}
        //Type of get is same

        

/*If it doesn't contain a rule for that, then it will return false*/
bool Graph::transition(char* content){
   
    if(proto == SNMP){
        //click_chatter("Checking SNMP protocol");
        return transition_snmp(content);
    }        
    for(int i=0;i<number_vertices;i++){
        if(KMPSearch(edges[current_state][i].rule, content)){
            current_state = i;
            return true;
        }

   }
   return false;
}

void Graph::setCurrentState(int current_state){
    this->current_state = current_state;
}

void Graph::addState(){
    Edge e;
    e.val = 0;
    e.rule = NULL;
    vector<Edge> temp(number_vertices, e);
    this->number_vertices++;
    this->edges.push_back(temp);
    
    for(std::vector<vector<Edge> >::iterator it = edges.begin(); it != edges.end();
            ++it){
        (*it).push_back(e);
    }
}

void Graph::addHash(String key, String value){
    this->hash_map.insert(pair<String, String>(key, value));
}

String Graph::getHash(String key){
   if(hash_map.find(key) == hash_map.end()){
       return NULL;
   }
   else{
       return hash_map.find(key)->second; 
   }
}

void Graph::setProto(Protocol proto){
    this->proto = proto;
}

Protocol Graph::getProto(){
    return this->proto;
}

void Graph::printHashes(){
    for(map<String, String>::iterator it = hash_map.begin(); it!= hash_map.end(); it++){
        //click_chatter("Hash %s %s\n", (*it).first.c_str(), (*it).second.c_str());
    }
}

/*Support for accepting not added yet*/
void Gateway::parseFSM(FILE* fp, int protocol){
    char* line = NULL;
    size_t size = 0;
    int read;
    bool start_reading_states = false;
    bool start_reading_hashes = false;
    bool start_reading_initial_states = false;
    bool start_reading_transitions = false;
    bool start_reading_alphabets = false;
    size_t size_line;
    int counter = 0; //counter for states

    //Setting the protocol for transition functions
    g->setProto((Protocol)protocol);

    while((read = getline(&line,&size, fp)) != -1){

        size_line = strlen(line);
        //The only possible reason for the size of line to be 1 is only if its a
        //new line character
        if(strlen(line) == 1){
            continue;
        }
        if(line[size_line-1] == '\n'){
            line[size_line-1] = '\0';
        }

        if(strcmp(line, "#states") == 0){
            start_reading_states = true;
            start_reading_transitions = false;
            start_reading_alphabets = false;
            start_reading_initial_states = false;
            start_reading_hashes = false;
            continue;

        }

        if(strcmp(line, "#accepting") == 0){
            start_reading_states = false;
            start_reading_transitions = false;
            start_reading_alphabets = true;
            start_reading_initial_states = false;
            start_reading_hashes = false;
            continue;
        }

        if(strcmp(line, "#transitions") == 0){
            start_reading_states = false;
            start_reading_transitions = true;
            start_reading_alphabets = false;
            start_reading_initial_states = false;
            start_reading_hashes = false;
            continue;
        }

        if(strcmp(line, "#alphabets") == 0){
            start_reading_alphabets = true;
            start_reading_states = false;
            start_reading_transitions = false;
            start_reading_initial_states = false;
            start_reading_hashes = false;
            continue;
        }

        if(strcmp(line, "#initial") == 0){
            start_reading_alphabets = false;
            start_reading_transitions = false;
            start_reading_states = false;
            start_reading_initial_states = true;
            start_reading_hashes = false;
            continue;
        }
        if(strcmp(line, "#hashes") == 0){
            start_reading_hashes = true;
            start_reading_alphabets = false;
            start_reading_transitions = false;
            start_reading_states = false;
            start_reading_initial_states = false;
            continue;
        }

        if(start_reading_states){
            g->map_states.insert(pair<String,int>(String(line), counter++));
            g->map_states.insert(pair<String,int>(String(strcat(line, "t")), counter++));
            g->addState();
            g->addState();
            continue;
        }

        if(start_reading_transitions){
         /*  for(map<String, int>::iterator it = map_states.begin(); it!= map_states.end();
                   ++it){
               //click_chatter("Key %s val %d ", it->first.c_str(), it->second);
           }*/
           int start, target, temp;
           const char* delim = ":/>";
           char* token1, *token2, *target_state;
           String hash;
           token1 = strsep(&line, delim); //starting
           start = g->map_states.find(String(token1))->second;
           token2 = strsep(&line, "/");//first transition
           //click_chatter("Token2 is %s", token2);
           hash = g->getHash(String(token2));
           temp = g->map_states.find(String(strcat(token1, "t")))->second;
           g->addTransition(start, temp, hash);
           token2 = strsep(&line, delim);//second transition
           target_state = strsep(&line, delim);//final state
           
           target = g->map_states.find(String(target_state))->second;
           start = g->map_states.find(String(token1))->second; 
           g->addTransition(start, target, g->getHash(String(token2))); 
           continue;
        }

        if(start_reading_alphabets){
            //Don't know what to do
            continue;
        }
        
        if(start_reading_initial_states){
           g->setCurrentState(g->map_states.find(String(line))->second); 
           continue;
        }

        if(start_reading_hashes){
            const char* delim = ":";
            char* token1;
            token1 = strsep(&line, delim);
            line = line+1;//For the space that follows the colon
            g->addHash(String(token1), String(line));
        }
            
    }
}


Gateway::Gateway(){
    g = new Graph();
}

Gateway::~Gateway(){
    delete(g);
}

int Gateway::configure(Vector<String> &conf, ErrorHandler *errh){
    String path;
    int protocol;
    FILE* fp;

    if(Args(this, errh).bind(conf).read("FSMFILE", path).read("PROTOCOL", protocol).
            complete() < 0){
        //click_chatter("Error: Cannot read fsm from the file");
    }

    fp = fopen(path.c_str(), "r");

    parseFSM(fp, protocol); 
}




void Gateway::push(int port, Packet* p){
    
  //assert(p->has_network_header());
    
    const click_ip *iph = p->ip_header();
    const click_udp *udph = p->udp_header();
    char* content;
    
    //click_chatter("proto is %d", iph->ip_p);
    

    if(!udph){
        //click_chatter("here");
        output(0).push(p);
        return;
    }

    //click_chatter("udph is %x", udph);
    //click_chatter("length of udph is %d", ntohs(udph->uh_ulen));

    content = (char*)((char*)udph + sizeof(click_udp));
    //click_chatter("content is %x", content);
    //click_chatter("Value at content is %x", *content);
    //click_chatter("value at udph is %x", *udph);
    if(!this->g->transition(content)){
        output(0).push(p);
    }
    else{
        output(1).push(p);
    }
}


CLICK_ENDDECLS
EXPORT_ELEMENT(Gateway)

