`include "define.vh"

module fifo(
	input  clk,
	input  rst,
	input  [`FLIT_LENGTH-1:0] data_i,
	output [`FLIT_LENGTH-1:0] data_o,
	input  push,
	input  pop,
	output empty,
	output full
);

reg [`FIFO_DEPTH:0] r_ptr, w_ptr;
reg [`FLIT_LENGTH-1:0] buffer [0:`FIFO_SIZE-1];
wire match;

always@( posedge clk or posedge rst ) begin		// w_ptr, when push = 1, w_ptr = w_ptr + 1
	if ( rst )
		w_ptr <= 0;
	else if ( push )
		w_ptr <= w_ptr + 1;
end

always@( posedge clk ) begin
	if ( push )
		buffer[w_ptr[`FIFO_DEPTH-1:0]] <= data_i;
end

always@( posedge clk or posedge rst ) begin		// r_ptr, when pop = 1, r_ptr = r_ptr + 1
	if ( rst )
		r_ptr <= 0;
	else if ( pop )
		r_ptr <= r_ptr + 1;
end
		
assign data_o = buffer[r_ptr[`FIFO_DEPTH-1:0]];

assign match = (w_ptr[`FIFO_DEPTH-1:0] == r_ptr[`FIFO_DEPTH-1:0]) ? 1'b1 : 1'b0;
assign empty = match && (w_ptr[`FIFO_DEPTH] == r_ptr[`FIFO_DEPTH]);
assign full  = match && (w_ptr[`FIFO_DEPTH] != r_ptr[`FIFO_DEPTH]);
  
endmodule
