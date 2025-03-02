`timescale 1ns / 1ps
module pipelined_test();
    logic clk = 1'b0;
    logic reset = 1'b1;
    logic [31:0] FetchInstr, DecodeInstr;
    logic [31:0] FetchPC, ALUOut, ResultW, WriteDataE;
    logic StallD, StallF;
    
    mips myTest(
        .clk(clk), 
        .reset(reset), 
        .PCF(FetchPC), 
        .InstrFetch(FetchInstr), 
        .InstrDec(DecodeInstr), 
        .ALUOut(ALUOut), 
        .ResultW(ResultW),
        .WriteDataE(WriteDataE),
        .StallD(StallD),
        .StallF(StallF)
    );
    
    always #5 clk= ~clk;
    initial begin
        #10; reset = 0;
        #100; $finish;
    end   
endmodule