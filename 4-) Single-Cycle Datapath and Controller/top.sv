`timescale 1ns / 1ps
module top(
    input logic clk, reset,            
	output logic[31:0] writedata, dataadr, // writeData: rt & dataAdr: ALU result
    output logic[31:0] readdata,           
    output logic memwrite,
    output logic [31:0] instr, pc 
    );    

    mips mips(clk, reset, pc, instr, memwrite, dataadr, writedata, readdata);  
    imem imem(pc[7:0], instr);  
    dmem dmem(clk, memwrite, dataadr, writedata, readdata);
endmodule

// External Data Memory
module dmem(
    input logic clk, we,
    input logic[31:0] a, wd,
    output logic[31:0] rd
    );

    logic[31:0] RAM[63:0]; 
    assign rd = RAM[a[31:2]];   // word-aligned  read (for lw)

    always_ff @(posedge clk)
        if(we)
            RAM[a[31:2]] <= wd; // word-aligned write (for sw)
endmodule

// External Instruction Memory
module imem(input logic[7:0] addr, output logic[31:0] instr);
    always_comb
        case(addr)
//		address		instruction
//		-------		-----------
        // JALADD
		8'h00: instr = 32'h20040008;    // addi $a0, $zero, 8
		8'h04: instr = 32'h20050008;    // addi $a1, $zero, 8
		8'h08: instr = 32'h0085f801;    // jaladd $a0, $a1
		8'h0c: instr = 32'h20060003;    // addi $a2, $zero, 3
		8'h10: instr = 32'h23ff0006;    // addi $ra, $ra, 6
		8'h14: instr = 32'h23e60000;    // addi $a2, $ra, 0
        
        // SW+
        // 8'h00: instr = 32'h20040050;    // addi $a0, $zero, 80
		// 8'h04: instr = 32'h20050001;    // addi $a1, $zero, 1
		// 8'h08: instr = 32'h20060005;    // addi $a2, $zero, 5
		// 8'h0c: instr = 32'h10a60003;    // beq $a1, $a2, 0x1c
		// 8'h10: instr = 32'hbc850000;    // sw+ $a1, 0($a0)
		// 8'h14: instr = 32'h20a50001;    // addi $a1, $a1, 1
		// 8'h18: instr = 32'h08000003;    // j 0x0c
		// 8'h1c: instr = 32'h00043820;    // add $a3, $zero, $a0     
	    default: instr = {32{1'bx}};	   // unknown address
	    endcase
endmodule


// Single-Cycle MIPS Processor
module mips(
    input logic clk, reset,
    output logic[31:0] pc,
    input  logic[31:0] instr,
    output logic memwrite,
    output logic[31:0] aluout, writedata,
    input  logic[31:0] readdata
    );

    // Control Signals
    logic memtoreg, pcsrc, zero, alusrc, regwrite, jump; 
    logic jaladdpc, jaladdra, swplus;
    logic[1:0] regdst; // 2-bit regdst
    logic[2:0] alucontrol;

    controller c(instr[31:26], instr[5:0], zero, memtoreg, memwrite, pcsrc,
                 alusrc, regdst, regwrite, jump, jaladdpc, jaladdra, swplus, alucontrol);

    datapath dp(clk, reset, memtoreg, pcsrc, alusrc, regdst, regwrite, jump, 
      jaladdpc, jaladdra, swplus, alucontrol, zero, pc, instr, aluout, writedata, readdata);
endmodule

// CONTROLLER
module controller(
    input logic[5:0] op, funct,
    input  logic zero,
    output logic memtoreg, memwrite,
    output logic pcsrc, alusrc,
    output logic[1:0] regdst,
    output logic regwrite, jump,
    output logic jaladdpc, jaladdra, swplus,
    output logic[2:0] alucontrol
    );

    logic[1:0] aluop;
    logic branch;

    maindec md(op, funct, memtoreg, memwrite, branch, alusrc, regdst, regwrite, 
		       jump, jaladdpc, jaladdra, swplus, aluop);

    aludec  ad(funct, aluop, alucontrol);

    assign pcsrc = branch & zero;
endmodule

// MAIN DECODER
module maindec(
    input logic[5:0] opcode, funct,
    output logic memtoreg, memwrite, branch,
    output logic alusrc, 
    output logic[1:0] regdst, 
    output logic regwrite, jump, 
    output logic jaladdpc, jaladdra, swplus,
    output logic[1:0] aluop
    );
   
    logic[12:0] controls;
    assign{regwrite, regdst, alusrc, branch, memwrite,
           memtoreg, aluop, jump, jaladdpc, jaladdra, swplus} = controls;

    always_comb
        case(opcode)
        6'b000000: begin 
            case(funct) 
                6'b000001: controls <= 13'b1_11_0_0_0_0_10_0_1_1_0; // JALADD: aluop=10, funct=000001(add)
                default:   controls <= 13'b1010000100_000; // R-type
            endcase end
        6'b100011: controls <= 13'b1001001000_000; // LW
        6'b101011: controls <= 13'b0001010000_000; // SW
        6'b000100: controls <= 13'b0000100010_000; // BEQ
        6'b001000: controls <= 13'b1001000000_000; // ADDI
        6'b000010: controls <= 13'b0000000001_000; // J 
        6'b101111: controls <= 13'b1_10_1_0_1_0_00_0_0_0_1; // SW+
        default:   controls <= 13'bxxxxxxxxxxxxx; // Illegal opcode
        endcase
endmodule

module aludec(
    input logic[5:0] funct,
    input logic[1:0] aluop,
    output logic[2:0] alucontrol
    );
  
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
            6'b000001: alucontrol  = 3'b010; // JALADD (ADD)
            default:   alucontrol  = 3'bxxx;
            endcase
        endcase
endmodule

// DATAPATH
module datapath(
    input logic clk, reset, memtoreg, pcsrc, alusrc,
    input logic[1:0] regdst,
    input logic regwrite, jump, 
    input logic jaladdpc, jaladdra, swplus,
    input logic[2:0] alucontrol, 
    
    output logic zero, 
    output logic[31:0] pc, 
	input  logic[31:0] instr,
    output logic[31:0] aluout, writedata, 
	input  logic[31:0] readdata
	);

    logic [4:0] writereg;
    logic [31:0] pcnext, pcnextbr, pcplus4, pcbranch, rsplus4;
    logic [31:0] signimm, signimmsh, srca, srcb, result, regwritedata;
    logic [31:0] jaladd_target;
    logic [31:0] pcnext_temp, result_temp;
    
    // NextPC (PC + 4)
    flopr #(32) pcreg(clk, reset, pcnext, pc);
    adder       pcadd1(pc, 32'b100, pcplus4);
    sl2         immsh(signimm, signimmsh);
    adder       pcadd2(pcplus4, signimmsh, pcbranch);  
    mux2 #(32)  pcbrmux(pcplus4, pcbranch, pcsrc, pcnextbr);
    mux2 #(32)  pcmux(pcnextbr, {pcplus4[31:28], instr[25:0], 2'b00}, jump, pcnext_temp);
        
    // Register File logic
    regfile rf(clk, regwrite, instr[25:21], instr[20:16], writereg, regwritedata, srca, writedata);
        
    // 4-to-1 MUX for WriteReg (2-bit RegDst is control signal)
    mux4 #(5) wrmux(instr[20:16], instr[15:11], instr[25:21], 5'd31, regdst, writereg);
    
    // Result Mux
    mux2 #(32) resmux(aluout, readdata, memtoreg, result_temp);
    signext se(instr[15:0], signimm);

    // ALU logic: RF[rs] + signImm
    mux2 #(32) srcbmux(writedata, signimm, alusrc, srcb);
    alu alu(srca, srcb, alucontrol, aluout, zero);
    
    // JALADD
    adder jaladd_addr(srca, writedata, jaladd_target);
    mux2 #(32) jalpc(pcnext_temp, jaladd_target, jaladdpc, pcnext);
    mux2 #(32) writemux(result, pcplus4, jaladdra, regwritedata);
        
    // SW+
    adder rsadd4(srca, 32'd4, rsplus4); 
    mux2 #(32) swplusmux(result_temp, rsplus4, swplus, result);   
endmodule


// REGISTER FILE (RF)
module regfile(
    input logic clk, we3, 
    input logic[4:0]  ra1, ra2, wa3, 
    input logic[31:0] wd3, 
    output logic[31:0] rd1, rd2
    );

    logic[31:0] rf [31:0];

    always_ff@(posedge clk)
        if(we3) 
            rf [wa3] <= wd3;	

    assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
    assign rd2 = (ra2 != 0) ? rf[ra2] : 0;
endmodule

// ALU OPERATIONS
module alu(
    input logic[31:0] a, b,
    input logic[2:0] alucont, 
    output logic[31:0] result,
    output logic zero
    );    
             
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


// Adder
module adder(input  logic[31:0] a, b, output logic[31:0] y);    
    assign y = a + b;
endmodule

// Shift left 2
module sl2(input  logic[31:0] a, output logic[31:0] y);    
    assign y = {a[29:0], 2'b00};
endmodule

// SignImm
module signext(input  logic[15:0] a, output logic[31:0] y);             
    assign y = {{16{a[15]}}, a};    // sign-extends 16-bit a
endmodule

// Parameterized Register
module flopr #(parameter WIDTH = 8)(
    input logic clk, reset, 
    input logic[WIDTH-1:0] d, 
    output logic[WIDTH-1:0] q
    );

    always_ff@(posedge clk, posedge reset)
        if (reset) q <= {WIDTH{1'b0}}; 
        else       q <= d;
endmodule


// 2-to-1 MUX
module mux2 #(parameter WIDTH = 8)(
    input logic[WIDTH-1:0] d0, d1,  
    input logic s, 
    output logic[WIDTH-1:0] y
    );
  
    assign y = s ? d1 : d0; 
endmodule

// 4-to-1 MUX for RegDst: rt, rd, rs(sw+), $ra(jaladd)
module mux4 #(parameter WIDTH = 8)(
    input logic[WIDTH-1:0] d0, d1, d2, d3,
    input logic[1:0] sel,
    output logic[WIDTH-1:0] y
    );
    
    always_comb 
    case(sel)
        2'b00: y = d0;
        2'b01: y = d1;
        2'b10: y = d2;
        2'b11: y = d3;
        default: y = {WIDTH{1'bx}};
    endcase
endmodule
