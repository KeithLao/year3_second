`include "define.vh"

`include "header_dec_dsb.v"
`include "fifo.v"
`include "switch5.v"
`include "pkg_arbiter5.v"

//+FHDR----------------------------------------------------------------
// (C)Copyright Company NTU GIEE ACCESS LAB
// All Right Reserved
//---------------------------------------------------------------------
// FILE NAME : switch_router_dsb.v
// PURPOSE: DSB (Distributed Shared Buffer) Router Implementation
// Based on the paper "Design of a High-Throughput Distributed 
// Shared-Buffer NoC Router" - Baseline Version with Dynamic Type Assignment
//---------------------------------------------------------------------
// RELEASE VERSION : V1
// VERSION DESCRIPTION : DSB routing with input buffering and middle memories
//                      with dynamic destination type assignment and conflict resolution
//---------------------------------------------------------------------
// PARAMETERS:
// PARAMETER NAME RANGE DESCRIPTION DEFAULT VALUE
//---------------------------------------------------------------------
// REUSE ISSUES: Credit-based flow control
// Reset Strategy: ASYNCHRONOUS RESET
// Clock Strategy: posedge trigger clock
//-FHDR----------------------------------------------------------------

module switch_router_dsb (
    clk, rst, lx, ly,
    P_datain, P_dataout, P_reqin, P_ackout, P_ackin, P_reqout,
    S_datain, S_dataout, S_reqin, S_ackout, S_ackin, S_reqout,
    W_datain, W_dataout, W_reqin, W_ackout, W_ackin, W_reqout,
    N_datain, N_dataout, N_reqin, N_ackout, N_ackin, N_reqout,
    E_datain, E_dataout, E_reqin, E_ackout, E_ackin, E_reqout
);

// Port declarations
input clk, rst;
input [2:0] lx, ly;

input P_reqin, P_ackout;
input S_reqin, S_ackout;
input W_reqin, W_ackout;
input N_reqin, N_ackout;
input E_reqin, E_ackout;

output P_ackin, P_reqout;
output S_ackin, S_reqout;
output W_ackin, W_reqout;
output N_ackin, N_reqout;
output E_ackin, E_reqout;

input [`FLIT_LENGTH-1:0] P_datain;
input [`FLIT_LENGTH-1:0] S_datain;
input [`FLIT_LENGTH-1:0] W_datain;
input [`FLIT_LENGTH-1:0] N_datain;
input [`FLIT_LENGTH-1:0] E_datain;

output [`FLIT_LENGTH-1:0] P_dataout;
output [`FLIT_LENGTH-1:0] S_dataout;
output [`FLIT_LENGTH-1:0] W_dataout;
output [`FLIT_LENGTH-1:0] N_dataout;
output [`FLIT_LENGTH-1:0] E_dataout;

//+CHDR----------------------------------------------------------------
// Wire declarations
//-CHDR----------------------------------------------------------------

// Input FIFO signals - 修正索引對應：S=0, W=1, N=2, E=3, P=4
wire [`FLIT_LENGTH-1:0] inflit0, inflit1, inflit2, inflit3, inflit4;
wire [4:0] empty_ififo, full_ififo, pop_ififo;

// Header decoder outputs - request vectors for routing
wire [4:0] request0, request1, request2, request3, request4;

// Middle Memory signals
wire [`FLIT_LENGTH-1:0] mm_dataout0, mm_dataout1, mm_dataout2, mm_dataout3, mm_dataout4;
wire [4:0] empty_mm, full_mm, pop_mm, push_mm;

// Middle Memory destination type tracking
reg [2:0] mm_dest_type [0:4];  // Each MM tracks its current destination type
reg [4:0] mm_type_valid;       // Whether each MM has a valid type assigned

// XB1 (Input to Middle Memory) arbitration - Input-centric approach
wire [4:0] req_from_input0, req_from_input1, req_from_input2, req_from_input3, req_from_input4;
wire [4:0] gnt_to_input0, gnt_to_input1, gnt_to_input2, gnt_to_input3, gnt_to_input4;
wire [4:0] anyGnt_input;

// XB2 (Middle Memory to Output) arbitration  
wire [4:0] req_to_out0, req_to_out1, req_to_out2, req_to_out3, req_to_out4;
wire [4:0] gnt_from_out0, gnt_from_out1, gnt_from_out2, gnt_from_out3, gnt_from_out4;
wire [4:0] anyGnt_out, clear_out;

// Crossbar data buses
wire [`FLIT_LENGTH:0] xb1_inbus0, xb1_inbus1, xb1_inbus2, xb1_inbus3, xb1_inbus4;
wire [`FLIT_LENGTH:0] xb1_outbus0, xb1_outbus1, xb1_outbus2, xb1_outbus3, xb1_outbus4;

wire [`FLIT_LENGTH:0] xb2_inbus0, xb2_inbus1, xb2_inbus2, xb2_inbus3, xb2_inbus4;
wire [`FLIT_LENGTH:0] xb2_outbus0, xb2_outbus1, xb2_outbus2, xb2_outbus3, xb2_outbus4;

// Final output flits
wire [`FLIT_LENGTH-1:0] outflit0, outflit1, outflit2, outflit3, outflit4;
wire [4:0] i_empty_out;

// Destination type extraction from request vectors
wire [2:0] dest_type0, dest_type1, dest_type2, dest_type3, dest_type4;

// Conflict resolution signals
wire [4:0] mm_compatible [0:4];  // mm_compatible[i][j] = 1 if input i is compatible with MM j
wire [4:0] final_mm_grant [0:4]; // final_mm_grant[i][j] = 1 if input i gets MM j

//+CHDR----------------------------------------------------------------
// Input stage: Input FIFOs and handshake logic
//-CHDR----------------------------------------------------------------

// Input handshake - acknowledge if FIFO not full and request is active
// 修正索引對應：S=0, W=1, N=2, E=3, P=4
assign S_ackin = (~full_ififo[0]) && S_reqin;
assign W_ackin = (~full_ififo[1]) && W_reqin;
assign N_ackin = (~full_ififo[2]) && N_reqin;
assign E_ackin = (~full_ififo[3]) && E_reqin;
assign P_ackin = (~full_ififo[4]) && P_reqin;

// Input FIFO instantiations
fifo S_ififo(.clk(clk), .rst(rst), .data_i(S_datain), .data_o(inflit0), 
             .push(S_ackin), .pop(pop_ififo[0] & (~empty_ififo[0])), 
             .empty(empty_ififo[0]), .full(full_ififo[0]));

fifo W_ififo(.clk(clk), .rst(rst), .data_i(W_datain), .data_o(inflit1), 
             .push(W_ackin), .pop(pop_ififo[1] & (~empty_ififo[1])), 
             .empty(empty_ififo[1]), .full(full_ififo[1]));

fifo N_ififo(.clk(clk), .rst(rst), .data_i(N_datain), .data_o(inflit2), 
             .push(N_ackin), .pop(pop_ififo[2] & (~empty_ififo[2])), 
             .empty(empty_ififo[2]), .full(full_ififo[2]));

fifo E_ififo(.clk(clk), .rst(rst), .data_i(E_datain), .data_o(inflit3), 
             .push(E_ackin), .pop(pop_ififo[3] & (~empty_ififo[3])), 
             .empty(empty_ififo[3]), .full(full_ififo[3]));

fifo P_ififo(.clk(clk), .rst(rst), .data_i(P_datain), .data_o(inflit4), 
             .push(P_ackin), .pop(pop_ififo[4] & (~empty_ififo[4])), 
             .empty(empty_ififo[4]), .full(full_ififo[4]));

//+CHDR----------------------------------------------------------------
// Route computation stage: Header decoders
//-CHDR----------------------------------------------------------------

header_dec_dsb u0_head(.rst(rst), .local_addr({lx,ly}), .valid(~empty_ififo[0]), 
                       .inflit(inflit0), .request_vector(request0), .dest_id_out());

header_dec_dsb u1_head(.rst(rst), .local_addr({lx,ly}), .valid(~empty_ififo[1]), 
                       .inflit(inflit1), .request_vector(request1), .dest_id_out());

header_dec_dsb u2_head(.rst(rst), .local_addr({lx,ly}), .valid(~empty_ififo[2]), 
                       .inflit(inflit2), .request_vector(request2), .dest_id_out());

header_dec_dsb u3_head(.rst(rst), .local_addr({lx,ly}), .valid(~empty_ififo[3]), 
                       .inflit(inflit3), .request_vector(request3), .dest_id_out());

header_dec_dsb u4_head(.rst(rst), .local_addr({lx,ly}), .valid(~empty_ififo[4]), 
                       .inflit(inflit4), .request_vector(request4), .dest_id_out());

// Extract destination type from request vectors (one-hot to binary)
assign dest_type0 = request0[0] ? 3'd0 : request0[1] ? 3'd1 : request0[2] ? 3'd2 : 
                    request0[3] ? 3'd3 : request0[4] ? 3'd4 : 3'd0;
assign dest_type1 = request1[0] ? 3'd0 : request1[1] ? 3'd1 : request1[2] ? 3'd2 : 
                    request1[3] ? 3'd3 : request1[4] ? 3'd4 : 3'd0;
assign dest_type2 = request2[0] ? 3'd0 : request2[1] ? 3'd1 : request2[2] ? 3'd2 : 
                    request2[3] ? 3'd3 : request2[4] ? 3'd4 : 3'd0;
assign dest_type3 = request3[0] ? 3'd0 : request3[1] ? 3'd1 : request3[2] ? 3'd2 : 
                    request3[3] ? 3'd3 : request3[4] ? 3'd4 : 3'd0;
assign dest_type4 = request4[0] ? 3'd0 : request4[1] ? 3'd1 : request4[2] ? 3'd2 : 
                    request4[3] ? 3'd3 : request4[4] ? 3'd4 : 3'd0;

//+CHDR----------------------------------------------------------------
// Middle Memory destination type management
//-CHDR----------------------------------------------------------------

// Update middle memory destination types
always @(posedge clk or posedge rst) begin
    if (rst) begin
        mm_dest_type[0] <= 3'd0;
        mm_dest_type[1] <= 3'd0;
        mm_dest_type[2] <= 3'd0;
        mm_dest_type[3] <= 3'd0;
        mm_dest_type[4] <= 3'd0;
        mm_type_valid <= 5'b00000;
    end else begin
        // Update MM0 type
        if (final_mm_grant[0][0] && anyGnt_input[0]) begin
            if (!mm_type_valid[0] || empty_mm[0]) begin
                mm_dest_type[0] <= dest_type0;
                mm_type_valid[0] <= 1'b1;
            end
        end else if (final_mm_grant[1][0] && anyGnt_input[1]) begin
            if (!mm_type_valid[0] || empty_mm[0]) begin
                mm_dest_type[0] <= dest_type1;
                mm_type_valid[0] <= 1'b1;
            end
        end else if (final_mm_grant[2][0] && anyGnt_input[2]) begin
            if (!mm_type_valid[0] || empty_mm[0]) begin
                mm_dest_type[0] <= dest_type2;
                mm_type_valid[0] <= 1'b1;
            end
        end else if (final_mm_grant[3][0] && anyGnt_input[3]) begin
            if (!mm_type_valid[0] || empty_mm[0]) begin
                mm_dest_type[0] <= dest_type3;
                mm_type_valid[0] <= 1'b1;
            end
        end else if (final_mm_grant[4][0] && anyGnt_input[4]) begin
            if (!mm_type_valid[0] || empty_mm[0]) begin
                mm_dest_type[0] <= dest_type4;
                mm_type_valid[0] <= 1'b1;
            end
        end else if (empty_mm[0]) begin
            mm_type_valid[0] <= 1'b0;
        end
        
        // Similar logic for MM1-MM4
        if (final_mm_grant[0][1] && anyGnt_input[0]) begin
            if (!mm_type_valid[1] || empty_mm[1]) begin
                mm_dest_type[1] <= dest_type0;
                mm_type_valid[1] <= 1'b1;
            end
        end else if (final_mm_grant[1][1] && anyGnt_input[1]) begin
            if (!mm_type_valid[1] || empty_mm[1]) begin
                mm_dest_type[1] <= dest_type1;
                mm_type_valid[1] <= 1'b1;
            end
        end else if (final_mm_grant[2][1] && anyGnt_input[2]) begin
            if (!mm_type_valid[1] || empty_mm[1]) begin
                mm_dest_type[1] <= dest_type2;
                mm_type_valid[1] <= 1'b1;
            end
        end else if (final_mm_grant[3][1] && anyGnt_input[3]) begin
            if (!mm_type_valid[1] || empty_mm[1]) begin
                mm_dest_type[1] <= dest_type3;
                mm_type_valid[1] <= 1'b1;
            end
        end else if (final_mm_grant[4][1] && anyGnt_input[4]) begin
            if (!mm_type_valid[1] || empty_mm[1]) begin
                mm_dest_type[1] <= dest_type4;
                mm_type_valid[1] <= 1'b1;
            end
        end else if (empty_mm[1]) begin
            mm_type_valid[1] <= 1'b0;
        end
        
        if (final_mm_grant[0][2] && anyGnt_input[0]) begin
            if (!mm_type_valid[2] || empty_mm[2]) begin
                mm_dest_type[2] <= dest_type0;
                mm_type_valid[2] <= 1'b1;
            end
        end else if (final_mm_grant[1][2] && anyGnt_input[1]) begin
            if (!mm_type_valid[2] || empty_mm[2]) begin
                mm_dest_type[2] <= dest_type1;
                mm_type_valid[2] <= 1'b1;
            end
        end else if (final_mm_grant[2][2] && anyGnt_input[2]) begin
            if (!mm_type_valid[2] || empty_mm[2]) begin
                mm_dest_type[2] <= dest_type2;
                mm_type_valid[2] <= 1'b1;
            end
        end else if (final_mm_grant[3][2] && anyGnt_input[3]) begin
            if (!mm_type_valid[2] || empty_mm[2]) begin
                mm_dest_type[2] <= dest_type3;
                mm_type_valid[2] <= 1'b1;
            end
        end else if (final_mm_grant[4][2] && anyGnt_input[4]) begin
            if (!mm_type_valid[2] || empty_mm[2]) begin
                mm_dest_type[2] <= dest_type4;
                mm_type_valid[2] <= 1'b1;
            end
        end else if (empty_mm[2]) begin
            mm_type_valid[2] <= 1'b0;
        end
        
        if (final_mm_grant[0][3] && anyGnt_input[0]) begin
            if (!mm_type_valid[3] || empty_mm[3]) begin
                mm_dest_type[3] <= dest_type0;
                mm_type_valid[3] <= 1'b1;
            end
        end else if (final_mm_grant[1][3] && anyGnt_input[1]) begin
            if (!mm_type_valid[3] || empty_mm[3]) begin
                mm_dest_type[3] <= dest_type1;
                mm_type_valid[3] <= 1'b1;
            end
        end else if (final_mm_grant[2][3] && anyGnt_input[2]) begin
            if (!mm_type_valid[3] || empty_mm[3]) begin
                mm_dest_type[3] <= dest_type2;
                mm_type_valid[3] <= 1'b1;
            end
        end else if (final_mm_grant[3][3] && anyGnt_input[3]) begin
            if (!mm_type_valid[3] || empty_mm[3]) begin
                mm_dest_type[3] <= dest_type3;
                mm_type_valid[3] <= 1'b1;
            end
        end else if (final_mm_grant[4][3] && anyGnt_input[4]) begin
            if (!mm_type_valid[3] || empty_mm[3]) begin
                mm_dest_type[3] <= dest_type4;
                mm_type_valid[3] <= 1'b1;
            end
        end else if (empty_mm[3]) begin
            mm_type_valid[3] <= 1'b0;
        end
        
        if (final_mm_grant[0][4] && anyGnt_input[0]) begin
            if (!mm_type_valid[4] || empty_mm[4]) begin
                mm_dest_type[4] <= dest_type0;
                mm_type_valid[4] <= 1'b1;
            end
        end else if (final_mm_grant[1][4] && anyGnt_input[1]) begin
            if (!mm_type_valid[4] || empty_mm[4]) begin
                mm_dest_type[4] <= dest_type1;
                mm_type_valid[4] <= 1'b1;
            end
        end else if (final_mm_grant[2][4] && anyGnt_input[2]) begin
            if (!mm_type_valid[4] || empty_mm[4]) begin
                mm_dest_type[4] <= dest_type2;
                mm_type_valid[4] <= 1'b1;
            end
        end else if (final_mm_grant[3][4] && anyGnt_input[3]) begin
            if (!mm_type_valid[4] || empty_mm[4]) begin
                mm_dest_type[4] <= dest_type3;
                mm_type_valid[4] <= 1'b1;
            end
        end else if (final_mm_grant[4][4] && anyGnt_input[4]) begin
            if (!mm_type_valid[4] || empty_mm[4]) begin
                mm_dest_type[4] <= dest_type4;
                mm_type_valid[4] <= 1'b1;
            end
        end else if (empty_mm[4]) begin
            mm_type_valid[4] <= 1'b0;
        end
    end
end

//+CHDR----------------------------------------------------------------
// XB1 stage: Input FIFO to Middle Memory arbitration and switching
//-CHDR----------------------------------------------------------------

// Step 1: Determine compatibility between inputs and middle memories
// Input i is compatible with MM j if:
// 1. Input i has data AND MM j has space
// 2. MM j is either empty/invalid OR MM j's type matches input i's destination type

assign mm_compatible[0][0] = (~empty_ififo[0]) && (~full_mm[0]) && (|request0) && 
                             (!mm_type_valid[0] || empty_mm[0] || (mm_dest_type[0] == dest_type0));
assign mm_compatible[0][1] = (~empty_ififo[0]) && (~full_mm[1]) && (|request0) && 
                             (!mm_type_valid[1] || empty_mm[1] || (mm_dest_type[1] == dest_type0));
assign mm_compatible[0][2] = (~empty_ififo[0]) && (~full_mm[2]) && (|request0) && 
                             (!mm_type_valid[2] || empty_mm[2] || (mm_dest_type[2] == dest_type0));
assign mm_compatible[0][3] = (~empty_ififo[0]) && (~full_mm[3]) && (|request0) && 
                             (!mm_type_valid[3] || empty_mm[3] || (mm_dest_type[3] == dest_type0));
assign mm_compatible[0][4] = (~empty_ififo[0]) && (~full_mm[4]) && (|request0) && 
                             (!mm_type_valid[4] || empty_mm[4] || (mm_dest_type[4] == dest_type0));

assign mm_compatible[1][0] = (~empty_ififo[1]) && (~full_mm[0]) && (|request1) && 
                             (!mm_type_valid[0] || empty_mm[0] || (mm_dest_type[0] == dest_type1));
assign mm_compatible[1][1] = (~empty_ififo[1]) && (~full_mm[1]) && (|request1) && 
                             (!mm_type_valid[1] || empty_mm[1] || (mm_dest_type[1] == dest_type1));
assign mm_compatible[1][2] = (~empty_ififo[1]) && (~full_mm[2]) && (|request1) && 
                             (!mm_type_valid[2] || empty_mm[2] || (mm_dest_type[2] == dest_type1));
assign mm_compatible[1][3] = (~empty_ififo[1]) && (~full_mm[3]) && (|request1) && 
                             (!mm_type_valid[3] || empty_mm[3] || (mm_dest_type[3] == dest_type1));
assign mm_compatible[1][4] = (~empty_ififo[1]) && (~full_mm[4]) && (|request1) && 
                             (!mm_type_valid[4] || empty_mm[4] || (mm_dest_type[4] == dest_type1));

assign mm_compatible[2][0] = (~empty_ififo[2]) && (~full_mm[0]) && (|request2) && 
                             (!mm_type_valid[0] || empty_mm[0] || (mm_dest_type[0] == dest_type2));
assign mm_compatible[2][1] = (~empty_ififo[2]) && (~full_mm[1]) && (|request2) && 
                             (!mm_type_valid[1] || empty_mm[1] || (mm_dest_type[1] == dest_type2));
assign mm_compatible[2][2] = (~empty_ififo[2]) && (~full_mm[2]) && (|request2) && 
                             (!mm_type_valid[2] || empty_mm[2] || (mm_dest_type[2] == dest_type2));
assign mm_compatible[2][3] = (~empty_ififo[2]) && (~full_mm[3]) && (|request2) && 
                             (!mm_type_valid[3] || empty_mm[3] || (mm_dest_type[3] == dest_type2));
assign mm_compatible[2][4] = (~empty_ififo[2]) && (~full_mm[4]) && (|request2) && 
                             (!mm_type_valid[4] || empty_mm[4] || (mm_dest_type[4] == dest_type2));

assign mm_compatible[3][0] = (~empty_ififo[3]) && (~full_mm[0]) && (|request3) && 
                             (!mm_type_valid[0] || empty_mm[0] || (mm_dest_type[0] == dest_type3));
assign mm_compatible[3][1] = (~empty_ififo[3]) && (~full_mm[1]) && (|request3) && 
                             (!mm_type_valid[1] || empty_mm[1] || (mm_dest_type[1] == dest_type3));
assign mm_compatible[3][2] = (~empty_ififo[3]) && (~full_mm[2]) && (|request3) && 
                             (!mm_type_valid[2] || empty_mm[2] || (mm_dest_type[2] == dest_type3));
assign mm_compatible[3][3] = (~empty_ififo[3]) && (~full_mm[3]) && (|request3) && 
                             (!mm_type_valid[3] || empty_mm[3] || (mm_dest_type[3] == dest_type3));
assign mm_compatible[3][4] = (~empty_ififo[3]) && (~full_mm[4]) && (|request3) && 
                             (!mm_type_valid[4] || empty_mm[4] || (mm_dest_type[4] == dest_type3));

assign mm_compatible[4][0] = (~empty_ififo[4]) && (~full_mm[0]) && (|request4) && 
                             (!mm_type_valid[0] || empty_mm[0] || (mm_dest_type[0] == dest_type4));
assign mm_compatible[4][1] = (~empty_ififo[4]) && (~full_mm[1]) && (|request4) && 
                             (!mm_type_valid[1] || empty_mm[1] || (mm_dest_type[1] == dest_type4));
assign mm_compatible[4][2] = (~empty_ififo[4]) && (~full_mm[2]) && (|request4) && 
                             (!mm_type_valid[2] || empty_mm[2] || (mm_dest_type[2] == dest_type4));
assign mm_compatible[4][3] = (~empty_ififo[4]) && (~full_mm[3]) && (|request4) && 
                             (!mm_type_valid[3] || empty_mm[3] || (mm_dest_type[3] == dest_type4));
assign mm_compatible[4][4] = (~empty_ififo[4]) && (~full_mm[4]) && (|request4) && 
                             (!mm_type_valid[4] || empty_mm[4] || (mm_dest_type[4] == dest_type4));

// Step 2: Input arbiters - each input arbitrates among compatible middle memories
pkg_arbiter5 u_input0_arb(.clk(clk), .rst(rst), .req(mm_compatible[0]), .Gnt(gnt_to_input0), 
                          .anyGnt(anyGnt_input[0]), .clear(1'b0));

pkg_arbiter5 u_input1_arb(.clk(clk), .rst(rst), .req(mm_compatible[1]), .Gnt(gnt_to_input1), 
                          .anyGnt(anyGnt_input[1]), .clear(1'b0));

pkg_arbiter5 u_input2_arb(.clk(clk), .rst(rst), .req(mm_compatible[2]), .Gnt(gnt_to_input2), 
                          .anyGnt(anyGnt_input[2]), .clear(1'b0));

pkg_arbiter5 u_input3_arb(.clk(clk), .rst(rst), .req(mm_compatible[3]), .Gnt(gnt_to_input3), 
                          .anyGnt(anyGnt_input[3]), .clear(1'b0));

pkg_arbiter5 u_input4_arb(.clk(clk), .rst(rst), .req(mm_compatible[4]), .Gnt(gnt_to_input4), 
                          .anyGnt(anyGnt_input[4]), .clear(1'b0));

// Step 3: Resolve conflicts - ensure no two inputs get the same middle memory
// Priority-based conflict resolution: Input 0 has highest priority, Input 4 has lowest

assign final_mm_grant[0] = gnt_to_input0;

assign final_mm_grant[1][0] = gnt_to_input1[0] & ~final_mm_grant[0][0];
assign final_mm_grant[1][1] = gnt_to_input1[1] & ~final_mm_grant[0][1];
assign final_mm_grant[1][2] = gnt_to_input1[2] & ~final_mm_grant[0][2];
assign final_mm_grant[1][3] = gnt_to_input1[3] & ~final_mm_grant[0][3];
assign final_mm_grant[1][4] = gnt_to_input1[4] & ~final_mm_grant[0][4];

assign final_mm_grant[2][0] = gnt_to_input2[0] & ~final_mm_grant[0][0] & ~final_mm_grant[1][0];
assign final_mm_grant[2][1] = gnt_to_input2[1] & ~final_mm_grant[0][1] & ~final_mm_grant[1][1];
assign final_mm_grant[2][2] = gnt_to_input2[2] & ~final_mm_grant[0][2] & ~final_mm_grant[1][2];
assign final_mm_grant[2][3] = gnt_to_input2[3] & ~final_mm_grant[0][3] & ~final_mm_grant[1][3];
assign final_mm_grant[2][4] = gnt_to_input2[4] & ~final_mm_grant[0][4] & ~final_mm_grant[1][4];

assign final_mm_grant[3][0] = gnt_to_input3[0] & ~final_mm_grant[0][0] & ~final_mm_grant[1][0] & ~final_mm_grant[2][0];
assign final_mm_grant[3][1] = gnt_to_input3[1] & ~final_mm_grant[0][1] & ~final_mm_grant[1][1] & ~final_mm_grant[2][1];
assign final_mm_grant[3][2] = gnt_to_input3[2] & ~final_mm_grant[0][2] & ~final_mm_grant[1][2] & ~final_mm_grant[2][2];
assign final_mm_grant[3][3] = gnt_to_input3[3] & ~final_mm_grant[0][3] & ~final_mm_grant[1][3] & ~final_mm_grant[2][3];
assign final_mm_grant[3][4] = gnt_to_input3[4] & ~final_mm_grant[0][4] & ~final_mm_grant[1][4] & ~final_mm_grant[2][4];

assign final_mm_grant[4][0] = gnt_to_input4[0] & ~final_mm_grant[0][0] & ~final_mm_grant[1][0] & ~final_mm_grant[2][0] & ~final_mm_grant[3][0];
assign final_mm_grant[4][1] = gnt_to_input4[1] & ~final_mm_grant[0][1] & ~final_mm_grant[1][1] & ~final_mm_grant[2][1] & ~final_mm_grant[3][1];
assign final_mm_grant[4][2] = gnt_to_input4[2] & ~final_mm_grant[0][2] & ~final_mm_grant[1][2] & ~final_mm_grant[2][2] & ~final_mm_grant[3][2];
assign final_mm_grant[4][3] = gnt_to_input4[3] & ~final_mm_grant[0][3] & ~final_mm_grant[1][3] & ~final_mm_grant[2][3] & ~final_mm_grant[3][3];
assign final_mm_grant[4][4] = gnt_to_input4[4] & ~final_mm_grant[0][4] & ~final_mm_grant[1][4] & ~final_mm_grant[2][4] & ~final_mm_grant[3][4];

// Update anyGnt_input based on final grants
assign anyGnt_input[0] = |final_mm_grant[0];
assign anyGnt_input[1] = |final_mm_grant[1];
assign anyGnt_input[2] = |final_mm_grant[2];
assign anyGnt_input[3] = |final_mm_grant[3];
assign anyGnt_input[4] = |final_mm_grant[4];

// XB1 input buses preparation
assign xb1_inbus0 = {empty_ififo[0], inflit0};
assign xb1_inbus1 = {empty_ififo[1], inflit1};
assign xb1_inbus2 = {empty_ififo[2], inflit2};
assign xb1_inbus3 = {empty_ififo[3], inflit3};
assign xb1_inbus4 = {empty_ififo[4], inflit4};

// XB1 switches - route input data to middle memories based on final grants
switch5 #(.DATA_WIDTH(`FLIT_LENGTH+1)) uXB1_mm0(.data0(xb1_inbus0), .data1(xb1_inbus1), 
        .data2(xb1_inbus2), .data3(xb1_inbus3), .data4(xb1_inbus4), 
        .Gnt({final_mm_grant[4][0], final_mm_grant[3][0], final_mm_grant[2][0], final_mm_grant[1][0], final_mm_grant[0][0]}), 
        .dataout(xb1_outbus0));

switch5 #(.DATA_WIDTH(`FLIT_LENGTH+1)) uXB1_mm1(.data0(xb1_inbus0), .data1(xb1_inbus1), 
        .data2(xb1_inbus2), .data3(xb1_inbus3), .data4(xb1_inbus4), 
        .Gnt({final_mm_grant[4][1], final_mm_grant[3][1], final_mm_grant[2][1], final_mm_grant[1][1], final_mm_grant[0][1]}), 
        .dataout(xb1_outbus1));

switch5 #(.DATA_WIDTH(`FLIT_LENGTH+1)) uXB1_mm2(.data0(xb1_inbus0), .data1(xb1_inbus1), 
        .data2(xb1_inbus2), .data3(xb1_inbus3), .data4(xb1_inbus4), 
        .Gnt({final_mm_grant[4][2], final_mm_grant[3][2], final_mm_grant[2][2], final_mm_grant[1][2], final_mm_grant[0][2]}), 
        .dataout(xb1_outbus2));

switch5 #(.DATA_WIDTH(`FLIT_LENGTH+1)) uXB1_mm3(.data0(xb1_inbus0), .data1(xb1_inbus1), 
        .data2(xb1_inbus2), .data3(xb1_inbus3), .data4(xb1_inbus4), 
        .Gnt({final_mm_grant[4][3], final_mm_grant[3][3], final_mm_grant[2][3], final_mm_grant[1][3], final_mm_grant[0][3]}), 
        .dataout(xb1_outbus3));

switch5 #(.DATA_WIDTH(`FLIT_LENGTH+1)) uXB1_mm4(.data0(xb1_inbus0), .data1(xb1_inbus1), 
        .data2(xb1_inbus2), .data3(xb1_inbus3), .data4(xb1_inbus4), 
        .Gnt({final_mm_grant[4][4], final_mm_grant[3][4], final_mm_grant[2][4], final_mm_grant[1][4], final_mm_grant[0][4]}), 
        .dataout(xb1_outbus4));

// Pop input FIFOs when data is successfully transferred to middle memory
assign pop_ififo = anyGnt_input;

// Push middle memory FIFOs when data is received from input
assign push_mm[0] = |{final_mm_grant[4][0], final_mm_grant[3][0], final_mm_grant[2][0], final_mm_grant[1][0], final_mm_grant[0][0]};
assign push_mm[1] = |{final_mm_grant[4][1], final_mm_grant[3][1], final_mm_grant[2][1], final_mm_grant[1][1], final_mm_grant[0][1]};
assign push_mm[2] = |{final_mm_grant[4][2], final_mm_grant[3][2], final_mm_grant[2][2], final_mm_grant[1][2], final_mm_grant[0][2]};
assign push_mm[3] = |{final_mm_grant[4][3], final_mm_grant[3][3], final_mm_grant[2][3], final_mm_grant[1][3], final_mm_grant[0][3]};
assign push_mm[4] = |{final_mm_grant[4][4], final_mm_grant[3][4], final_mm_grant[2][4], final_mm_grant[1][4], final_mm_grant[0][4]};

//+CHDR----------------------------------------------------------------
// Middle Memory stage: FIFO buffers
//-CHDR----------------------------------------------------------------

fifo mm0_fifo(.clk(clk), .rst(rst), .data_i(xb1_outbus0[`FLIT_LENGTH-1:0]), .data_o(mm_dataout0), 
              .push(push_mm[0] & (~xb1_outbus0[`FLIT_LENGTH])), .pop(pop_mm[0] & (~empty_mm[0])), 
              .empty(empty_mm[0]), .full(full_mm[0]));

fifo mm1_fifo(.clk(clk), .rst(rst), .data_i(xb1_outbus1[`FLIT_LENGTH-1:0]), .data_o(mm_dataout1), 
              .push(push_mm[1] & (~xb1_outbus1[`FLIT_LENGTH])), .pop(pop_mm[1] & (~empty_mm[1])), 
              .empty(empty_mm[1]), .full(full_mm[1]));

fifo mm2_fifo(.clk(clk), .rst(rst), .data_i(xb1_outbus2[`FLIT_LENGTH-1:0]), .data_o(mm_dataout2), 
              .push(push_mm[2] & (~xb1_outbus2[`FLIT_LENGTH])), .pop(pop_mm[2] & (~empty_mm[2])), 
              .empty(empty_mm[2]), .full(full_mm[2]));

fifo mm3_fifo(.clk(clk), .rst(rst), .data_i(xb1_outbus3[`FLIT_LENGTH-1:0]), .data_o(mm_dataout3), 
              .push(push_mm[3] & (~xb1_outbus3[`FLIT_LENGTH])), .pop(pop_mm[3] & (~empty_mm[3])), 
              .empty(empty_mm[3]), .full(full_mm[3]));

fifo mm4_fifo(.clk(clk), .rst(rst), .data_i(xb1_outbus4[`FLIT_LENGTH-1:0]), .data_o(mm_dataout4), 
              .push(push_mm[4] & (~xb1_outbus4[`FLIT_LENGTH])), .pop(pop_mm[4] & (~empty_mm[4])), 
              .empty(empty_mm[4]), .full(full_mm[4]));

//+CHDR----------------------------------------------------------------
// XB2 stage: Middle Memory to Output arbitration and switching
//-CHDR----------------------------------------------------------------

// Request generation for output port access based on middle memory destination types
assign req_to_out0[0] = (~empty_mm[0]) && mm_type_valid[0] && (mm_dest_type[0] == 3'd0);
assign req_to_out0[1] = (~empty_mm[1]) && mm_type_valid[1] && (mm_dest_type[1] == 3'd0);
assign req_to_out0[2] = (~empty_mm[2]) && mm_type_valid[2] && (mm_dest_type[2] == 3'd0);
assign req_to_out0[3] = (~empty_mm[3]) && mm_type_valid[3] && (mm_dest_type[3] == 3'd0);
assign req_to_out0[4] = (~empty_mm[4]) && mm_type_valid[4] && (mm_dest_type[4] == 3'd0);

assign req_to_out1[0] = (~empty_mm[0]) && mm_type_valid[0] && (mm_dest_type[0] == 3'd1);
assign req_to_out1[1] = (~empty_mm[1]) && mm_type_valid[1] && (mm_dest_type[1] == 3'd1);
assign req_to_out1[2] = (~empty_mm[2]) && mm_type_valid[2] && (mm_dest_type[2] == 3'd1);
assign req_to_out1[3] = (~empty_mm[3]) && mm_type_valid[3] && (mm_dest_type[3] == 3'd1);
assign req_to_out1[4] = (~empty_mm[4]) && mm_type_valid[4] && (mm_dest_type[4] == 3'd1);

assign req_to_out2[0] = (~empty_mm[0]) && mm_type_valid[0] && (mm_dest_type[0] == 3'd2);
assign req_to_out2[1] = (~empty_mm[1]) && mm_type_valid[1] && (mm_dest_type[1] == 3'd2);
assign req_to_out2[2] = (~empty_mm[2]) && mm_type_valid[2] && (mm_dest_type[2] == 3'd2);
assign req_to_out2[3] = (~empty_mm[3]) && mm_type_valid[3] && (mm_dest_type[3] == 3'd2);
assign req_to_out2[4] = (~empty_mm[4]) && mm_type_valid[4] && (mm_dest_type[4] == 3'd2);

assign req_to_out3[0] = (~empty_mm[0]) && mm_type_valid[0] && (mm_dest_type[0] == 3'd3);
assign req_to_out3[1] = (~empty_mm[1]) && mm_type_valid[1] && (mm_dest_type[1] == 3'd3);
assign req_to_out3[2] = (~empty_mm[2]) && mm_type_valid[2] && (mm_dest_type[2] == 3'd3);
assign req_to_out3[3] = (~empty_mm[3]) && mm_type_valid[3] && (mm_dest_type[3] == 3'd3);
assign req_to_out3[4] = (~empty_mm[4]) && mm_type_valid[4] && (mm_dest_type[4] == 3'd3);

assign req_to_out4[0] = (~empty_mm[0]) && mm_type_valid[0] && (mm_dest_type[0] == 3'd4);
assign req_to_out4[1] = (~empty_mm[1]) && mm_type_valid[1] && (mm_dest_type[1] == 3'd4);
assign req_to_out4[2] = (~empty_mm[2]) && mm_type_valid[2] && (mm_dest_type[2] == 3'd4);
assign req_to_out4[3] = (~empty_mm[3]) && mm_type_valid[3] && (mm_dest_type[3] == 3'd4);
assign req_to_out4[4] = (~empty_mm[4]) && mm_type_valid[4] && (mm_dest_type[4] == 3'd4);

// Output port arbiters
pkg_arbiter5 u_out0_arb(.clk(clk), .rst(rst), .req(req_to_out0), .Gnt(gnt_from_out0), 
                        .anyGnt(anyGnt_out[0]), .clear(clear_out[0]));

pkg_arbiter5 u_out1_arb(.clk(clk), .rst(rst), .req(req_to_out1), .Gnt(gnt_from_out1), 
                        .anyGnt(anyGnt_out[1]), .clear(clear_out[1]));

pkg_arbiter5 u_out2_arb(.clk(clk), .rst(rst), .req(req_to_out2), .Gnt(gnt_from_out2), 
                        .anyGnt(anyGnt_out[2]), .clear(clear_out[2]));

pkg_arbiter5 u_out3_arb(.clk(clk), .rst(rst), .req(req_to_out3), .Gnt(gnt_from_out3), 
                        .anyGnt(anyGnt_out[3]), .clear(clear_out[3]));

pkg_arbiter5 u_out4_arb(.clk(clk), .rst(rst), .req(req_to_out4), .Gnt(gnt_from_out4), 
                        .anyGnt(anyGnt_out[4]), .clear(clear_out[4]));

// XB2 input buses preparation
assign xb2_inbus0 = {empty_mm[0], mm_dataout0};
assign xb2_inbus1 = {empty_mm[1], mm_dataout1};
assign xb2_inbus2 = {empty_mm[2], mm_dataout2};
assign xb2_inbus3 = {empty_mm[3], mm_dataout3};
assign xb2_inbus4 = {empty_mm[4], mm_dataout4};

// XB2 switches
switch5 #(.DATA_WIDTH(`FLIT_LENGTH+1)) uXB2_out0(.data0(xb2_inbus0), .data1(xb2_inbus1), 
        .data2(xb2_inbus2), .data3(xb2_inbus3), .data4(xb2_inbus4), 
        .Gnt(gnt_from_out0), .dataout(xb2_outbus0));

switch5 #(.DATA_WIDTH(`FLIT_LENGTH+1)) uXB2_out1(.data0(xb2_inbus0), .data1(xb2_inbus1), 
        .data2(xb2_inbus2), .data3(xb2_inbus3), .data4(xb2_inbus4), 
        .Gnt(gnt_from_out1), .dataout(xb2_outbus1));

switch5 #(.DATA_WIDTH(`FLIT_LENGTH+1)) uXB2_out2(.data0(xb2_inbus0), .data1(xb2_inbus1), 
        .data2(xb2_inbus2), .data3(xb2_inbus3), .data4(xb2_inbus4), 
        .Gnt(gnt_from_out2), .dataout(xb2_outbus2));

switch5 #(.DATA_WIDTH(`FLIT_LENGTH+1)) uXB2_out3(.data0(xb2_inbus0), .data1(xb2_inbus1), 
        .data2(xb2_inbus2), .data3(xb2_inbus3), .data4(xb2_inbus4), 
        .Gnt(gnt_from_out3), .dataout(xb2_outbus3));

switch5 #(.DATA_WIDTH(`FLIT_LENGTH+1)) uXB2_out4(.data0(xb2_inbus0), .data1(xb2_inbus1), 
        .data2(xb2_inbus2), .data3(xb2_inbus3), .data4(xb2_inbus4), 
        .Gnt(gnt_from_out4), .dataout(xb2_outbus4));

// Extract output data and empty signals
assign {i_empty_out[0], outflit0} = xb2_outbus0;
assign {i_empty_out[1], outflit1} = xb2_outbus1;
assign {i_empty_out[2], outflit2} = xb2_outbus2;
assign {i_empty_out[3], outflit3} = xb2_outbus3;
assign {i_empty_out[4], outflit4} = xb2_outbus4;

// Pop middle memory FIFOs when data is successfully sent to output
assign pop_mm[0] = (gnt_from_out0[0] & anyGnt_out[0] & S_ackout) | 
                   (gnt_from_out1[0] & anyGnt_out[1] & W_ackout) | 
                   (gnt_from_out2[0] & anyGnt_out[2] & N_ackout) | 
                   (gnt_from_out3[0] & anyGnt_out[3] & E_ackout) | 
                   (gnt_from_out4[0] & anyGnt_out[4] & P_ackout);

assign pop_mm[1] = (gnt_from_out0[1] & anyGnt_out[0] & S_ackout) | 
                   (gnt_from_out1[1] & anyGnt_out[1] & W_ackout) | 
                   (gnt_from_out2[1] & anyGnt_out[2] & N_ackout) | 
                   (gnt_from_out3[1] & anyGnt_out[3] & E_ackout) | 
                   (gnt_from_out4[1] & anyGnt_out[4] & P_ackout);

assign pop_mm[2] = (gnt_from_out0[2] & anyGnt_out[0] & S_ackout) | 
                   (gnt_from_out1[2] & anyGnt_out[1] & W_ackout) | 
                   (gnt_from_out2[2] & anyGnt_out[2] & N_ackout) | 
                   (gnt_from_out3[2] & anyGnt_out[3] & E_ackout) | 
                   (gnt_from_out4[2] & anyGnt_out[4] & P_ackout);

assign pop_mm[3] = (gnt_from_out0[3] & anyGnt_out[0] & S_ackout) | 
                   (gnt_from_out1[3] & anyGnt_out[1] & W_ackout) | 
                   (gnt_from_out2[3] & anyGnt_out[2] & N_ackout) | 
                   (gnt_from_out3[3] & anyGnt_out[3] & E_ackout) | 
                   (gnt_from_out4[3] & anyGnt_out[4] & P_ackout);

assign pop_mm[4] = (gnt_from_out0[4] & anyGnt_out[0] & S_ackout) | 
                   (gnt_from_out1[4] & anyGnt_out[1] & W_ackout) | 
                   (gnt_from_out2[4] & anyGnt_out[2] & N_ackout) | 
                   (gnt_from_out3[4] & anyGnt_out[3] & E_ackout) | 
                   (gnt_from_out4[4] & anyGnt_out[4] & P_ackout);

// Clear arbiters on TAIL flit acknowledgment
assign clear_out[0] = (outflit0[`FLIT_LENGTH-1:`FLIT_LENGTH-2] == `TAIL) && S_ackout && anyGnt_out[0];
assign clear_out[1] = (outflit1[`FLIT_LENGTH-1:`FLIT_LENGTH-2] == `TAIL) && W_ackout && anyGnt_out[1];
assign clear_out[2] = (outflit2[`FLIT_LENGTH-1:`FLIT_LENGTH-2] == `TAIL) && N_ackout && anyGnt_out[2];
assign clear_out[3] = (outflit3[`FLIT_LENGTH-1:`FLIT_LENGTH-2] == `TAIL) && E_ackout && anyGnt_out[3];
assign clear_out[4] = (outflit4[`FLIT_LENGTH-1:`FLIT_LENGTH-2] == `TAIL) && P_ackout && anyGnt_out[4];

//+CHDR----------------------------------------------------------------
// Output connections - 修正端口映射，確保正確的輸出方向
//-CHDR----------------------------------------------------------------

// 正確的端口映射：S=0, W=1, N=2, E=3, P=4
assign S_dataout = outflit0;
assign W_dataout = outflit1;
assign N_dataout = outflit2;
assign E_dataout = outflit3;
assign P_dataout = outflit4;

assign S_reqout = anyGnt_out[0] & ~i_empty_out[0];
assign W_reqout = anyGnt_out[1] & ~i_empty_out[1];
assign N_reqout = anyGnt_out[2] & ~i_empty_out[2];
assign E_reqout = anyGnt_out[3] & ~i_empty_out[3];
assign P_reqout = anyGnt_out[4] & ~i_empty_out[4];

endmodule
