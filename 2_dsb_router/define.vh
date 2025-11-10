`timescale 1ns/10ps
`define CYCLE_TIME 20.0

`define FLIT_LENGTH  72	
/* 
	71-70: header
	69-64: src
	63-58: dest
	57-0: data
*/
`define SID 3'd0
`define WID 3'd1
`define NID 3'd2
`define EID 3'd3
`define PID 3'd4 // Local Processor Port

`define HEAD  2'b10
`define BODY  2'b11
`define TAIL  2'b01

`define FIFO_SIZE 8 // 8
`define FIFO_DEPTH 3 // 3

`define NoC_SIZE  8


