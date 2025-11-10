`timescale 1ns/10ps
`include "define.vh"

module PATTERN(
    clk, rst,
    M0lx, M0ly, M1lx, M1ly,
    M2lx, M2ly, M3lx, M3ly,

    P0_datain, P0_dataout, P0_reqin, P0_ackout, P0_ackin, P0_reqout,
    P1_datain, P1_dataout, P1_reqin, P1_ackout, P1_ackin, P1_reqout,
    P2_datain, P2_dataout, P2_reqin, P2_ackout, P2_ackin, P2_reqout,
    P3_datain, P3_dataout, P3_reqin, P3_ackout, P3_ackin, P3_reqout
);



//==============================================//
//          Input & Output Declaration          //
//==============================================//

    output reg  clk, rst;
    output reg  [2:0] M0lx, M0ly;
    output reg  [2:0] M1lx, M1ly;
    output reg  [2:0] M2lx, M2ly;
    output reg  [2:0] M3lx, M3ly;

    output reg  P0_reqin, P0_ackout;
    output reg  P1_reqin, P1_ackout;
    output reg  P2_reqin, P2_ackout;
    output reg  P3_reqin, P3_ackout;

    input P0_ackin, P0_reqout;
    input P1_ackin, P1_reqout;
    input P2_ackin, P2_reqout;
    input P3_ackin, P3_reqout;
    
    output reg  [`FLIT_LENGTH-1:0] P0_datain;
    output reg  [`FLIT_LENGTH-1:0] P1_datain;
    output reg  [`FLIT_LENGTH-1:0] P2_datain;
    output reg  [`FLIT_LENGTH-1:0] P3_datain;

    input [`FLIT_LENGTH-1:0] P0_dataout;
    input [`FLIT_LENGTH-1:0] P1_dataout;
    input [`FLIT_LENGTH-1:0] P2_dataout;
    input [`FLIT_LENGTH-1:0] P3_dataout;

//==============================================//
//               Parameter & Integer            //
//==============================================//
    // User modification
    parameter PATTERN_NUM = 100;

    // PATTERN operation
    parameter CYCLE = `CYCLE_TIME;

    // PATTERN CONTROL
    integer cycle_time = CYCLE;
    integer cur_time;
    integer i;

//==============================================//
//                 String control               //
//==============================================//
// Should use %0s
    string reset_color          = "\033[1;0m";
    string txt_black_prefix     = "\033[1;30m";
    string txt_red_prefix       = "\033[1;31m";
    string txt_green_prefix     = "\033[1;32m";
    string txt_yellow_prefix    = "\033[1;33m";
    string txt_blue_prefix      = "\033[1;34m";
    string txt_magenta_prefix   = "\033[1;35m";
    string txt_cyan_prefix      = "\033[1;36m";

    string bkg_black_prefix     = "\033[40;1m";
    string bkg_red_prefix       = "\033[41;1m";
    string bkg_green_prefix     = "\033[42;1m";
    string bkg_yellow_prefix    = "\033[43;1m";
    string bkg_blue_prefix      = "\033[44;1m";
    string bkg_white_prefix     = "\033[47;1m";

//==============================================//
//                main function                 //
//==============================================//
    initial begin
        reset_task;
        
        // start to test
        for(cur_time = 0; cur_time < PATTERN_NUM ; cur_time = cur_time + 1){
            ack_tesk;
            #(CYCLE/2);
            input_task;
            #(CYCLE/2);
            receive_task;
            @ (negedge clk); 
        }    
    
        check_task;
        pass_task;
    end

//==============================================//
//            Clock and Reset Task              //
//==============================================//
    // clock
    always begin
        #(CYCLE/2);
        clk = ~clk;
    end  

    // Cycle counter for data field (increment each clock)

    // reset task
    task reset_task; begin	
        // initiaize signal
        clk = 0;
        rst = 0;

        // force clock to be 0, do not flip in half cycle
        force clk = 0;

        #(CYCLE*3);
        
        // reset
        rst = 1;  #(CYCLE*4); // wait 4 cycles to check output signal

        // check reset
        
        // release reset
        rst = 0; #(CYCLE*3);
        
        // release clock
        release clk; repeat(5) @ (negedge clk);
    end endtask


//==============================================//
//                   lx  ly                     //
//==============================================//

    always @(posedge clk)begin
        M0lx = 0;   
        M0ly = 0;

        M1lx = 0;   
        M1ly = 1;

        M2lx = 1;
        M2ly = 0;

        M3lx = 1;
        M3ly = 1;
    end
//==============================================//
//            Signal Declaration                //
//==============================================//

    parameter DATA_P = "../00_TESTBED/DATA/0_Mesh_in.dat";

    reg [`FLIT_LENGTH-1:0] DATA_PP [0:31];

    initial $readmemb(DATA_P, DATA_PP);

    integer pp = 0;

    reg [`FLIT_LENGTH-1:0]flitp;

    always @(posedge clk)begin
        flitp <= DATA_PP[pp];
    end

    wire [2:0]p_srcx = flitp[`FLIT_LENGTH-3:`FLIT_LENGTH-5];
    wire [2:0]p_srcy = flitp[`FLIT_LENGTH-6:`FLIT_LENGTH-8];

    wire [41:0]p_time = flitp[`FLIT_LENGTH-15:16];

    wire [15:0]p_num = flitp[15:0];

    wire [15:0]p_num0 = P0_dataout[15:0];
    wire [15:0]p_num1 = P1_dataout[15:0];
    wire [15:0]p_num2 = P2_dataout[15:0];
    wire [15:0]p_num3 = P3_dataout[15:0];

    reg in[0:63];
    reg out[0:63];

//==============================================//
//                Ack Task                      //
//==============================================//

    // input task
    task ack_task; begin

        P0_reqin = 0;
        P1_reqin = 0;
        P2_reqin = 0;
        P3_reqin = 0;

        if(p_time <= cur_time and flitp !== 0)begin
            if(p_srcx == 0 and p_srcy == 0)
                P0_reqin = 1;
            else if(p_srcx == 0 and p_srcy == 1)
                P1_reqin = 1;
            else if(p_srcx == 1 and p_srcy == 0)
                P2_reqin = 1;
            else if(p_srcx == 1 and p_srcy == 1)
                P3_reqin = 1;
        end
        
    end endtask

//==============================================//
//                Input Task                    //
//==============================================//

    // input task
    task input_task; begin

        P0_datain = 0;
        P1_datain = 0;
        P2_datain = 0;
        P3_datain = 0;

        if(P_ackin)begin
            if(p_srcx == 0 and p_srcy == 0)
                P0_datain = flitp;
            else if(p_srcx == 0 and p_srcy == 1)
                P1_datain = flitp;
            else if(p_srcx == 1 and p_srcy == 0)
                P2_datain = flitp;
            else if(p_srcx == 1 and p_srcy == 1)
                P3_datain = flitp;
            in[p_num] = 1;
            pp = pp + 1;
        end

        
    end endtask

//==============================================//
//           Receive task                       //
//==============================================//

    task receive_task; begin

        P0_ackout = P0_reqout;
        P1_ackout = P1_reqout;
        P2_ackout = P2_reqout;
        P3_ackout = P3_reqout;

        if(P0_reqout) begin
            
            out[p_num0] = 1;
        end
        if(P1_reqout) begin
            
            out[p_num1] = 1;
        end
        if(P2_reqout) begin
            
            out[p_num2] = 1;
        end
        if(P3_reqout) begin
           
            out[p_num3] = 1;
        end

    end endtask

//==============================================//
//                Check Task                    //
//==============================================//

    task check_task; begin
        for(i = 0; i < 64; i = i + 1){
            if(in[i] !== out[i]){
                $display("%0s================================================================", txt_red_prefix);
                $display("                             FAIL"                           );
                $display("    the %4d flit have not receive after %-8d clock cycle  ", i, cur_time);
                $display("    in[i] is %4d , out[i] is %4d ", in[i], out[i]);
                $display("================================================================%0s", reset_color);
                $finish;
            }
        }
    end endtask

//==============================================//
//                 Pass Task                    //
//==============================================//
// pass task
    task pass_task; begin
        $display("%0s========================================================", txt_magenta_prefix);
        $display("                      Congratulations!!");
        $display("                     All Pattern Test Pass");
        $display("======================================================== %0s", reset_color);
        $finish;
    end	endtask


//==============================================//
//                Terminal Print                //
//==============================================//


//==============================================//
//          1. Flit go out of router            //
//==============================================//
    always @(posedge clk) begin
        if(P0_reqOut) begin
            $display("Time %0t: %s flit exits from M0 with flit num %0d", cur_time, "HEAD", P0_dataout[15:0]);
        end
        if(P1_reqOut) begin
            $display("Time %0t: %s flit exits from M1 with flit num %0d", cur_time, "HEAD", P1_dataout[15:0]);
        end
        if(P2_reqOut) begin
            $display("Time %0t: %s flit exits from M2 with flit num %0d", cur_time, "HEAD", P2_dataout[15:0]);
        end
        if(P3_reqOut) begin
            $display("Time %0t: %s flit exits from M3 with flit num %0d", cur_time, "HEAD", P3_dataout[15:0]);
        end

    end

endmodule
    