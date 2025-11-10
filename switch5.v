`include "define.vh"

module switch5 #(
    parameter DATA_WIDTH = 36, // Default value, will be overridden during instantiation
    parameter NUM_INPUTS = 5
) (
    input [DATA_WIDTH-1:0] data0,
    input [DATA_WIDTH-1:0] data1,
    input [DATA_WIDTH-1:0] data2,
    input [DATA_WIDTH-1:0] data3,
    input [DATA_WIDTH-1:0] data4,
    input [NUM_INPUTS-1:0] Gnt,
    output reg [DATA_WIDTH-1:0] dataout
);

always@(*) begin
    // Use the one-hot grant signal to select which input data to pass to the output.
    case(Gnt)
        5'b00001: dataout = data0;
        5'b00010: dataout = data1;
        5'b00100: dataout = data2;
        5'b01000: dataout = data3;
        5'b10000: dataout = data4;
        default:  dataout = {DATA_WIDTH{1'bz}}; // If no grant is active, output is high-impedance.
    endcase
end

endmodule