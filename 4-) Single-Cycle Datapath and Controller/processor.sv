`timescale 1ns / 1ps
module processor(
    input logic clk,
    input logic btnC, btnD,
    
    output logic memwrite, 
    output logic[6:0]seg, 
    output logic dp,
    output logic[3:0] an
    );

    logic btnCdeb, btnDdeb;
    logic[31:0] instr, pc;
    logic[31:0] writedata, dataadr, readdata; // writedata: rt register & dataadr: alu result
    
    pulse_controller clkButton(clk, btnC, 0, btnCdeb);
    pulse_controller resetButton(clk, btnD, 0, btnDdeb);
    
    top topmodule(
        .clk(btnCdeb), 
        .reset(btnDdeb), 
        .writedata(writedata), 
        .dataadr(dataadr), 
        .readdata(readdata), 
        .memwrite(memwrite), 
        .instr(instr), 
        .pc(pc)
    );
    
    display_controller display(clk, writedata[7:4], writedata[3:0], dataadr[7:4], dataadr[3:0], seg, dp, an);  
endmodule
