`include "define.vh"

//+FHDR----------------------------------------------------------------
// FILE NAME : header_dec_dsb.v
// PURPOSE : Header decoder for the DSB router. Computes the output
// port request vector and extracts the destination ID
// based on XY routing. Designed to fit the pipeline
// stage 1.5 of the switch_router_dsb.
//---------------------------------------------------------------------
module header_dec_dsb (
    input rst,
    input [5:0] local_addr, // Local router's address {lx, ly}
    input valid, // Driven by ~empty_ififo, indicates valid flit at FIFO head
    input [`FLIT_LENGTH-1:0] inflit, // Input flit data from input FIFO
    output reg [4:0] request_vector, // The calculated output port request vector (one-hot)
    output reg [2:0] dest_id_out // The destination output port ID
);

// --- Internal Wires and Regs ---
wire x_eq; // Destination X-coordinate equals current X
wire y_eq; // Destination Y-coordinate equals current Y
wire x_mt; // Destination X-coordinate is greater than current X
wire y_mt; // Destination Y-coordinate is greater than current Y
wire [1:0] flit_type; // Type of the flit (HEAD, BODY, TAIL)
wire [5:0] des; // Destination address from flit
wire [2:0] des_x; // Destination X-coordinate from flit
wire [2:0] des_y; // Destination Y-coordinate from flit
wire [2:0] local_x; // Current router's X-coordinate
wire [2:0] local_y; // Current router's Y-coordinate

// --- Logic Assignments ---
// Deconstruct local_addr into X and Y coordinates
assign local_x = local_addr[5:3];
assign local_y = local_addr[2:0];

// Extract flit type and destination address from the incoming flit
assign flit_type = inflit[`FLIT_LENGTH-1 : `FLIT_LENGTH-2];
assign des = inflit[63:58]; // Destination address

// Calculate destination coordinates
assign des_x = des % `NoC_SIZE;
assign des_y = des / `NoC_SIZE;

// Compare destination coordinates with the router's local coordinates
assign x_mt = (des_x > local_x);
assign y_mt = (des_y > local_y);
assign x_eq = (des_x == local_x);
assign y_eq = (des_y == local_y);

// --- Routing Logic ---
// Determine the output port request vector and destination ID based on XY routing
// 按照 header_dec.v 的正確邏輯：S=0, W=1, N=2, E=3, P=4
always @(*) begin
    if (rst) begin
        request_vector = 5'b00000;
        dest_id_out = 3'd0; // Default to S port
    end
    // Decode only if it's a valid head flit
    else if (valid && (flit_type == `HEAD)) begin
        if (x_eq) begin
            if (y_eq) begin
                // Arrived at destination -> To Processor (P)
                request_vector = 5'b10000; // Request Port P (bit 4)
                dest_id_out = 3'd4; // P port ID
            end else if (y_mt) begin
                // Move South (S) - y_mt means destination y > current y, so go South
                request_vector = 5'b00001; // Request Port S (bit 0)
                dest_id_out = 3'd0; // S port ID
            end else begin
                // Move North (N) - destination y < current y, so go North
                request_vector = 5'b00100; // Request Port N (bit 2)
                dest_id_out = 3'd2; // N port ID
            end
        end else if (x_mt) begin
            // Move East (E) - x_mt means destination x > current x, so go East
            request_vector = 5'b01000; // Request Port E (bit 3)
            dest_id_out = 3'd3; // E port ID
        end else begin
            // Move West (W) - destination x < current x, so go West
            request_vector = 5'b00010; // Request Port W (bit 1)
            dest_id_out = 3'd1; // W port ID
        end
    end
    else begin
        // If not a valid head flit, do not assert any request
        request_vector = 5'b00000;
        dest_id_out = 3'd0; // Default to S port
    end
end

endmodule
