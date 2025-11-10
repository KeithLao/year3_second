#include <bits/stdc++.h>
using namespace std;

// Global parameters
int flit_bit;
int localx, localy;
int src_dest_bit = 6;
int packet_length = 1;
int header_bit = 2;
int num_bit = 16;
int num = 0;
int memory_Padding_num = 32;

// Use queue<string> for each mesh
queue<string> memory[4];  // M0 M1 M2 M3

string HEAD = "10";
string BODY = "11";
string TAIL = "01";

string toBinaryString(int val, int bits) {
    string res = bitset<64>(val).to_string();  
    return res.substr(64 - bits);            
}


void generateflit(int time, int srcx, int srcy, int destx, int desty, int idx) {
    int src_bit = src_dest_bit / 2;
    int dest_bit = src_dest_bit / 2;
    int left_bit = flit_bit - 2 * src_dest_bit - header_bit - num_bit;

    for (int i = 1; i <= packet_length; ++i) {
        string header;
        if (i == 1) header = HEAD;
        else if (i == packet_length) header = TAIL;
        else header = BODY;

        string flit = header
                    + toBinaryString(srcy, src_bit)
                    + toBinaryString(srcx, src_bit)
                    + toBinaryString(desty, dest_bit)
                    + toBinaryString(destx, dest_bit)
                    + toBinaryString(time, left_bit)
                    + toBinaryString(num, num_bit);
        
        num++;
        memory[idx].push(flit);
    }
}

void parseInput(ifstream& in) {
    string line;
    int idx, time, srcx, srcy, destx, desty;
    int place;

    while (in >> line) {
        if (line == ".flit_bit") {
            in >> flit_bit;
        } else if (line == ".local_place") {
            in >> localx >> localy;
        } else if (line == ".request") {
        	while(getline(in, line)){
        		
	            istringstream iss(line);
				iss >> idx >> time >> srcy >> srcx >> desty >> destx;
	
	            if (srcx == 0 && srcy == 0) {
	                place = 0;
	            } else if (srcx == 1 && srcy == 0) {
	                place = 1;
	            } else if (srcx == 0 && srcy == 1) {
	                place = 2;
	            } else if (srcx == 1 && srcy == 1) {
	                place = 3;
	            }
	            
				if(idx != 0){
					cout << "line: " << line << endl;
					cout << idx << endl;
					generateflit(time, srcx, srcy, destx, desty, place);
				}
	    	}
        }
    }
}

void Padding() {
    for (int i = 0; i < 5; ++i) {
        while (memory[i].size() < memory_Padding_num) {
            string zero_flit(flit_bit, '0');
            memory[i].push(zero_flit);
        }
    }
}

void parseOutput(ofstream& out, int idx) {
    while (!memory[idx].empty()) {
        out << memory[idx].front() << endl;
        memory[idx].pop();
    }
}

int main() {
    ifstream in("I_in.dat");
    
    ofstream out0("0_Mesh0_in.dat");
    ofstream out1("1_Mesh1_in.dat");
    ofstream out2("2_Mesh2_in.dat");
    ofstream out3("3_Mesh3_in.dat");

    parseInput(in);

	Padding();
	
    parseOutput(out0, 0);
    parseOutput(out1, 1);
    parseOutput(out2, 2);
    parseOutput(out3, 3);

    return 0;
}
