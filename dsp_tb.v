module dsp_tb();
    reg [17:0] A;
    reg [17:0] B;
    reg [17:0] D;
    reg [47:0] C;
    reg clk;
    reg CARRYIN;
    reg [7:0] OPMODE;
    reg [17:0] BCIN; //cascaded reg for port P

    //rst for registers
    reg RSTA;
    reg RSTB;
    reg RSTM;
    reg RSTP;
    reg RSTC;
    reg RSTD;
    reg RSTCARRYIN;
    reg RSTOPMODE;
    
    //clk enable for registers
    reg CEA; 
    reg CEB;
    reg CEM;
    reg CEP;
    reg CEC;
    reg CED;
    reg CECARRYIN;
    reg CEOPMODE;

    reg [47:0] PCIN;

    wire [17:0] BCOUT; //cascaded wire for port B
    wire [47:0] PCOUT; //cascaded wire for port P
    wire [47:0] P;
    wire [35:0] M;
    wire CARRYOUT;
    wire CARRYOUTF;

    dsp #(
        .A0REG(0),
        .A1REG(1),
        .B0REG(0),
        .B1REG(1),
        .CREG(1),
        .DREG(1),
        .MREG(1),
        .PREG(1),
        .CARRYINREG(1),
        .CARRYOUTREG(1),
        .OPMODEREG(1),
        .CARRYINSEL("OPMODE5"),
        .B_INPUT("DIRECT"),
        .RSTTYPE("SYNC")
    )
    dut(
    .A(A),
    .B(B),
    .D(D),
    .C(C),
    .clk(clk),
    .CARRYIN(CARRYIN),
    .OPMODE(OPMODE),
    .BCIN(BCIN),

    // Reset signals
    .RSTA(RSTA),
    .RSTB(RSTB),
    .RSTM(RSTM),
    .RSTP(RSTP),
    .RSTC(RSTC),
    .RSTD(RSTD),
    .RSTCARRYIN(RSTCARRYIN),
    .RSTOPMODE(RSTOPMODE),

    // Clock enables
    .CEA(CEA),
    .CEB(CEB),
    .CEM(CEM),
    .CEP(CEP),
    .CEC(CEC),
    .CED(CED),
    .CECARRYIN(CECARRYIN),
    .CEOPMODE(CEOPMODE),

    // Cascaded input
    .PCIN(PCIN),

    // Outputs
    .BCOUT(BCOUT),
    .PCOUT(PCOUT),
    .P(P),
    .M(M),
    .CARRYOUT(CARRYOUT),
    .CARRYOUTF(CARRYOUTF)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    reg [47:0] P_prev;
    reg CARRYOUT_prev;

    initial begin
//2.1 verify reset operation
        RSTA = 1;
        RSTB = 1;
        RSTM = 1;
        RSTP = 1;
        RSTC = 1;
        RSTD = 1;
        RSTCARRYIN = 1;
        RSTOPMODE = 1;

        // Randomize all other inputs
        A = $random;
        B = $random;
        D = $random;
        C = $random;
        CARRYIN = $random;
        OPMODE = $random;
        BCIN = $random;
        PCIN = $random;

        CEA = $random;
        CEB = $random;
        CEM = $random;
        CEP = $random;
        CEC = $random;
        CED = $random;
        CECARRYIN = $random;
        CEOPMODE = $random;

        @(negedge clk);
        if (P !== 0 || M !== 0 || PCOUT !== 0 || BCOUT !== 0 || CARRYOUT !== 0 || CARRYOUTF !== 0) begin
            $display("ERROR: Outputs not zero after reset. P = %h, M = %h, PCOUT = %h, BCOUT = %h, CARRYOUT = %h, CARRYOUTF = %h"
            , P, M, PCOUT, BCOUT, CARRYOUT, CARRYOUTF);
        end 
        else begin
            $display("PASS: Outputs are zero after reset. P = %h, M = %h, PCOUT = %h, BCOUT = %h, CARRYOUT = %h, CARRYOUTF = %h"
            , P, M, PCOUT, BCOUT, CARRYOUT, CARRYOUTF);
        end

        RSTA = 0;
        RSTB = 0;
        RSTM = 0;
        RSTP = 0;
        RSTC = 0;
        RSTD = 0;
        RSTCARRYIN = 0;
        RSTOPMODE = 0;

//2.2 Verify DSP Path 1
        // Apply input stimulus
        A = 20;
        B = 10;
        C = 350;
        D = 25;
        OPMODE = 8'b11011101;
        BCIN = $random;
        PCIN = $random;
        CARRYIN = $random;

        CEA = 1;
        CEB = 1;
        CEM = 1;
        CEP = 1;
        CEC = 1;
        CED = 1;
        CECARRYIN = 1;
        CEOPMODE = 1;

        repeat(4) @(negedge clk);
        if (BCOUT !== 16'hF || M !== 36'h12C || P !== 48'h32 || PCOUT !== 48'h32 || CARRYOUT !== 1'b0 || CARRYOUTF !== 1'b0) begin
            $display("DSP Path1 FAILED!");
            $display("Expected: BCOUT = %h, M = %h, P = %h, PCOUT = %h, CARRYOUT = %b, CARRYOUTF = %b", 16'hF, 36'h12C, 48'h32, 48'h32, 1'b0, 1'b0);
            $display("Got     : BCOUT = %h, M = %h, P = %h, PCOUT = %h, CARRYOUT = %b, CARRYOUTF = %b", BCOUT, M, P, PCOUT, CARRYOUT, CARRYOUTF);
        end 
        else begin
            $display("Verify DSP Path1 PASSED! BCOUT = %h, M = %h, P = %h, PCOUT = %h, CARRYOUT = %b, CARRYOUTF = %b", BCOUT, M, P, PCOUT, CARRYOUT, CARRYOUTF);
        end

//2.3 DSP path 2
        A = 20;
        B = 10;
        C = 350;
        D = 25;
        OPMODE = 8'b00010000;
        BCIN = $random;
        PCIN = $random;
        CARRYIN = $random;
        

        repeat(3)@(negedge clk);
        if (BCOUT !== 18'h23 || M !== 36'h2BC || P !== 48'h0 || PCOUT !== 48'h0 || CARRYOUT !== 1'b0 || CARRYOUTF !== 1'b0) begin
            $display("DSP path2 FAILED!");
            $display("Expected: BCOUT = %h, M = %h, P = %h, PCOUT = %h, CARRYOUT = %b, CARRYOUTF = %b", 
                    18'h23, 36'h2BC, 48'h0, 48'h0, 1'b0, 1'b0);
            $display("Got     : BCOUT = %h, M = %h, P = %h, PCOUT = %h, CARRYOUT = %b, CARRYOUTF = %b", 
                    BCOUT, M, P, PCOUT, CARRYOUT, CARRYOUTF);
        end 
        else begin
            $display("Verify DSP Path2 PASSED! BCOUT = %h, M = %h, P = %h, PCOUT = %h, CARRYOUT = %b, CARRYOUTF = %b", 
                    BCOUT, M, P, PCOUT, CARRYOUT, CARRYOUTF);
        end

//2.4 Verify DSP Path 3
        OPMODE = 8'b00001010;
        A = 20;
        B = 10;
        C = 350;
        D = 25;
        BCIN = $random;
        PCIN = $random;
        CARRYIN = $random;
        P_prev = P;
        CARRYOUT_prev = CARRYOUT;
        
        repeat(3) @(negedge clk);
        if (BCOUT !== 18'hA || M !== 36'hC8 || P !== P_prev || PCOUT !== P_prev ||
            CARRYOUT !== CARRYOUT_prev || CARRYOUTF !== CARRYOUT_prev) begin
            $display("DSP path3 FAILED!");
            $display("Expected: BCOUT = %h, M = %h, P = %h,PCOUT = %h, CARRYOUT = %b, CARRYOUTF = %b",18'hA, 36'hC8, P_prev,P_prev,CARRYOUT_prev, CARRYOUT_prev);
            $display("Got     : BCOUT = %h, M = %h, P = %h,PCOUT = %h, CARRYOUT = %b, CARRYOUTF = %b",BCOUT, M, P,PCOUT,CARRYOUT, CARRYOUTF);
        end 
        else begin
            $display("Verify DSP Path3 PASSED! BCOUT = %h, M = %h, P = %h,PCOUT = %h, P_prev = %h, CARRYOUT = %b, CARRYOUTF = %b, CARRYOUT_prev = %b", 
            BCOUT, M, P, PCOUT,P_prev, CARRYOUT, CARRYOUTF, CARRYOUT_prev);
        end

//2.5 verify DSP path 4
        OPMODE = 8'b10100111;
        A = 5;
        B = 6;
        C = 350;
        D = 25;
        PCIN = 3000;
        BCIN = $random;
        CARRYIN = $random;

        repeat(3)@(negedge clk);
        if(BCOUT !== 'h6 || M !== 'h1e || P !== 'hfe6fffec0bb1 || PCOUT !== 'hfe6fffec0bb1 ||
              CARRYOUT !== 1 || CARRYOUTF !== 1 )begin
            $display("DSP path4 FAILED!");
            $display("Expected: BCOUT = 'h6, M = 'h1e, P = PCOUT = 'hfe6fffec0bb1, and CARRYOUT = CARRYOUTF = 1");
            $display("Got     : BCOUT = %h, M = '%h, P = %h PCOUT = %h, and CARRYOUT %h, CARRYOUTF = %h", BCOUT, M, P, PCOUT, CARRYOUT, CARRYOUTF);
        end
        else begin
            $display("Verify DSP Path4 PASSED! BCOUT = %h, M = '%h, P = %h PCOUT = %h, and CARRYOUT %h, CARRYOUTF = %h", BCOUT, M, P, PCOUT, CARRYOUT, CARRYOUTF);
        end
    $stop;
    end
endmodule



