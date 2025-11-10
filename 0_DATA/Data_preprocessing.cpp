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

// Use queue<string> for each direction
queue<string> memory[5];  // 0: Processor, 1: South, 2: West, 3: North, 4: East

string HEAD = "10";
string BODY = "11";
string TAIL = "01";

string toBinaryString(int val, int bits) {
    string res = bitset<64>(val).to_string();  
    return res.substr(64 - bits);            
}

int pointer(const string& line) {
    if (line == "Processor") return 0;
    if (line == "South") return 1;
    if (line == "West") return 2;
    if (line == "North") return 3;
    if (line == "East") return 4;
}

void generateflit(int time, int srcx, int srcy, int destx, int desty, const string& dir) {
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
        memory[pointer(dir)].push(flit);
    }
}

void parseInput(ifstream& in) {
    string line, direction;
    int idx, time, srcx, srcy, destx, desty;

    while (in >> line) {
        if (line == ".flit_bit") {
            in >> flit_bit;
        } else if (line == ".local_place") {
            in >> localx >> localy;
        } else if (line == ".request") {
        	while(getline(in, line)){
        		
	            istringstream iss(line);
				iss >> idx >> time >> srcy >> srcx >> desty >> destx;
	
	            if (srcx == localx && srcy == localy) {
	                direction = "Processor";
	            } else if (srcx == localx) {
	                direction = (srcy > localy) ? "South" : "North";
	            } else {
	                direction = (srcx > localx) ? "East" : "West";
	            }
				
				if(idx != 0){
					cout << "line: " << line << endl;
					cout << idx << endl;
					generateflit(time, srcx, srcy, destx, desty, direction);
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

void parseOutput(ofstream& out, const string& dir) {
    int idx = pointer(dir);
    while (!memory[idx].empty()) {
        out << memory[idx].front() << endl;
        memory[idx].pop();
    }
}

int main() {
    ifstream in("I_in.dat");
    
    ofstream outP("0_Processor_direction_in.dat");
    ofstream outS("1_South_direction_in.dat");
    ofstream outW("2_West_direction_in.dat");
    ofstream outN("3_North_direction_in.dat");
    ofstream outE("4_East_direction_in.dat");

    parseInput(in);

	Padding();
	
    parseOutput(outP, "Processor");
    parseOutput(outS, "South");
    parseOutput(outW, "West");
    parseOutput(outN, "North");
    parseOutput(outE, "East");

    return 0;
}
