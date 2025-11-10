`timescale 1ns/10ps

`include "define.vh"

`include "PATTERN.v"
`ifdef RTL
  `include "switch_router_dsb.v"
`endif
`ifdef GATE
  `include "switch_router_dsb_SYN.v"
`endif

	  		  	
module TESTBED;

    wire clk, rst;
    wire [2:0] lx, ly;
    wire P_reqin, P_ackout;
    wire S_reqin, S_ackout;
    wire W_reqin, W_ackout;
    wire N_reqin, N_ackout;
    wire E_reqin, E_ackout;

    wire P_ackin, P_reqout;
    wire S_ackin, S_reqout;
    wire W_ackin, W_reqout;
    wire N_ackin, N_reqout;
    wire E_ackin, E_reqout;

    wire [`FLIT_LENGTH-1:0] P_datain;
    wire [`FLIT_LENGTH-1:0] S_datain;
    wire [`FLIT_LENGTH-1:0] W_datain;
    wire [`FLIT_LENGTH-1:0] N_datain;
    wire [`FLIT_LENGTH-1:0] E_datain;

    wire [`FLIT_LENGTH-1:0] P_dataout;
    wire [`FLIT_LENGTH-1:0] S_dataout;
    wire [`FLIT_LENGTH-1:0] W_dataout;
    wire [`FLIT_LENGTH-1:0] N_dataout;
    wire [`FLIT_LENGTH-1:0] E_dataout;


initial begin
  `ifdef RTL
    $fsdbDumpfile("switch_router_dsb.fsdb");
    $fsdbDumpvars(0,"+mda");
  
  `endif
  `ifdef GATE
    $sdf_annotate("switch_router_dsb_SYN.sdf", u_switch_router_dsb);
    $fsdbDumpfile("switch_router_dsb_SYN.fsdb");
    $fsdbDumpvars(0,"+mda");   
  `endif
end

`ifdef RTL
switch_router_dsb u_switch_router_dsb(
    .clk(clk), .rst(rst), .lx(lx), .ly(ly),
	.P_datain(P_datain), .P_dataout(P_dataout), .P_reqin(P_reqin), .P_ackout(P_ackout), .P_ackin(P_ackin), .P_reqout(P_reqout),
	.S_datain(S_datain), .S_dataout(S_dataout), .S_reqin(S_reqin), .S_ackout(S_ackout), .S_ackin(S_ackin), .S_reqout(S_reqout),
	.W_datain(W_datain), .W_dataout(W_dataout), .W_reqin(W_reqin), .W_ackout(W_ackout), .W_ackin(W_ackin), .W_reqout(W_reqout),
	.N_datain(N_datain), .N_dataout(N_dataout), .N_reqin(N_reqin), .N_ackout(N_ackout), .N_ackin(N_ackin), .N_reqout(N_reqout),
	.E_datain(E_datain), .E_dataout(E_dataout), .E_reqin(E_reqin), .E_ackout(E_ackout), .E_ackin(E_ackin), .E_reqout(E_reqout)
    );
`endif

`ifdef GATE
switch_router_dsb u_switch_router_dsb(
    .clk(clk), .rst(rst), .lx(lx), .ly(ly),
	.P_datain(P_datain), .P_dataout(P_dataout), .P_reqin(P_reqin), .P_ackout(P_ackout), .P_ackin(P_ackin), .P_reqout(P_reqout),
	.S_datain(S_datain), .S_dataout(S_dataout), .S_reqin(S_reqin), .S_ackout(S_ackout), .S_ackin(S_ackin), .S_reqout(S_reqout),
	.W_datain(W_datain), .W_dataout(W_dataout), .W_reqin(W_reqin), .W_ackout(W_ackout), .W_ackin(W_ackin), .W_reqout(W_reqout),
	.N_datain(N_datain), .N_dataout(N_dataout), .N_reqin(N_reqin), .N_ackout(N_ackout), .N_ackin(N_ackin), .N_reqout(N_reqout),
	.E_datain(E_datain), .E_dataout(E_dataout), .E_reqin(E_reqin), .E_ackout(E_ackout), .E_ackin(E_ackin), .E_reqout(E_reqout)
    );
`endif

PATTERN u_PATTERN(
    .clk(clk), .rst(rst), .lx(lx), .ly(ly),
	.P_datain(P_datain), .P_dataout(P_dataout), .P_reqin(P_reqin), .P_ackout(P_ackout), .P_ackin(P_ackin), .P_reqout(P_reqout),
	.S_datain(S_datain), .S_dataout(S_dataout), .S_reqin(S_reqin), .S_ackout(S_ackout), .S_ackin(S_ackin), .S_reqout(S_reqout),
	.W_datain(W_datain), .W_dataout(W_dataout), .W_reqin(W_reqin), .W_ackout(W_ackout), .W_ackin(W_ackin), .W_reqout(W_reqout),
	.N_datain(N_datain), .N_dataout(N_dataout), .N_reqin(N_reqin), .N_ackout(N_ackout), .N_ackin(N_ackin), .N_reqout(N_reqout),
	.E_datain(E_datain), .E_dataout(E_dataout), .E_reqin(E_reqin), .E_ackout(E_ackout), .E_ackin(E_ackin), .E_reqout(E_reqout)
    );
  
endmodule
