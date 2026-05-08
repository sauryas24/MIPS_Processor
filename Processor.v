`timescale 1ns / 1ps
`include "defs.vh"
module Processor(input clk, output halt, input reset, output reg [7:0]
pc, input [31:0] ins, output [31:0] io_reg1, output [31:0] io_reg2,
output [31:0] io_reg3, output [31:0] io_reg4);
wire [5:0] opcode; // Extracted from ins
wire [5:0] func; // Extracted from ins
wire [4:0] shift_amount; // Extracted from ins
wire [4:0] src1_addr; // rs extracted from ins (input to RF)
wire [4:0] src2_addr; // rt extracted from ins (input to RF)
wire [31:0] src1; // Output of RF, input to ALU
wire [31:0] src2; // Output of RF, input to ALU
wire [4:0] dest_addr; // rt/rd extracted from ins (input to RF)
wire [31:0] dest_data; // Output of ALU, input to RF
wire dest_data_valid; // Output of ALU, input to RF
wire [7:0] next_pc; // Next instruction address
wire [15:0] imm; // Immediate extracted from ins
reg [31:0] io_reg [0:3]; // Circular I/O buffer
reg [1:0] io_reg_index; // Index to circular I/O buffer
reg fetched; // Is first instruction fetched? 
reg [1:0] state;
reg [31:0] A_reg;
reg [31:0] B_reg;
reg [31:0] ALU_out_reg;
assign io_reg1 = io_reg[0];
assign io_reg2 = io_reg[1];
assign io_reg3 = io_reg[2];
assign io_reg4 = io_reg[3];
RegisterFile rf (src1_addr, src2_addr, src1, src2, dest_addr, ALU_out_reg, dest_data_valid & fetched & (state==2'b10), clk);
wire [31:0] imm_sign_ext = {{16{imm[15]}}, imm};
wire [31:0] imm_zero_ext = {16'b0, imm};
wire [31:0] second_val = (opcode==`OP_REG) ? B_reg : (opcode==`OP_ADDI) ? imm_sign_ext : imm_zero_ext;
ALU alu (A_reg, second_val, shift_amount, opcode, func, dest_data, dest_data_valid);
assign next_pc = (fetched & ~halt) ? pc + 1 : 8'b0;
always @(posedge clk) begin
if (reset) begin
state<=2'b00;
pc <= 8'b0;
io_reg_index <= 2'b0;
fetched <= 1'b0;
end
else begin
fetched<= 1'b1;
case(state)
2'b00: begin
A_reg<=src1;
B_reg<=src2;
state<=state+1;
end
2'b01: begin
ALU_out_reg<=dest_data;
if ((opcode == `OP_REG) && (func == `FUNC_SYSCALL) &&
(src1 == `SYS_write) &&(state==1'b1)) begin
io_reg_index <= io_reg_index + 1;
io_reg[io_reg_index] <= B_reg;
end
state<=state+1;
end
2'b10: begin
pc<= halt? pc : next_pc;
state<=2'b00;
end
endcase
end
end

// Decode instruction
assign opcode = ins [31:26];
assign src1_addr = ins [25:21];
assign src2_addr = ins [20:16];
assign dest_addr = (opcode==6'h0)? ins[15:11] : ins[20:16];
assign shift_amount = ins [10:6];
assign func = ins [5:0];
assign imm = ins [15:0];
assign halt = (reset | ~fetched) ? 1'b0 : (((opcode == `OP_REG)
&& (func == `FUNC_SYSCALL) && (src1 == `SYS_exit)) ? 1'b1 :
1'b0);
endmodule // end of Processor module 
