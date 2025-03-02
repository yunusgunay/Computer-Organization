`timescale 1ns / 1ps
module pipelined_processor(
    input logic clk,
    input logic btnC, btnD,
    
    output logic dp,
    output logic [6:0] seg,
    output logic [3:0] an
    );
    
    logic [31:0] PCF, InstrFetch, InstrDec;
    logic [31:0] ALUOut, ResultW, WriteDataE, ReadDataM;
    logic MemWrite, RegWrite, Jump, StallD, StallF;
    logic btnC_deb, btnD_deb;
    localparam ZERO = 1'b0;
    
    pulse_controller clkButton(clk, btnC, ZERO, btnC_deb);
    pulse_controller resetButton(clk, btnD, ZERO, btnD_deb);
    
    mips pipelined_mips(btnC_deb, btnD_deb, PCF, InstrFetch, InstrDec, ALUOut, ResultW, WriteDataE, ReadDataM,
        MemWrite, RegWrite, Jump, StallD, StallF);
    
    display_controller(clk, ALUOut[7:4], ALUOut[3:0], ResultW[7:4], ResultW[3:0], seg, dp, an);
endmodule
