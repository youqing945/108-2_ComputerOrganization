#include<iostream>
#include<string>
#include<math.h>
#include<queue>
#include<stack>
#include<list>
#include<vector>
using namespace std;

void direct_mapped(FILE *inputfile, FILE *outputfile, int cachesize, int blocksize);
void fourway_associative(FILE *inputfile, FILE *outputfile, int cachesize, int blocksize, int policy);
void fully_associative(FILE *inputfile, FILE *outputfile, int cachesize, int blocksize, int policy);

int main(int argc, char *argv[]){

    //open two files.
    FILE *inputfile, *outputfile;
    inputfile = fopen(argv[1], "r"); //the file must exist.
    outputfile = fopen(argv[2], "w"); 
    if(inputfile == NULL) perror("Error opening file");
    else{
        //get arguments in trace.txt.
        char buffer[100];
        fgets(buffer, 100, inputfile);
        int cachesize = atoi(buffer);       //cache ize
        fgets(buffer, 100, inputfile);
        int blocksize = atoi(buffer);       //block size
        fgets(buffer, 100, inputfile);
        int associativity = atoi(buffer);   //0:direct-mapped 1:four-way set 2:fully
        fgets(buffer, 100, inputfile);
        int policy = atoi(buffer);          //0:FIFO 1:LRU 2:Your policy(LIFO)

        if(associativity == 0){
            direct_mapped(inputfile, outputfile, cachesize, blocksize);
        }
        else if(associativity == 1){
            fourway_associative(inputfile, outputfile, cachesize, blocksize, policy);
        }
        else if(associativity == 2){
            fully_associative(inputfile, outputfile, cachesize, blocksize, policy);
        }
        else{
            cout<<"Fail to read the file \""<<argv[1]<<"\". Please check it.\n";
            return 0;
        }


        //finish message.
        cout<<"\ncache size: "<<cachesize<<" KB\n";
        cout<<"block size: "<<blocksize<< " byte\n";
        cout<<"associativity: ";
        if(associativity == 0) cout<<"direct-mapped";
        else if(associativity == 1) cout<<"four-way set associative";
        else if(associativity == 2) cout<<"fully associative";
        cout<<"\nreplace algorithm: ";
        if(policy == 0) cout<<"FIFO";
        else if(policy == 1) cout<<"LRU";
        else if(policy == 2) cout<<"My policy --- LIFO";
        cout<<"\n";
        cout<<"Compute end.\n\n";
    }

    //close two files.
    fclose(inputfile);
    fclose(outputfile);
    cout<<"Files are closed.\n";
    cout<<"Please check the output file \""<<argv[2]<<"\".\n\n";
    
    return 0;
}

//direct-mapped
void direct_mapped(FILE *inputfile, FILE *outputfile, int cachesize, int blocksize){
    char buffer[100];
    int offset = log2(blocksize); //offset = lg(block size) 
    int index = log2(cachesize)+10-offset;
    int tag = 32-(offset+index);
    int set = pow(2, index);

    int cache[set]; //store tags
    for(int i = 0; i<set; i++) cache[i] = -1;

    while (!feof(inputfile)){
        if(fgets(buffer, 100, inputfile)==NULL) break;

        //get address in binary
        int address[32];
        for(int i = 0; i<8; i++){
            int temp = buffer[2+i]-48;
            if(temp > 9) temp = temp-39;
            for(int j = 3; j>=0; j--){
                address[4*i+j] = temp % 2;
                temp = temp / 2;
            }
        }
        
        //get index and tag
        int inputindex = 0;
        int inputtag = 0;
        for(int i = 0; i<tag; i++) inputtag = inputtag + address[tag-1-i]*pow(2, i);
        for(int i = 0; i<index; i++) inputindex = inputindex + address[tag+index-1-i]*pow(2, i);
        
        //see if hit or miss
        if(cache[inputindex] == -1){ //not used yet
            fputs("-1", outputfile);
            cache[inputindex] = inputtag;
        }
        else{
            if(cache[inputindex] == inputtag){ //no change
                fputs("-1", outputfile);
            }
            else{ //change
                char str[32];
                //itoa(cache[inputindex], str, 10);
                sprintf(str, "%d", cache[inputindex]);
                fputs(str, outputfile);
                cache[inputindex] = inputtag;
            }
        }
        fputs("\n", outputfile);
    }

}

//4-way associative
void fourway_associative(FILE *inputfile, FILE *outputfile, int cachesize, int blocksize, int policy){
    char buffer[100];
    int offset = log2(blocksize); //offset = lg(block size) 
    int index = log2(cachesize)+10-offset-2;
    int tag = 32-(offset+index);
    int set = pow(2, index);

    int cache[set][4]; //store tags

    queue<int> tempq;
    vector<queue<int>> fifo(set, tempq);

    list<int> templ;
    vector<list<int>> lru(set, templ);

    stack<int> temps;
    vector<stack<int>> lifo(set, temps);

    for(int i = 0; i<set; i++){
        for(int j = 0; j<4; j++){
            cache[i][j] = -1;
        }
    }

    while (!feof(inputfile)){
        if(fgets(buffer, 100, inputfile)==NULL) break;

        //get address in binary
        int address[32];
        for(int i = 0; i<8; i++){
            int temp = buffer[2+i]-48;
            if(temp > 9) temp = temp-39;
            for(int j = 3; j>=0; j--){
                address[4*i+j] = temp % 2;
                temp = temp / 2;
            }
        }
        
        //get index and tag
        int inputindex = 0;
        int inputtag = 0;
        for(int i = 0; i<tag; i++) inputtag = inputtag + address[tag-1-i]*pow(2, i);
        for(int i = 0; i<index; i++) inputindex = inputindex + address[tag+index-1-i]*pow(2, i);

        //see if hit or miss
        int fin = 0;
        for(int i = 0; i<4; i++){
            if(cache[inputindex][i] == -1 || cache[inputindex][i] == inputtag){ //not used yet or no change
                fputs("-1", outputfile);
                if(cache[inputindex][i] == -1){
                    cache[inputindex][i] = inputtag;
                    if(policy == 0) fifo[inputindex].push(inputtag);
                    else if(policy == 1) lru[inputindex].push_back(inputtag);
                    else if(policy == 2) lifo[inputindex].push(inputtag);
                }
                else{
                    if(policy == 1){
                        lru[inputindex].remove(inputtag);
                        lru[inputindex].push_back(inputtag);
                    }
                }

                fin = 1;
                break;
            }
        }

        if(fin != 1){ //replace
            if(policy == 0){ //FIFO queue
                char str[32];
                sprintf(str, "%d", fifo[inputindex].front());
                fputs(str, outputfile);

                for(int i = 0; i<4; i++){
                    if(cache[inputindex][i] == fifo[inputindex].front()){
                        cache[inputindex][i] = inputtag;
                        fifo[inputindex].pop();
                        fifo[inputindex].push(inputtag);
                        break;
                    }
                }
            }
            else if(policy == 1){ //LRU list
                char str[32];
                sprintf(str, "%d", lru[inputindex].front());
                fputs(str, outputfile);

                for(int i = 0; i<4; i++){
                    if(cache[inputindex][i] == lru[inputindex].front()){
                        cache[inputindex][i] = inputtag;
                        lru[inputindex].pop_front();
                        lru[inputindex].push_back(inputtag);
                        break;
                    }
                }
            }
            else if(policy == 2){ //LIFO stack
                char str[32];
                sprintf(str, "%d", lifo[inputindex].top());
                fputs(str, outputfile);

                for(int i = 0; i<4; i++){
                    if(cache[inputindex][i] == lifo[inputindex].top()){
                        cache[inputindex][i] = inputtag;
                        lifo[inputindex].pop();
                        lifo[inputindex].push(inputtag);
                        break;
                    }
                }
            }
        }
        
        fputs("\n", outputfile);
    }
}

//fully associative
void fully_associative(FILE *inputfile, FILE *outputfile, int cachesize, int blocksize, int policy){
    char buffer[100];
    int offset = log2(blocksize); //offset = lg(block size) 
    int index = 0;
    int tag = 32-(offset+index);
    int way = pow(2, log2(cachesize)+10-offset);

    int cache[way]; //store tags

    queue<int> fifo;
    list<int> lru;
    stack<int> lifo;

    for(int i = 0; i<way; i++) cache[i] = -1;

    while (!feof(inputfile)){
        if(fgets(buffer, 100, inputfile)==NULL) break;

        //get address in binary
        int address[32];
        for(int i = 0; i<8; i++){
            int temp = buffer[2+i]-48;
            if(temp > 9) temp = temp-39;
            for(int j = 3; j>=0; j--){
                address[4*i+j] = temp % 2;
                temp = temp / 2;
            }
        }
        
        //get tag
        int inputtag = 0;
        for(int i = 0; i<tag; i++) inputtag = inputtag + address[tag-1-i]*pow(2, i);

        //see if hit or miss
        int fin = 0;
        for(int i = 0; i<way; i++){
            if(cache[i] == -1 || cache[i] == inputtag){ //not used yet or no change
                fputs("-1", outputfile);
                if(cache[i] == -1){
                    cache[i] = inputtag;
                    if(policy == 0) fifo.push(inputtag);
                    else if(policy == 1) lru.push_back(inputtag);
                    else if(policy == 2) lifo.push(inputtag);
                }
                else{
                    if(policy == 1){
                        lru.remove(inputtag);
                        lru.push_back(inputtag);
                    }
                }

                fin = 1;
                break;
            }
        }

        if(fin != 1){ //replace
            if(policy == 0){ //FIFO queue
                char str[32];
                sprintf(str, "%d", fifo.front());
                fputs(str, outputfile);

                for(int i = 0; i<way; i++){
                    if(cache[i] == fifo.front()){
                        cache[i] = inputtag;
                        fifo.pop();
                        fifo.push(inputtag);
                        break;
                    }
                }
            }
            else if(policy == 1){ //LRU list
                char str[32];
                sprintf(str, "%d", lru.front());
                fputs(str, outputfile);

                for(int i = 0; i<way; i++){
                    if(cache[i] == lru.front()){
                        cache[i] = inputtag;
                        lru.pop_front();
                        lru.push_back(inputtag);
                        break;
                    }
                }
            }
            else if(policy == 2){ //LIFO stack
                char str[32];
                sprintf(str, "%d", lifo.top());
                fputs(str, outputfile);

                for(int i = 0; i<way; i++){
                    if(cache[i] == lifo.top()){
                        cache[i] = inputtag;
                        lifo.pop();
                        lifo.push(inputtag);
                        break;
                    }
                }
            }
        }
        
        fputs("\n", outputfile);
    }
}
