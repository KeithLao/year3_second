`timescale 1ns/10ps
`include "define.vh"

module PATTERN(
    clk, rst, lx, ly,
	P_datain, P_dataout, P_reqin, P_ackout, P_ackin, P_reqout,
	S_datain, S_dataout, S_reqin, S_ackout, S_ackin, S_reqout,
	W_datain, W_dataout, W_reqin, W_ackout, W_ackin, W_reqout,
	N_datain, N_dataout, N_reqin, N_ackout, N_ackin, N_reqout,
	E_datain, E_dataout, E_reqin, E_ackout, E_ackin, E_reqout
);


//==============================================//
//          Input & Output Declaration          //
//==============================================//

    output reg  clk, rst;
    output reg  [2:0] lx, ly;
    output reg  P_reqin, P_ackout;
    output reg  S_reqin, S_ackout;
    output reg  W_reqin, W_ackout;
    output reg  N_reqin, N_ackout;
    output reg  E_reqin, E_ackout;

    input P_ackin, P_reqout;
    input S_ackin, S_reqout;
    input W_ackin, W_reqout;
    input N_ackin, N_reqout;
    input E_ackin, E_reqout;

    output reg  [`FLIT_LENGTH-1:0] P_datain;
    output reg  [`FLIT_LENGTH-1:0] S_datain;
    output reg  [`FLIT_LENGTH-1:0] W_datain;
    output reg  [`FLIT_LENGTH-1:0] N_datain;
    output reg  [`FLIT_LENGTH-1:0] E_datain;

    input [`FLIT_LENGTH-1:0] P_dataout;
    input [`FLIT_LENGTH-1:0] S_dataout;
    input [`FLIT_LENGTH-1:0] W_dataout;
    input [`FLIT_LENGTH-1:0] N_dataout;
    input [`FLIT_LENGTH-1:0] E_dataout;

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
        for(cur_time = 0; cur_time < PATTERN_NUM ; cur_time = cur_time + 1) begin
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
        lx = 1;
        ly = 1;
    end
//==============================================//
//            Signal Declaration                //
//==============================================//

    //parameter DATA_P = "../00_TESTBED/DATA/0_Processor_direction_in.dat";
    //parameter DATA_S = "../00_TESTBED/DATA/1_South_direction_in.dat";
    //parameter DATA_W = "../00_TESTBED/DATA/2_West_direction_in.dat";
    //parameter DATA_N = "../00_TESTBED/DATA/3_North_direction_in.dat";
    //parameter DATA_E = "../00_TESTBED/DATA/4_East_direction_in.dat";

    parameter DATA_P = "../00_TESTBED/DATA2/0_Processor_direction_in.dat";
    parameter DATA_S = "../00_TESTBED/DATA2/1_South_direction_in.dat";
    parameter DATA_W = "../00_TESTBED/DATA2/2_West_direction_in.dat";
    parameter DATA_N = "../00_TESTBED/DATA2/3_North_direction_in.dat";
    parameter DATA_E = "../00_TESTBED/DATA2/4_East_direction_in.dat";

    reg [`FLIT_LENGTH-1:0] DATA_PP [0:31];
    reg [`FLIT_LENGTH-1:0] DATA_SS [0:31];
    reg [`FLIT_LENGTH-1:0] DATA_WW [0:31];
    reg [`FLIT_LENGTH-1:0] DATA_NN [0:31];
    reg [`FLIT_LENGTH-1:0] DATA_EE [0:31];

    initial $readmemb(DATA_P, DATA_PP);
    initial $readmemb(DATA_S, DATA_SS);
    initial $readmemb(DATA_W, DATA_WW);
    initial $readmemb(DATA_N, DATA_NN);
    initial $readmemb(DATA_E, DATA_EE);

    integer pp = 0;
    integer ps = 0;
    integer pw = 0;
    integer pn = 0;
    integer pe = 0;

    reg [`FLIT_LENGTH-1:0]flitp;
    reg [`FLIT_LENGTH-1:0]flits;
    reg [`FLIT_LENGTH-1:0]flitw;
    reg [`FLIT_LENGTH-1:0]flitn;
    reg [`FLIT_LENGTH-1:0]flite;

    always @(posedge clk)begin
        flitp <= DATA_PP[pp];
        flits <= DATA_SS[ps];
        flitw <= DATA_WW[pw];
        flitn <= DATA_NN[pn];
        flite <= DATA_EE[pe];
    end

    wire [41:0]p_time = flitp[`FLIT_LENGTH-15:16];
    wire [41:0]s_time = flits[`FLIT_LENGTH-15:16];
    wire [41:0]w_time = flitw[`FLIT_LENGTH-15:16];
    wire [41:0]n_time = flitn[`FLIT_LENGTH-15:16];
    wire [41:0]e_time = flite[`FLIT_LENGTH-15:16];

    wire [15:0]p_num = flitp[15:0];
    wire [15:0]s_num = flits[15:0];
    wire [15:0]w_num = flitw[15:0];
    wire [15:0]n_num = flitn[15:0];
    wire [15:0]e_num = flite[15:0];

    wire [15:0]p_num2 = P_dataout[15:0];
    wire [15:0]s_num2 = S_dataout[15:0];
    wire [15:0]w_num2 = W_dataout[15:0];
    wire [15:0]n_num2 = N_dataout[15:0];
    wire [15:0]e_num2 = E_dataout[15:0];

    reg in[0:63];
    reg out[0:63];


//==============================================//
//                Ack Task                      //
//==============================================//

    // input task
    task ackin_task; begin

        P_reqin = 0;
        S_reqin = 0;
        W_reqin = 0;
        N_reqin = 0;
        E_reqin = 0;

        if(p_time <= cur_time && flitp !== 0)
            P_reqin = 1;
        if(s_time <= cur_time && flits !== 0)
            S_reqin = 1;
        if(w_time <= cur_time && flitw !== 0)
            W_reqin = 1;
        if(n_time <= cur_time && flitn !== 0)
            N_reqin = 1;
        if(e_time <= cur_time && flite !== 0)
            E_reqin = 1;

    end endtask

    task ackout_task; begin

        P_ackout = P_reqout;
        S_ackout = S_reqout;
        W_ackout = W_reqout;
        N_ackout = N_reqout;
        E_ackout = E_reqout;

    end endtask


//==============================================//
//                Input Task                    //
//==============================================//

    // input task
    task input_task; begin

        P_datain = 72'bz;
        S_datain = 72'bz;
        W_datain = 72'bz;
        N_datain = 72'bz;
        E_datain = 72'bz;

        if(P_ackin)begin
            P_datain = flitp;
            in[p_num] = 1;
            pp = pp + 1;
        end

        if(S_ackin)begin
            S_datain = flits;
            in[s_num] = 1;
            ps = ps + 1;
        end

        if(W_ackin)begin
            W_datain = flitw;
            in[w_num] = 1;
            pw = pw + 1;
        end

        if(N_ackin)begin
            N_datain = flitn;
            in[n_num] = 1;
            pn = pn + 1;
        end

        if(E_ackin)begin
            E_datain = flite;
            in[e_num] = 1;
            pe = pe + 1;
        end
        
    end endtask

//==============================================//
//           Receive task                       //
//==============================================//

    task receive_task; begin

        if(P_reqout) begin
            out[p_num2] = 1;
        end
        if(S_reqout) begin
            out[s_num2] = 1;
        end
        if(W_reqout) begin
            out[w_num2] = 1;
        end
        if(N_reqout) begin
            out[n_num2] = 1;
        end
        if(E_reqout) begin
            out[e_num2] = 1;
        end

    end endtask

//==============================================//
//                Check Task                    //
//==============================================//

    task check_task; begin
        for(i = 0; i < 64; i = i + 1) begin
            if(in[i] !== out[i])begin
                $display("%0s================================================================", txt_red_prefix);
                $display("                             FAIL"                           );
                $display("    the %4d flit have not received after %-8d clock cycle  ", i, cur_time);
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
        if (P_reqout && P_ackout) begin
            $display(txt_magenta_prefix, "Time %0t: %s flit exits from P with flit num %0d", cur_time, "HEAD", P_dataout[15:0], reset_color);
        end
        if (S_reqout && S_ackout) begin
            $display(txt_green_prefix, "Time %0t: %s flit exits from S with flit num %0d", cur_time, "HEAD", S_dataout[15:0], reset_color);
        end
        if (W_reqout && W_ackout) begin
            $display(txt_yellow_prefix, "Time %0t: %s flit exits from W with flit num %0d", cur_time, "HEAD", W_dataout[15:0], reset_color);
        end
        if (N_reqout && N_ackout) begin
            $display(txt_blue_prefix, "Time %0t: %s flit exits from N with flit num %0d", cur_time, "HEAD", N_dataout[15:0], reset_color);
        end
        if (E_reqout && E_ackout) begin
            $display(txt_red_prefix, "Time %0t: %s flit exits from E with flit num %0d", cur_time, "HEAD", E_dataout[15:0], reset_color);
        end

    end


endmodule
    