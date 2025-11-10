`timescale 1ns/10ps

`include "define.vh" // Make sure FLIT_LENGTH is defined here
`include "PATTERN.v"  // Assuming PATTERN.v is adapted or designed for the mesh P-ports

`ifdef RTL
  `include "switch_router_dsb.v"
`endif
`ifdef GATE
  `include "switch_router_SYN_dsb.v"
`endif

module TESTBED;

    wire clk, rst;

    // Router Coordinates
    wire [2:0] M0lx, M0ly; // Router (0,0)
    wire [2:0] M1lx, M1ly; // Router (0,1)
    wire [2:0] M2lx, M2ly; // Router (1,0)
    wire [2:0] M3lx, M3ly; // Router (1,1)

    // P-port interfaces for PATTERN module (one for each router)
    wire P0_reqin, P0_ackout;
    wire P0_ackin, P0_reqout;
    wire [`FLIT_LENGTH-1:0] P0_datain;
    wire [`FLIT_LENGTH-1:0] P0_dataout;

    wire P1_reqin, P1_ackout;
    wire P1_ackin, P1_reqout;
    wire [`FLIT_LENGTH-1:0] P1_datain;
    wire [`FLIT_LENGTH-1:0] P1_dataout;

    wire P2_reqin, P2_ackout;
    wire P2_ackin, P2_reqout;
    wire [`FLIT_LENGTH-1:0] P2_datain;
    wire [`FLIT_LENGTH-1:0] P2_dataout;

    wire P3_reqin, P3_ackout;
    wire P3_ackin, P3_reqout;
    wire [`FLIT_LENGTH-1:0] P3_datain;
    wire [`FLIT_LENGTH-1:0] P3_dataout;

    // Internal Mesh Connection Wires
    // M0.E <-> M1.W
    wire [`FLIT_LENGTH-1:0] data_M0E_to_M1W, data_M1W_to_M0E;
    wire req_M0E_to_M1W, req_M1W_to_M0E;
    wire ack_M1W_to_M0E, ack_M0E_to_M1W;

    // M0.S <-> M2.N
    wire [`FLIT_LENGTH-1:0] data_M0S_to_M2N, data_M2N_to_M0S;
    wire req_M0S_to_M2N, req_M2N_to_M0S;
    wire ack_M2N_to_M0S, ack_M0S_to_M2N;

    // M1.S <-> M3.N
    wire [`FLIT_LENGTH-1:0] data_M1S_to_M3N, data_M3N_to_M1S;
    wire req_M1S_to_M3N, req_M3N_to_M1S;
    wire ack_M3N_to_M1S, ack_M1S_to_M3N;

    // M2.E <-> M3.W
    wire [`FLIT_LENGTH-1:0] data_M2E_to_M3W, data_M3W_to_M2E;
    wire req_M2E_to_M3W, req_M3W_to_M2E;
    wire ack_M3W_to_M2E, ack_M2E_to_M3W;

    // Wires for unused output ports (to prevent floating port warnings from some linters, though not strictly necessary for outputs)
    wire M0_N_reqout_u, M0_N_ackout_u; wire [`FLIT_LENGTH-1:0] M0_N_dataout_u;
    wire M0_W_reqout_u, M0_W_ackout_u; wire [`FLIT_LENGTH-1:0] M0_W_dataout_u;

    wire M1_N_reqout_u, M1_N_ackout_u; wire [`FLIT_LENGTH-1:0] M1_N_dataout_u;
    wire M1_E_reqout_u, M1_E_ackout_u; wire [`FLIT_LENGTH-1:0] M1_E_dataout_u;

    wire M2_S_reqout_u, M2_S_ackout_u; wire [`FLIT_LENGTH-1:0] M2_S_dataout_u;
    wire M2_W_reqout_u, M2_W_ackout_u; wire [`FLIT_LENGTH-1:0] M2_W_dataout_u;

    wire M3_S_reqout_u, M3_S_ackout_u; wire [`FLIT_LENGTH-1:0] M3_S_dataout_u;
    wire M3_E_reqout_u, M3_E_ackout_u; wire [`FLIT_LENGTH-1:0] M3_E_dataout_u;


    initial begin
      `ifdef RTL
        $fsdbDumpfile("switch_router_dsb.fsdb");
        $fsdbDumpvars(0,"+mda"); // Dump all vars in TESTBED_MESH and instances below
        
      `endif
      `ifdef GATE
        // For multiple instances, SDF annotation needs to be done for each.
        // Assuming one SDF file for the switch_router_dsb module definition.
        // Adjust path/filename as necessary.
        $sdf_annotate("switch_router_SYN_dsb.sdf", M0);
        $sdf_annotate("switch_router_SYN_dsb.sdf", M1);
        $sdf_annotate("switch_router_SYN_dsb.sdf", M2);
        $sdf_annotate("switch_router_SYN_dsb.sdf", M3);
        $fsdbDumpfile("switch_router_SYN_dsb.fsdb");
        $fsdbDumpvars(0,"+mda");

      `endif
    end

    // Instantiate Routers
    // Router M0 (0,0)
    switch_router_dsb M0 (
        .clk(clk), .rst(rst), .lx(M0lx), .ly(M0ly),
        .P_datain(P0_datain), .P_dataout(P0_dataout), .P_reqin(P0_reqin), .P_ackout(P0_ackout), .P_ackin(P0_ackin), .P_reqout(P0_reqout),
        .S_datain(data_M2N_to_M0S), .S_dataout(data_M0S_to_M2N), .S_reqin(req_M2N_to_M0S), .S_ackout(ack_M0S_to_M2N), .S_ackin(ack_M2N_to_M0S), .S_reqout(req_M0S_to_M2N),
        .W_datain(`FLIT_LENGTH'b0), .W_dataout(M0_W_dataout_u), .W_reqin(1'b0), .W_ackout(M0_W_ackout_u), .W_ackin(1'b0), .W_reqout(M0_W_reqout_u),
        .N_datain(`FLIT_LENGTH'b0), .N_dataout(M0_N_dataout_u), .N_reqin(1'b0), .N_ackout(M0_N_ackout_u), .N_ackin(1'b0), .N_reqout(M0_N_reqout_u),
        .E_datain(data_M1W_to_M0E), .E_dataout(data_M0E_to_M1W), .E_reqin(req_M1W_to_M0E), .E_ackout(ack_M0E_to_M1W), .E_ackin(ack_M1W_to_M0E), .E_reqout(req_M0E_to_M1W)
    );

    // Router M1 (0,1)
    switch_router_dsb M1 (
        .clk(clk), .rst(rst), .lx(M1lx), .ly(M1ly),
        .P_datain(P1_datain), .P_dataout(P1_dataout), .P_reqin(P1_reqin), .P_ackout(P1_ackout), .P_ackin(P1_ackin), .P_reqout(P1_reqout),
        .S_datain(data_M3N_to_M1S), .S_dataout(data_M1S_to_M3N), .S_reqin(req_M3N_to_M1S), .S_ackout(ack_M1S_to_M3N), .S_ackin(ack_M3N_to_M1S), .S_reqout(req_M1S_to_M3N),
        .W_datain(data_M0E_to_M1W), .W_dataout(data_M1W_to_M0E), .W_reqin(req_M0E_to_M1W), .W_ackout(ack_M1W_to_M0E), .W_ackin(ack_M0E_to_M1W), .W_reqout(req_M1W_to_M0E),
        .N_datain(`FLIT_LENGTH'b0), .N_dataout(M1_N_dataout_u), .N_reqin(1'b0), .N_ackout(M1_N_ackout_u), .N_ackin(1'b0), .N_reqout(M1_N_reqout_u),
        .E_datain(`FLIT_LENGTH'b0), .E_dataout(M1_E_dataout_u), .E_reqin(1'b0), .E_ackout(M1_E_ackout_u), .E_ackin(1'b0), .E_reqout(M1_E_reqout_u)
    );

    // Router M2 (1,0)
    switch_router_dsb M2 (
        .clk(clk), .rst(rst), .lx(M2lx), .ly(M2ly),
        .P_datain(P2_datain), .P_dataout(P2_dataout), .P_reqin(P2_reqin), .P_ackout(P2_ackout), .P_ackin(P2_ackin), .P_reqout(P2_reqout),
        .S_datain(`FLIT_LENGTH'b0), .S_dataout(M2_S_dataout_u), .S_reqin(1'b0), .S_ackout(M2_S_ackout_u), .S_ackin(1'b0), .S_reqout(M2_S_reqout_u),
        .W_datain(`FLIT_LENGTH'b0), .W_dataout(M2_W_dataout_u), .W_reqin(1'b0), .W_ackout(M2_W_ackout_u), .W_ackin(1'b0), .W_reqout(M2_W_reqout_u),
        .N_datain(data_M0S_to_M2N), .N_dataout(data_M2N_to_M0S), .N_reqin(req_M0S_to_M2N), .N_ackout(ack_M2N_to_M0S), .N_ackin(ack_M0S_to_M2N), .N_reqout(req_M2N_to_M0S),
        .E_datain(data_M3W_to_M2E), .E_dataout(data_M2E_to_M3W), .E_reqin(req_M3W_to_M2E), .E_ackout(ack_M2E_to_M3W), .E_ackin(ack_M3W_to_M2E), .E_reqout(req_M2E_to_M3W)
    );

    // Router M3 (1,1)
    switch_router_dsb M3 (
        .clk(clk), .rst(rst), .lx(M3lx), .ly(M3ly),
        .P_datain(P3_datain), .P_dataout(P3_dataout), .P_reqin(P3_reqin), .P_ackout(P3_ackout), .P_ackin(P3_ackin), .P_reqout(P3_reqout),
        .S_datain(`FLIT_LENGTH'b0), .S_dataout(M3_S_dataout_u), .S_reqin(1'b0), .S_ackout(M3_S_ackout_u), .S_ackin(1'b0), .S_reqout(M3_S_reqout_u),
        .W_datain(data_M2E_to_M3W), .W_dataout(data_M3W_to_M2E), .W_reqin(req_M2E_to_M3W), .W_ackout(ack_M3W_to_M2E), .W_ackin(ack_M2E_to_M3W), .W_reqout(req_M3W_to_M2E),
        .N_datain(data_M1S_to_M3N), .N_dataout(data_M3N_to_M1S), .N_reqin(req_M1S_to_M3N), .N_ackout(ack_M3N_to_M1S), .N_ackin(ack_M1S_to_M3N), .N_reqout(req_M3N_to_M1S),
        .E_datain(`FLIT_LENGTH'b0), .E_dataout(M3_E_dataout_u), .E_reqin(1'b0), .E_ackout(M3_E_ackout_u), .E_ackin(1'b0), .E_reqout(M3_E_reqout_u)
    );

    // PATTERN Instantiation
    PATTERN u_PATTERN(
        .clk(clk), .rst(rst),
        .M0lx(M0lx), .M0ly(M0ly), .M1lx(M1lx), .M1ly(M1ly),
        .M2lx(M2lx), .M2ly(M2ly), .M3lx(M3lx), .M3ly(M3ly),

        .P0_datain(P0_datain), .P0_dataout(P0_dataout), .P0_reqin(P0_reqin), .P0_ackout(P0_ackout), .P0_ackin(P0_ackin), .P0_reqout(P0_reqout),
        .P1_datain(P1_datain), .P1_dataout(P1_dataout), .P1_reqin(P1_reqin), .P1_ackout(P1_ackout), .P1_ackin(P1_ackin), .P1_reqout(P1_reqout),
        .P2_datain(P2_datain), .P2_dataout(P2_dataout), .P2_reqin(P2_reqin), .P2_ackout(P2_ackout), .P2_ackin(P2_ackin), .P2_reqout(P2_reqout),
        .P3_datain(P3_datain), .P3_dataout(P3_dataout), .P3_reqin(P3_reqin), .P3_ackout(P3_ackout), .P3_ackin(P3_ackin), .P3_reqout(P3_reqout)
    );

endmodule