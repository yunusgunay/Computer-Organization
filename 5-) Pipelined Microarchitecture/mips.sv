`timescale 1ns / 1ps
// IF to ID
module PipeFtoD(
    input logic clk, reset, EN,
    input logic [31:0] instrF, PcPlus4F,
    output logic [31:0] instrD, PcPlus4D
    );

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            instrD <= 32'b0;
            PcPlus4D <= 32'b0;
        end else if(EN) begin
            instrD <= instrF;
            PcPlus4D <= PcPlus4F;
        end
    end
endmodule

// WB to IF
module PipeWtoF(
    input logic clk, reset, EN,
    input logic [31:0] PC,
    output logic [31:0] PCF
    );

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            PCF <= 32'b0;
        end else if(EN) begin
            PCF <= PC;
        end
    end
endmodule

// ID to EXE
module PipeDtoE(
    input logic clk, reset, CLR,
    
    input logic [31:0] RD1D, RD2D, SignImmD,
    input logic [4:0] rsD, rtD, rdD,
    input logic RegWriteD, MemToRegD, MemWriteD,
    input logic [2:0] ALUControlD,
    input logic ALUSrcD, RegDstD,
    
    output logic [31:0] RD1E, RD2E, SignImmE, 
    output logic [4:0] rsE, rtE, rdE,
    output logic RegWriteE, MemToRegE, MemWriteE,   
    output logic [2:0] ALUControlE,
    output logic ALUSrcE, RegDstE   
    );
    
    always_ff @(posedge clk) begin
        if(CLR || reset) begin
            RD1E <= 32'b0;
            RD2E <= 32'b0; 
            SignImmE <= 32'b0; 
            
            rsE <= 5'b0;
            rtE <= 5'b0;
            rdE <= 5'b0;
            
            RegWriteE <= 1'b0;
            MemToRegE <= 1'b0; 
            MemWriteE <= 1'b0; 
            ALUControlE <= 3'b0; 
            ALUSrcE <= 1'b0;
            RegDstE <= 1'b0;       
        end else begin
            // ID to EXE stage
            RD1E <= RD1D;
            RD2E <= RD2D;
            SignImmE <= SignImmD;
            
            rsE <= rsD;
            rtE <= rtD;
            rdE <= rdD;
            
            RegWriteE <= RegWriteD;
            MemToRegE <= MemToRegD; 
            MemWriteE <= MemWriteD; 
            ALUControlE <= ALUControlD; 
            ALUSrcE <= ALUSrcD;
            RegDstE <= RegDstD; 
        end   
    end     
endmodule

// EXE to MEM
module PipeEtoM(
    input logic clk, reset,
    
    input logic [31:0] ALUOutE, WriteDataE,
    input logic [4:0] WriteRegE,
    input logic RegWriteE, MemToRegE, MemWriteE,
    
    output logic [31:0] ALUOutM, WriteDataM,
    output logic [4:0] WriteRegM,
    output logic RegWriteM, MemToRegM, MemWriteM
    );
	
	always_ff @(posedge clk) begin 
	   if(reset) begin
	       ALUOutM <= 32'b0;
	       WriteDataM <= 32'b0;
	       WriteRegM <= 5'b0; 
	       RegWriteM <= 1'b0; 
	       MemToRegM <= 1'b0; 
	       MemWriteM <= 1'b0;
	   end else begin 
	       ALUOutM <= ALUOutE;
	       WriteDataM <= WriteDataE;
	       WriteRegM <= WriteRegE; 
	       RegWriteM <= RegWriteE; 
	       MemToRegM <= MemToRegE; 
	       MemWriteM <= MemWriteE;
	   end	
	end           
endmodule

// MEM to WB
module PipeMtoW(
    input logic clk, reset,
    
    input logic [31:0] ReadDataM, ALUOutM,
    input logic [4:0] WriteRegM,
    input logic RegWriteM, MemToRegM,
    
    output logic [31:0] ReadDataW, ALUOutW,
    output logic [4:0] WriteRegW,
    output logic RegWriteW, MemToRegW
    );
	
	always_ff @(posedge clk) begin
	   if(reset) begin
	       ReadDataW <= 32'b0;
	       ALUOutW <= 32'b0;
	       WriteRegW <= 5'b0; 
	       RegWriteW <= 1'b0; 
	       MemToRegW <= 1'b0; 
	   end else begin 
	       ReadDataW <= ReadDataM;
	       ALUOutW <= ALUOutM;
	       WriteRegW <= WriteRegM; 
	       RegWriteW <= RegWriteM; 
	       MemToRegW <= MemToRegM; 	   
	   end
	end               
endmodule

// PIPELINED DATAPATH
module datapath(
    input logic clk, reset,    
    input logic MemToRegD, ALUSrcD, RegDstD, RegWriteD,
    input logic [2:0] ALUControlD,
    input logic BranchD, Jump,
    input logic rsD, rtD, rdD,
    
    output logic MemWriteD,
    output logic [31:0] instrF, PCF, instrD, 
    output logic [31:0] ALUOutE, WriteDataE, ReadDataW, ResultW,
    output logic StallF, StallD
    ); 

    // Internal Signals //
    logic ForwardAD, ForwardBD;
    logic [1:0] ForwardAE, ForwardBE;
    
    logic [4:0] WriteRegW, WriteRegE, WriteRegM;
    logic RegWriteE, RegWriteW, RegWriteM, MemToRegM, MemWriteM;
    logic MemToRegW, MemToRegE, MemWriteE, ALUSrcE, RegDstE, ZeroE, FlushE;
    logic [2:0] ALUControlE;
    logic [31:0] WriteDataM, ALUOutM, ReadDataM, ALUOutW;
        
    logic [31:0] PcPlus4D, JumpAddr, PC, PCNext, PcPlus4, PcBranchD;
    logic [31:0] SignImmD, SignImmExt, SignImmE;
    
    logic [4:0] rsE, rtE, rdE;
    logic [31:0] SrcAE, SrcBE, RD1D, RD2D, RD1E, RD2E;
    logic [31:0] RD1D_Temp, RD2D_Temp;
    logic Enable1, Enable2;
    localparam ZERO = 1'b0;
    // End of Integral Signals //
 
    // Hazard Unit
    HazardUnit hazard_unit(
        .RegWriteW(RegWriteW), 
        .WriteRegE(WriteRegE), .WriteRegW(WriteRegW),
        .RegWriteM(RegWriteM), .MemToRegM(MemToRegM),
        .WriteRegM(WriteRegM),           
        .RegWriteE(RegWriteE), .MemToRegE(MemToRegE),
        .rsE(rsE), .rtE(rtE), 
        .rsD(instrD[25:21]), .rtD(instrD[20:16]),    
        .BranchD(BranchD), .Jump(Jump),
        .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
        .ForwardAD(ForwardAD), .ForwardBD(ForwardBD),
        .FlushE(FlushE), .StallD(StallD), .StallF(StallF)
    );
    
    // IF to ID
    assign Enable2 = ~StallD && 1;
    PipeFtoD fd_pipe(clk, reset, Enable2, instrF, PcPlus4, instrD, PcPlus4D);       
    imem instr_mem(PCF[7:2], instrF);
    regfile reg_file(clk, ZERO, RegWriteW, instrD[25:21], instrD[20:16], WriteRegW, ResultW, RD1D_Temp, RD2D_Temp);
   
    // ID to EXE    
    always_comb begin
        if(ForwardAD) begin
            RD1D = ALUOutM;
        end else begin
            RD1D = RD1D_Temp;
        end
        
        if(ForwardBD) begin
            RD2D = ALUOutM;
        end else begin
            RD2D = RD2D_Temp;
        end   
    end 
    
    PipeDtoE de_pipe(
        .clk(clk), .reset(reset), .CLR(FlushE), 
        .RD1D(RD1D), .RD2D(RD2D), .SignImmD(SignImmD),
        .rsD(instrD[25:21]), .rtD(instrD[20:16]), .rdD(instrD[15:11]),      
        .RegWriteD(RegWriteD), .MemToRegD(MemToRegD), .MemWriteD(MemWriteD), 
        .ALUControlD(ALUControlD), 
        .ALUSrcD(ALUSrcD), .RegDstD(RegDstD), 

        .RD1E(RD1E), .RD2E(RD2E), .SignImmE(SignImmE), 
        .rsE(rsE), .rtE(rtE), .rdE(rdE),   
        .RegWriteE(RegWriteE), .MemToRegE(MemToRegE), .MemWriteE(MemWriteE), 
        .ALUControlE(ALUControlE), 
        .ALUSrcE(ALUSrcE), .RegDstE(RegDstE)
    );

    // EXE Stage Forwarding
    mux4 #(32)forwardA_mux(RD1E, ResultW, ALUOutM, ZERO, ForwardAE, SrcAE);
    mux4 #(32)forwardB_mux(RD2E, ResultW, ALUOutM, ZERO, ForwardBE, WriteDataE);
    
    // Choose WriteReg and ALU Input
    always_comb begin
        if(RegDstE) begin
            WriteRegE = rdE;
        end else begin
            WriteRegE = rtE;
        end
        
        if(ALUSrcE) begin
            SrcBE = SignImmE;
        end else begin
            SrcBE = WriteDataE;
        end   
    end
    alu alu1(SrcAE, SrcBE, ALUControlE, ALUOutE, ZeroE);

    // EXE to MEM
    PipeEtoM pEtoM(
        .clk(clk), .reset(reset),
        .RegWriteE(RegWriteE), .MemToRegE(MemToRegE), .MemWriteE(MemWriteE), 
        .ALUOutE(ALUOutE), .WriteDataE(WriteDataE), .WriteRegE(WriteRegE),
        
        .RegWriteM(RegWriteM), .MemToRegM(MemToRegM), .MemWriteM(MemWriteM), 
        .ALUOutM(ALUOutM), .WriteDataM(WriteDataM), .WriteRegM(WriteRegM)
    );

    // MEM to WB
    dmem decode_mem(clk, MemWriteM, ALUOutM, WriteDataM, ReadDataM);      
    PipeMtoW mw_pipe(
        .clk(clk), .reset(reset),
        .ReadDataM(ReadDataM), .ALUOutM(ALUOutM), 
        .WriteRegM(WriteRegM),
        .RegWriteM(RegWriteM), .MemToRegM(MemToRegM),
         
        .ReadDataW(ReadDataW), .ALUOutW(ALUOutW), 
        .WriteRegW(WriteRegW),
        .RegWriteW(RegWriteW), .MemToRegW(MemToRegW)
    );
    
    // WB to IF
    assign Enable1 = ~StallF && 1;
    PipeWtoF wf_pipe(clk, reset, Enable1, PC, PCF);
    
    // PC
    signext sign_ext(instrD[15:0], SignImmD);
    assign SignImmExt = SignImmD << 2;
    adder pc_branch_inc(SignImmExt, PcPlus4D, PcBranchD);
    adder pc4_inc(PCF, 32'd4, PcPlus4);
    
    always_comb begin
        if(MemToRegW) begin
            ResultW = ReadDataW;
        end else begin
            ResultW = ALUOutW;
        end
        
        if(BranchD && (RD1D == RD2D)) begin
            PCNext = PcBranchD;
        end else begin
            PCNext = PcPlus4;
        end   
    end
    
    // Jump
    logic [3:0] upper_bits = PcPlus4D[31:28];
    logic [25:0] jump_offset = instrD[25:0];
    assign JumpAddr = {upper_bits, jump_offset, 2'b00};
    mux2 #(32) jump_sel(PCNext, JumpAddr, Jump, PC);
endmodule


// HAZARD UNIT
module HazardUnit(
    input logic RegWriteW,
    input logic [4:0] WriteRegE, WriteRegW,
    input logic RegWriteM, MemToRegM,
    input logic [4:0] WriteRegM,
    input logic RegWriteE, MemToRegE,
    input logic [4:0] rsE, rtE,
    input logic [4:0] rsD, rtD,
    input logic BranchD, Jump,
    
    output logic [1:0] ForwardAE, ForwardBE,
    output logic ForwardAD, ForwardBD,
    output logic FlushE, StallD, StallF
    );
    
    logic lwstall, branchstall;
    
    always_comb begin
        // ForwardAE
        if((rsE != 0) && rsE == WriteRegM && RegWriteM)
            ForwardAE = 2'b10; // forward from MEM stage
        else if((rsE != 0) && rsE == WriteRegW && RegWriteW)
            ForwardAE = 2'b01; // forward from WB stage
        else
            ForwardAE = 2'b00; 
            
       // ForwardBE
        if((rtE != 0) && rtE == WriteRegM && RegWriteM)
            ForwardBE = 2'b10; // forward from MEM stage
        else if((rtE != 0) && rtE == WriteRegW && RegWriteW)
            ForwardBE = 2'b01; // forward from WB stage
        else
            ForwardBE = 2'b00;
        
        // ForwardAD and ForwardBD: forwarding for DECODE stage
        ForwardAD = rsD != 0 && rsD == WriteRegM && RegWriteM;
        ForwardBD = rtD != 0 && rtD == WriteRegM && RegWriteM;
        
        // StallD and StallF: for load-use and branch hazards
        lwstall = MemToRegE && (rsD == rtE || rtD == rtE);
        branchstall = (BranchD && RegWriteE && (WriteRegE == rsD || WriteRegE == rtD)) || 
                      (BranchD && MemToRegM && (WriteRegM == rsD || WriteRegM == rtD));
        
        StallD = lwstall || branchstall;
        StallF = lwstall || branchstall;
        FlushE = lwstall || branchstall || Jump;     
    end
endmodule

// TOP MODULE OF THE PIPELINED PROCESSOR
module mips(
    input logic clk, reset,
    
    output logic [31:0] PCF, InstrFetch, InstrDec,
    output logic [31:0] ALUOut, ResultW, WriteDataE, ReadDataM,
    output logic MemWrite, RegWrite, Jump, StallD, StallF
    );

    logic MemToReg, ALUSrc, RegDst, BranchD;
    logic [2:0] ALUControl;
    localparam ZERO = 1'b0;
    logic lwstall, branchstall;
    logic rsD, rtD, rdD;
	
	controller controls(InstrDec[31:26], InstrDec[5:0], MemToReg, MemWrite, ALUSrc, RegDst, RegWrite, Jump, ALUControl, BranchD);   
    datapath pipelined(clk, reset, MemToReg, ALUSrc, RegDst, RegWrite, ALUControl, BranchD, Jump, ZERO, ZERO, ZERO, MemWrite,
                InstrFetch, PCF, InstrDec, ALUOut, WriteDataE, ReadDataM, ResultW, StallF, StallD);
endmodule


module imem(input logic [5:0] addr, output logic [31:0] instr);
	always_comb
      case({addr,2'b00})
//		address		instruction
//		-------		-----------
        8'h00: instr = 32'h20080005; // addi $t0, $zero, 5
        8'h04: instr = 32'h2009000a; // addi $t1, $zero, 10
        8'h08: instr = 32'h200a000f; // addi $t2, $zero, 15
        8'h0c: instr = 32'h200b0014; // addi $t3, $zero, 20
        8'h10: instr = 32'h01096020; // add $t4, $t0, $t1
        8'h14: instr = 32'h012a6824; // and $t5, $t1, $t2
        8'h18: instr = 32'had100044; // sw $s0, 0x44($t0)
        8'h1c: instr = 32'h8d710044; // lw $s1, 0x44($t3)
	    default: instr = { 32{1'bx} };
	  endcase
endmodule


// 	***************************************************************************
// 	***************************************************************************
//	Below are the modules that you shouldn't need to modify at all..
//	***************************************************************************
//	***************************************************************************
module controller(input  logic[5:0] op, funct,
                  output logic     memtoreg, memwrite,
                  output logic     alusrc,
                  output logic     regdst, regwrite,
                  output logic     jump,
                  output logic[2:0] alucontrol,
                  output logic branch);

   logic [1:0] aluop;

   maindec md (op, memtoreg, memwrite, branch, alusrc, regdst, regwrite, 
         jump, aluop);

   aludec  ad (funct, aluop, alucontrol);
endmodule

// External data memory used by MIPS single-cycle processor
module dmem (input  logic        clk, we,
             input  logic[31:0]  a, wd,
             output logic[31:0]  rd);

   logic  [31:0] RAM[63:0];
  
   assign rd = RAM[a[31:2]];    // word-aligned  read (for lw)

   always_ff @(posedge clk)
     if (we)
       RAM[a[31:2]] <= wd;      // word-aligned write (for sw)
endmodule

module maindec (input logic[5:0] op, 
	              output logic memtoreg, memwrite, branch,
	              output logic alusrc, regdst, regwrite, jump,
	              output logic[1:0] aluop );
   logic [8:0] controls;

   assign {regwrite, regdst, alusrc, branch, memwrite,
                memtoreg,  aluop, jump} = controls;

  always_comb
    case(op)
      6'b000000: controls <= 9'b110000100; // R-type
      6'b100011: controls <= 9'b101001000; // LW
      6'b101011: controls <= 9'b001010000; // SW
      6'b000100: controls <= 9'b000100010; // BEQ
      6'b001000: controls <= 9'b101000000; // ADDI
      6'b000010: controls <= 9'b000000001; // J
      default:   controls <= 9'bxxxxxxxxx; // illegal op
    endcase
endmodule

module aludec (input    logic[5:0] funct,
               input    logic[1:0] aluop,
               output   logic[2:0] alucontrol);
  always_comb
    case(aluop)
      2'b00: alucontrol  = 3'b010;  // add  (for lw/sw/addi)
      2'b01: alucontrol  = 3'b110;  // sub   (for beq)
      default: case(funct)          // R-TYPE instructions
          6'b100000: alucontrol  = 3'b010; // ADD
          6'b100010: alucontrol  = 3'b110; // SUB
          6'b100100: alucontrol  = 3'b000; // AND
          6'b100101: alucontrol  = 3'b001; // OR
          6'b101010: alucontrol  = 3'b111; // SLT
          default:   alucontrol  = 3'bxxx; // ???
        endcase
    endcase
endmodule

module regfile (input    logic clk, reset, we3, 
                input    logic[4:0]  ra1, ra2, wa3, 
                input    logic[31:0] wd3, 
                output   logic[31:0] rd1, rd2);

  logic [31:0] rf [31:0];

  always_ff @(negedge clk)
	 if (reset)
		for (int i=0; i<32; i++) rf[i] = 32'b0;
     else if (we3) 
         rf [wa3] <= wd3;	

  assign rd1 = (ra1 != 0) ? rf [ra1] : 0;
  assign rd2 = (ra2 != 0) ? rf[ ra2] : 0;
endmodule

module alu(input  logic [31:0] a, b, 
           input  logic [2:0]  alucont, 
           output logic [31:0] result,
           output logic zero);
    
    always_comb
        case(alucont)
            3'b010: result = a + b;
            3'b110: result = a - b;
            3'b000: result = a & b;
            3'b001: result = a | b;
            3'b111: result = (a < b) ? 1 : 0;
            default: result = {32{1'bx}};
        endcase
    
    assign zero = (result == 0) ? 1'b1 : 1'b0;    
endmodule

module adder (input  logic[31:0] a, b,
              output logic[31:0] y);
     
     assign y = a + b;
endmodule

module signext (input  logic[15:0] a,
                output logic[31:0] y);
              
  assign y = {{16{a[15]}}, a};    // sign-extends 16-bit a
endmodule


// paramaterized 2-to-1 MUX
module mux2 #(parameter WIDTH = 8)
             (input  logic[WIDTH-1:0] d0, d1,  
              input  logic s, 
              output logic[WIDTH-1:0] y);
  
   assign y = s ? d1 : d0; 
endmodule

// Parametrized 4-to-1 MUX
module mux4 #(parameter WIDTH = 32) (
    input  logic [WIDTH-1:0] d0, d1, d2, d3, 
    input  logic [1:0]       sel,           
    output logic [WIDTH-1:0] y            
);
    always_comb begin
        case (sel)
            2'b00: y = d0; 
            2'b01: y = d1;  
            2'b10: y = d2; 
            2'b11: y = d3;
            default: y = {WIDTH{1'bx}}; 
        endcase
    end
endmodule