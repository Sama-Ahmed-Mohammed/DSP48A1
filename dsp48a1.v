module dsp (
    input [17:0] A,
    input [17:0] B,
    input [17:0] D,
    input [47:0] C,
    input clk,
    input CARRYIN,
    input [7:0] OPMODE,
    input [17:0] BCIN, //cascaded input for port P

    //rst for registers
    input RSTA,
    input RSTB,
    input RSTM,
    input RSTP,
    input RSTC,
    input RSTD,
    input RSTCARRYIN,
    input RSTOPMODE,
    
    //clk enable for registers
    input CEA, 
    input CEB,
    input CEM,
    input CEP,
    input CEC,
    input CED,
    input CECARRYIN,
    input CEOPMODE,

    input [47:0] PCIN,

    output [17:0] BCOUT, //cascaded output for port B
    output [47:0] PCOUT, //cascaded output for port P
    output [47:0] P,
    output [35:0] M,
    output CARRYOUT,
    output CARRYOUTF
);
    //number of pipelined stages, takes only 0 or 1
    parameter A0REG = 0; 
    parameter A1REG = 1;
    parameter B0REG = 0;
    parameter B1REG = 1;
    parameter CREG = 1;
    parameter DREG = 1;
    parameter MREG = 1;
    parameter PREG = 1;
    parameter CARRYINREG = 1;
    parameter CARRYOUTREG = 1;
    parameter OPMODEREG = 1;

    //"CARRYIN" Or "OPMODE5", Which value will be considered. tie mux out to 0 if neither exists
    parameter CARRYINSEL = "CARRYIN";

    //DIRECT = B input, CASCADE = the previous DSP48A1 slice. tie mux out to 0 if neither exists
    parameter B_INPUT = "DIRECT";

    //SYNC or ASYNC reset type
    parameter RSTTYPE = "SYNC"; 

    //=====================================================================
    //=======  B_input Mux  ======================
    wire [17:0] B_IN; //the B_INPUT mux output

    assign B_IN = (B_INPUT === "DIRECT")? B :
                  (B_INPUT === "CASCADE")? BCIN : 0;

    //==========================================================================
    // Pipeline first stage
    //=========================================================================
    //internal signals
    wire [17:0] A0;
    wire [17:0] B0;
    wire [17:0] D0;
    wire [47:0] C0;
    wire [7:0] OPMODE0;

    //A0REG
    reg_mux #(.WIDTH(18), .REGE(A0REG), .RSTTYPE(RSTTYPE)) 
        A0_REG (.clk(clk), .RST(RSTA), .CE(CEA), .in(A), .out(A0));
    //B0REG
    reg_mux #(.WIDTH(18), .REGE(B0REG), .RSTTYPE(RSTTYPE)) 
        B0_REG (.clk(clk), .RST(RSTB), .CE(CEB), .in(B_IN), .out(B0));
    //DREG
    reg_mux #(.WIDTH(18), .REGE(DREG), .RSTTYPE(RSTTYPE)) 
        D_REG (.clk(clk), .RST(RSTD), .CE(CED), .in(D), .out(D0));
    //CREG
    reg_mux #(.WIDTH(48), .REGE(CREG), .RSTTYPE(RSTTYPE)) 
        C_REG (.clk(clk), .RST(RSTC), .CE(CEC), .in(C), .out(C0));
    //OPMODEREG
    reg_mux #(.WIDTH(8), .REGE(OPMODEREG), .RSTTYPE(RSTTYPE)) 
        OPMODE_REG (.clk(clk), .RST(RSTOPMODE), .CE(CEOPMODE), .in(OPMODE), .out(OPMODE0));

    //===============================================================
    // pre adder/subtractor
    //==============================================================
    //internal signals
    wire [17:0] pre_add_subtract_result;
    wire [17:0] multiplier_input; 
    
    //pre adder/subtractor
    assign pre_add_subtract_result = (OPMODE0[6])? (D0 - B0) : (D0 + B0);

    //Mux to choose which value to pass to the Multiplier
    assign multiplier_input = (OPMODE0[4])? pre_add_subtract_result : B0;

    //=======================================================
    // Pipeline second stage
    //======================================================
    //internal signals
    wire [17:0] A1;
    wire [17:0] B1; //will hold the value of multiplier input 

    //B1REG
    reg_mux #(.WIDTH(18), .REGE(B1REG), .RSTTYPE(RSTTYPE)) 
        B1_REG (.clk(clk), .RST(RSTB), .CE(CEB), .in(multiplier_input), .out(B1));
    //A1REG
    reg_mux #(.WIDTH(18), .REGE(A1REG), .RSTTYPE(RSTTYPE)) 
        A1_REG (.clk(clk), .RST(RSTA), .CE(CEA), .in(A0), .out(A1));
    
    //Assign output BCOUT
    assign BCOUT = B1;

    //==============================================================

    //=========== Multiplier ====================
    wire [35:0] multiplier_out;
    assign multiplier_out = A1 * B1;

    //========== Carry Cascade ==================
    wire CYI_IN;
    assign CYI_IN = (CARRYINSEL === "CARRYIN")? CARRYIN : 
                        (CARRYINSEL === "OPMODE5")? OPMODE0[5] : 0;


    //=======================================================
    // Pipeline Third stage
    //======================================================
    wire [35:0] MREG_OUT; 
    wire CYI_OUT;

    //MREG
    reg_mux #(.WIDTH(36), .REGE(MREG), .RSTTYPE(RSTTYPE)) 
        M_REG (.clk(clk), .RST(RSTM), .CE(CEM), .in(multiplier_out), .out(MREG_OUT));
    
    //CYI
    reg_mux #(.WIDTH(1), .REGE(CARRYINREG), .RSTTYPE(RSTTYPE)) 
        CYI_REG (.clk(clk), .RST(RSTCARRYIN), .CE(CECARRYIN), .in(CYI_IN), .out(CYI_OUT));

    //assign output M
    assign M = MREG_OUT;
    //==============================================================

    //========= Concatenate DAB ===========
    wire [47:0] DAB_CONCAT = {D0[11:0], A1[17:0], B1[17:0]};
    wire [47:0] PREG_OUT;

    //============ MUX_X ===================
    wire [47:0] X; //MUX X output
    assign X = (OPMODE0[1:0] == 2'b00)? 48'b0                 :
               (OPMODE0[1:0] == 2'b01)? {{12{1'b0}},MREG_OUT} :
               (OPMODE0[1:0] == 2'b10)? PREG_OUT              : DAB_CONCAT;

    //==========  MUX_Z  =================
    wire [47:0] Z; //MUX Z output
    assign Z = (OPMODE0[3:2] == 2'b00)? 48'b0       :
               (OPMODE0[3:2] == 2'b01)? PCIN        :
               (OPMODE0[3:2] == 2'b10)? PREG_OUT    : C0;
    
    //========== Post adder_subtractor ==========
    wire [48:0] post_add_subtract_result;
    assign post_add_subtract_result = (OPMODE0[7])? (Z - (X+CYI_OUT)) : (Z + X + CYI_OUT);

    //============================================================
    // Pipeline last stage
    //============================================================
    // PREG
    reg_mux #(.WIDTH(48), .REGE(PREG), .RSTTYPE(RSTTYPE)) 
        P_REG (.clk(clk), .RST(RSTP), .CE(CEP), .in(post_add_subtract_result[47:0]), .out(PREG_OUT));

    //outputs P and PCOUT
    assign P = PREG_OUT;
    assign PCOUT = P;

    //CYO REG
    wire CYO_OUT;
    reg_mux #(.WIDTH(1), .REGE(CARRYOUTREG), .RSTTYPE(RSTTYPE)) 
        CYO_REG (.clk(clk), .RST(RSTCARRYIN), .CE(CECARRYIN), .in(post_add_subtract_result[48]), .out(CYO_OUT));

    //output CARRYOUT and CARRYOUTF
    assign CARRYOUT = CYO_OUT;
    assign CARRYOUTF = CARRYOUT;

endmodule

  /*  reg_mux #(.WIDTH(), .REGE(), .RSTTYPE()) 
        stage (.clk(), .RST(), .CE(), .in(), .out());
        */