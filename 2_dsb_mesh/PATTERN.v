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
        for(cur_time = 0; cur_time < PATTERN_NUM ; cur_time = cur_time + 1)begin
            ackin_task;
            input_task;
            #(CYCLE/2);
            ackout_task;
            receive_task;
            #(CYCLE/2);
        end 
    
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

        M1lx = 1;   
        M1ly = 0;

        M2lx = 0;
        M2ly = 1;

        M3lx = 1;
        M3ly = 1;
    end
//==============================================//
//            Signal Declaration                //
//==============================================//

    parameter DATA_P0 = "../00_TESTBED/DATA/0_Mesh0_in.dat";
    parameter DATA_P1 = "../00_TESTBED/DATA/1_Mesh1_in.dat";
    parameter DATA_P2 = "../00_TESTBED/DATA/2_Mesh2_in.dat";
    parameter DATA_P3 = "../00_TESTBED/DATA/3_Mesh3_in.dat";

    reg [`FLIT_LENGTH-1:0] DATA_PP0 [0:31];
    reg [`FLIT_LENGTH-1:0] DATA_PP1 [0:31];
    reg [`FLIT_LENGTH-1:0] DATA_PP2 [0:31];
    reg [`FLIT_LENGTH-1:0] DATA_PP3 [0:31];

    initial $readmemb(DATA_P0, DATA_PP0);
    initial $readmemb(DATA_P1, DATA_PP1);
    initial $readmemb(DATA_P2, DATA_PP2);
    initial $readmemb(DATA_P3, DATA_PP3);

    integer pp0 = 0;
    integer pp1 = 0;
    integer pp2 = 0;
    integer pp3 = 0;

    reg [`FLIT_LENGTH-1:0]flitp0;
    reg [`FLIT_LENGTH-1:0]flitp1;
    reg [`FLIT_LENGTH-1:0]flitp2;
    reg [`FLIT_LENGTH-1:0]flitp3;

    always @(posedge clk)begin
        flitp0 <= DATA_PP0[pp0];
        flitp1 <= DATA_PP1[pp1];
        flitp2 <= DATA_PP2[pp2];
        flitp3 <= DATA_PP3[pp3];
    end

    wire [41:0]p0_time = flitp0[`FLIT_LENGTH-15:16];
    wire [41:0]p1_time = flitp1[`FLIT_LENGTH-15:16];
    wire [41:0]p2_time = flitp2[`FLIT_LENGTH-15:16];
    wire [41:0]p3_time = flitp3[`FLIT_LENGTH-15:16];

    wire [15:0]p0_num = flitp0[15:0];
    wire [15:0]p1_num = flitp1[15:0];
    wire [15:0]p2_num = flitp2[15:0];
    wire [15:0]p3_num = flitp3[15:0];

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
    task ackin_task; begin

        P0_reqin = 0;
        P1_reqin = 0;
        P2_reqin = 0;
        P3_reqin = 0;

        if(p0_time <= cur_time && flitp0 !== 0)
            P0_reqin = 1;
        if(p1_time <= cur_time && flitp1 !== 0)
            P1_reqin = 1;
        if(p2_time <= cur_time && flitp2 !== 0)
            P2_reqin = 1;
        if(p3_time <= cur_time && flitp3 !== 0)
            P3_reqin = 1;
        
    end endtask

    task ackout_task; begin

        P0_ackout = P0_reqout;
        P1_ackout = P1_reqout;
        P2_ackout = P2_reqout;
        P3_ackout = P3_reqout;

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

        if(P0_ackin)begin
            P0_datain = flitp0;
            in[p0_num] = 1;
            pp0 = pp0 + 1;
        end
        if(P1_ackin)begin
            P1_datain = flitp1;
            in[p1_num] = 1;
            pp1 = pp1 + 1;
        end
        if(P2_ackin)begin
            P2_datain = flitp2;
            in[p2_num] = 1;
            pp2 = pp2 + 1;
        end
        if(P3_ackin)begin
            P3_datain = flitp3;
            in[p3_num] = 1;
            pp3 = pp3 + 1;
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
        for(i = 0; i < 64; i = i + 1)begin
            if(in[i] !== out[i])begin
                $display("%0s================================================================", txt_red_prefix);
                $display("                             FAIL"                           );
                $display("    the %4d flit have not receive after %-8d clock cycle  ", i, cur_time);
                $display("    in[i] is %4d , out[i] is %4d ", in[i], out[i]);
                $display("================================================================%0s", reset_color);
                $finish;
            end
        end
    end endtask

//==============================================//
//                 Pass Task                    //
//==============================================//
// pass task
    task pass_task; begin
        $display("%0s========================================================", txt_magenta_prefix);
        $display("                      Congratulations!!");
        $display("                    All Pattern Test Pass");
        $display("======================================================== %0s", reset_color);
        $finish;
    end	endtask


//==============================================//
//                Terminal Print                //
//==============================================//


//==============================================//
//          1. Flit go out of router            //
//==============================================//
    always @(negedge clk) begin
        if(P0_reqout && P0_ackout) begin
            $display(txt_red_prefix,    "Time %0t: %s flit exits from M0 with flit num %0d, generate time: %0d, delay: %0d", cur_time, "HEAD", P0_dataout[15:0], P0_dataout[`FLIT_LENGTH-15:16], cur_time - P0_dataout[`FLIT_LENGTH-15:16], reset_color);
        end
        if(P1_reqout && P1_ackout) begin
            $display(txt_blue_prefix,   "Time %0t: %s flit exits from M1 with flit num %0d, generate time: %0d, delay: %0d", cur_time, "HEAD", P1_dataout[15:0], P1_dataout[`FLIT_LENGTH-15:16], cur_time - P1_dataout[`FLIT_LENGTH-15:16], reset_color);
        end
        if(P2_reqout && P2_ackout) begin
            $display(txt_yellow_prefix, "Time %0t: %s flit exits from M2 with flit num %0d, generate time: %0d, delay: %0d", cur_time, "HEAD", P2_dataout[15:0], P2_dataout[`FLIT_LENGTH-15:16], cur_time - P2_dataout[`FLIT_LENGTH-15:16], reset_color);
        end
        if(P3_reqout && P3_ackout) begin
            $display(txt_green_prefix,  "Time %0t: %s flit exits from M3 with flit num %0d, generate time: %0d, delay: %0d", cur_time, "HEAD", P3_dataout[15:0], P3_dataout[`FLIT_LENGTH-15:16], cur_time - P3_dataout[`FLIT_LENGTH-15:16], reset_color);
        end

    end

endmodule
    