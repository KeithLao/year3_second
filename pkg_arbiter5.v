`include "define.vh"

// A parameterized 5-input Round-Robin package arbiter
module pkg_arbiter5 #(
    parameter NUM_REQUESTERS = 5
) (
    input clk,
    input rst,
    input [NUM_REQUESTERS-1:0] req,
    output [NUM_REQUESTERS-1:0] Gnt,
    output anyGnt,
    input clear
);

    // Internal registers for priority tracking
    reg [NUM_REQUESTERS-1:0] last_grant;
    
    // Combinational logic for grant generation
    wire [NUM_REQUESTERS-1:0] grant_next;
    wire [NUM_REQUESTERS-1:0] req_masked;
    wire [NUM_REQUESTERS-1:0] req_unmasked;
    wire any_req_masked;
    
    // Update last_grant register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            last_grant <= 5'b00000;
        end else if (clear || (anyGnt && |req)) begin
            last_grant <= grant_next;
        end
    end
    
    // Mask requests based on last grant for round-robin behavior
    assign req_masked = req & ~((last_grant - 1'b1) | last_grant);
    assign any_req_masked = |req_masked;
    
    // Choose between masked and unmasked requests
    assign req_unmasked = any_req_masked ? req_masked : req;
    
    // Priority encoder - grant to lowest index requester
    assign grant_next[0] = req_unmasked[0];
    assign grant_next[1] = req_unmasked[1] & ~req_unmasked[0];
    assign grant_next[2] = req_unmasked[2] & ~(|req_unmasked[1:0]);
    assign grant_next[3] = req_unmasked[3] & ~(|req_unmasked[2:0]);
    assign grant_next[4] = req_unmasked[4] & ~(|req_unmasked[3:0]);
    
    // Output assignments - all combinational
    assign Gnt = grant_next;
    assign anyGnt = |grant_next;

endmodule
