`timescale 1ns/1ps

module riscky_alu(clk, rst);

    input clk, rst;

    // IF stage
    wire [31:0] address_out;
    wire [31:0] pc1_out;
    wire [31:0] instruction;

    // IF/ID register outputs
    wire [31:0] ifid_instruction;
    wire [31:0] ifid_address_out;
    wire [31:0] ifid_pc1_out;

    // ID stage
    wire [31:0] read_data1;
    wire [31:0] read_data2;
    wire [31:0] imm_add;
    wire        aluscr_mux;
    wire        regwrite_from_id;
    wire        regwrite_reg;
    wire [31:0] rd_write;
    wire        b_en;
    wire        memwrite_en;
    wire        memread_en;
    wire        auipc;
    wire [1:0]  ALU_op_in;
    wire [1:0]  jump_en;
    wire [1:0]  memtoreg_en;
    wire [3:0]  alucntrl_alu;
    wire [4:0]  id_rs1;
    wire [4:0]  id_rs2;
    wire [4:0]  id_rd;

    // ID/EX register outputs
    wire [31:0] idex_read_data1;
    wire [31:0] idex_read_data2;
    wire [31:0] idex_imm_add;
    wire [31:0] idex_address_out;
    wire [31:0] idex_pc1_out;
    wire        idex_aluscr_mux;
    wire        idex_auipc;
    wire [3:0]  idex_alucntrl_alu;
    wire        idex_b_en;
    wire [1:0]  idex_jump_en;
    wire        idex_memread_en;
    wire        idex_memwrite_en;
    wire [1:0]  idex_memtoreg_en;
    wire        idex_regwrite_from_id;
    wire [4:0]  idex_rs1;
    wire [4:0]  idex_rs2;
    wire [4:0]  idex_rd;

    // EX stage
    wire [31:0] alu_address;
    wire        zero_en;
    wire [31:0] adder_out;
    wire [1:0]  pc_selector;
    wire [31:0] mux1_out;
    wire [31:0] ex_read_data2;
    wire        ex_memread_en;
    wire        ex_memwrite_en;
    wire [1:0]  ex_memtoreg_en;
    wire        ex_regwrite_reg;
    wire [31:0] ex_pc1_out;

    // EX/MEM register outputs
    wire [31:0] exmem_alu_address;
    wire [31:0] exmem_read_data2;
    wire        exmem_memread_en;
    wire        exmem_memwrite_en;
    wire [1:0]  exmem_memtoreg_en;
    wire        exmem_regwrite_reg;
    wire [31:0] exmem_pc1_out;
    wire [4:0]  exmem_rd;

    // MEM stage
    wire [31:0] read_data_final;

    // MEM/WB register outputs
    wire [31:0] memwb_alu_address;
    wire [31:0] memwb_read_data_final;
    wire [31:0] memwb_pc1_out;
    wire [1:0]  memwb_memtoreg_en;
    wire        memwb_regwrite_reg;
    wire [4:0]  memwb_rd;
    wire [31:0] memwb_rd_write;

    // hazard and forwarding
    wire        stall;
    wire        flush;
    wire [1:0]  forwardA;
    wire [1:0]  forwardB;
    wire [1:0]  forwardS;

    assign flush          = (pc_selector != 2'b00) && !rst;
    assign memwb_rd_write = rd_write;

    stage_IF s_if (
        .clk(clk), .rst(rst),
        .address_in(adder_out),
        .pc_selector(pc_selector),
        .alu_address(alu_address),
        .stall(stall),
        .address_out(address_out),
        .pc1_out(pc1_out),
        .instruction(instruction)
    );

    reg_IF_ID if_id (
        .clk(clk), .rst(rst),
        .flush(flush), .stall(stall),
        .instruction_in(instruction),
        .address_out_in(address_out),
        .pc1_out_in(pc1_out),
        .instruction_out(ifid_instruction),
        .address_out_out(ifid_address_out),
        .pc1_out_out(ifid_pc1_out)
    );

    stage_ID s_id (
        .clk(clk), .rst(rst),
        .instruction(ifid_instruction),
        .regwrite_reg(memwb_regwrite_reg),
        .rd_write(rd_write),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .imm_add(imm_add),
        .aluscr_mux(aluscr_mux),
        .memtoreg_en(memtoreg_en),
        .regwrite_reg_out(regwrite_from_id),
        .memread_en(memread_en),
        .memwrite_en(memwrite_en),
        .b_en(b_en),
        .ALU_op_in(ALU_op_in),
        .jump_en(jump_en),
        .auipc(auipc),
        .alucntrl_alu(alucntrl_alu),
        .rs1(id_rs1), .rs2(id_rs2), .rd(id_rd),
        .wb_rd(memwb_rd)
    );

    reg_ID_EX id_ex (
        .clk(clk), .rst(rst),
        .flush(flush), .stall(stall),
        .read_data1_in(read_data1),
        .read_data2_in(read_data2),
        .imm_add_in(imm_add),
        .address_out_in(ifid_address_out),
        .pc1_out_in(ifid_pc1_out),
        .aluscr_mux_in(aluscr_mux),
        .auipc_in(auipc),
        .alucntrl_alu_in(alucntrl_alu),
        .b_en_in(b_en),
        .jump_en_in(jump_en),
        .memread_en_in(memread_en),
        .memwrite_en_in(memwrite_en),
        .memtoreg_en_in(memtoreg_en),
        .regwrite_from_id_in(regwrite_from_id),
        .rs1_in(id_rs1), .rs2_in(id_rs2), .rd_in(id_rd),
        .read_data1_out(idex_read_data1),
        .read_data2_out(idex_read_data2),
        .imm_add_out(idex_imm_add),
        .address_out_out(idex_address_out),
        .pc1_out_out(idex_pc1_out),
        .aluscr_mux_out(idex_aluscr_mux),
        .auipc_out(idex_auipc),
        .alucntrl_alu_out(idex_alucntrl_alu),
        .b_en_out(idex_b_en),
        .jump_en_out(idex_jump_en),
        .memread_en_out(idex_memread_en),
        .memwrite_en_out(idex_memwrite_en),
        .memtoreg_en_out(idex_memtoreg_en),
        .regwrite_from_id_out(idex_regwrite_from_id),
        .rs1_out(idex_rs1), .rs2_out(idex_rs2), .rd_out(idex_rd)
    );

    stage_EX s_ex (
        .read_data1(idex_read_data1),
        .read_data2(idex_read_data2),
        .imm_add(idex_imm_add),
        .address_out(idex_address_out),
        .pc1_out_in(idex_pc1_out),
        .aluscr_mux(idex_aluscr_mux),
        .auipc(idex_auipc),
        .alucntrl_alu(idex_alucntrl_alu),
        .b_en(idex_b_en),
        .jump_en(idex_jump_en),
        .memread_en_in(idex_memread_en),
        .memwrite_en_in(idex_memwrite_en),
        .memtoreg_en_in(idex_memtoreg_en),
        .regwrite_reg_in(idex_regwrite_from_id),
        .forwardA(forwardA), .forwardB(forwardB), .forwardS(forwardS),
        .exmem_alu_address(exmem_alu_address),
        .memwb_rd_write(memwb_rd_write),
        .mux1_out(mux1_out),
        .alu_address(alu_address),
        .zero_en(zero_en),
        .adder_out(adder_out),
        .pc_selector(pc_selector),
        .read_data2_out(ex_read_data2),
        .memread_en_out(ex_memread_en),
        .memwrite_en_out(ex_memwrite_en),
        .memtoreg_en_out(ex_memtoreg_en),
        .regwrite_reg_out(ex_regwrite_reg),
        .pc1_out_out(ex_pc1_out)
    );

    reg_EX_MEM ex_mem (
        .clk(clk), .rst(rst),
        .alu_address_in(alu_address),
        .read_data2_in(ex_read_data2),
        .memread_en_in(ex_memread_en),
        .memwrite_en_in(ex_memwrite_en),
        .memtoreg_en_in(ex_memtoreg_en),
        .regwrite_reg_in(ex_regwrite_reg),
        .pc1_out_in(ex_pc1_out),
        .rd_in(idex_rd),
        .alu_address_out(exmem_alu_address),
        .read_data2_out(exmem_read_data2),
        .memread_en_out(exmem_memread_en),
        .memwrite_en_out(exmem_memwrite_en),
        .memtoreg_en_out(exmem_memtoreg_en),
        .regwrite_reg_out(exmem_regwrite_reg),
        .pc1_out_out(exmem_pc1_out),
        .rd_out(exmem_rd)
    );

    stage_MEM s_mem (
        .clk(clk), .rst(rst),
        .alu_address(exmem_alu_address),
        .read_data2(exmem_read_data2),
        .memread_en(exmem_memread_en),
        .memwrite_en(exmem_memwrite_en),
        .read_data_final(read_data_final)
    );

    reg_MEM_WB mem_wb (
        .clk(clk), .rst(rst),
        .alu_address_in(exmem_alu_address),
        .read_data_final_in(read_data_final),
        .pc1_out_in(exmem_pc1_out),
        .memtoreg_en_in(exmem_memtoreg_en),
        .regwrite_reg_in(exmem_regwrite_reg),
        .rd_in(exmem_rd),
        .alu_address_out(memwb_alu_address),
        .read_data_final_out(memwb_read_data_final),
        .pc1_out_out(memwb_pc1_out),
        .memtoreg_en_out(memwb_memtoreg_en),
        .regwrite_reg_out(memwb_regwrite_reg),
        .rd_out(memwb_rd)
    );

    stage_WB s_wb (
        .alu_address(memwb_alu_address),
        .read_data_final(memwb_read_data_final),
        .pc1_out(memwb_pc1_out),
        .memtoreg_en(memwb_memtoreg_en),
        .regwrite_reg_in(memwb_regwrite_reg),
        .regwrite_reg_out(regwrite_reg),
        .rd_write(rd_write)
    );

    forwarding_unit fu (
        .idex_rs1(idex_rs1), .idex_rs2(idex_rs2),
        .exmem_rd(exmem_rd),
        .exmem_regwrite(exmem_regwrite_reg),
        .exmem_memread_en(exmem_memread_en),
        .memwb_rd(memwb_rd),
        .memwb_regwrite(memwb_regwrite_reg),
        .idex_aluscr_mux(idex_aluscr_mux),
        .forwardA(forwardA), .forwardB(forwardB), .forwardS(forwardS)
    );

    hazard_detection_unit hdu (
        .idex_memread_en(idex_memread_en),
        .idex_rd(idex_rd),
        .id_rs1(ifid_instruction[19:15]),
        .id_rs2(ifid_instruction[24:20]),
        .stall(stall)
    );

endmodule


// IF/ID register
module reg_IF_ID (
    input             clk, rst,
    input             flush,
    input             stall,
    input      [31:0] instruction_in,
    input      [31:0] address_out_in,
    input      [31:0] pc1_out_in,
    output reg [31:0] instruction_out,
    output reg [31:0] address_out_out,
    output reg [31:0] pc1_out_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            instruction_out <= 32'b0;
            address_out_out <= 32'b0;
            pc1_out_out     <= 32'b0;
        end else if (!stall) begin
            instruction_out <= instruction_in;
            address_out_out <= address_out_in;
            pc1_out_out     <= pc1_out_in;
        end
    end
endmodule


// ID/EX register
module reg_ID_EX (
    input             clk, rst,
    input             flush,
    input             stall,
    input      [31:0] read_data1_in,
    input      [31:0] read_data2_in,
    input      [31:0] imm_add_in,
    input      [31:0] address_out_in,
    input      [31:0] pc1_out_in,
    input             aluscr_mux_in,
    input             auipc_in,
    input      [3:0]  alucntrl_alu_in,
    input             b_en_in,
    input      [1:0]  jump_en_in,
    input             memread_en_in,
    input             memwrite_en_in,
    input      [1:0]  memtoreg_en_in,
    input             regwrite_from_id_in,
    input      [4:0]  rs1_in,
    input      [4:0]  rs2_in,
    input      [4:0]  rd_in,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] imm_add_out,
    output reg [31:0] address_out_out,
    output reg [31:0] pc1_out_out,
    output reg        aluscr_mux_out,
    output reg        auipc_out,
    output reg [3:0]  alucntrl_alu_out,
    output reg        b_en_out,
    output reg [1:0]  jump_en_out,
    output reg        memread_en_out,
    output reg        memwrite_en_out,
    output reg [1:0]  memtoreg_en_out,
    output reg        regwrite_from_id_out,
    output reg [4:0]  rs1_out,
    output reg [4:0]  rs2_out,
    output reg [4:0]  rd_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush || stall) begin
            read_data1_out       <= 32'b0;
            read_data2_out       <= 32'b0;
            imm_add_out          <= 32'b0;
            address_out_out      <= 32'b0;
            pc1_out_out          <= 32'b0;
            aluscr_mux_out       <= 1'b0;
            auipc_out            <= 1'b0;
            alucntrl_alu_out     <= 4'b0;
            b_en_out             <= 1'b0;
            jump_en_out          <= 2'b0;
            memread_en_out       <= 1'b0;
            memwrite_en_out      <= 1'b0;
            memtoreg_en_out      <= 2'b0;
            regwrite_from_id_out <= 1'b0;
            rs1_out              <= 5'b0;
            rs2_out              <= 5'b0;
            rd_out               <= 5'b0;
        end else begin
            read_data1_out       <= read_data1_in;
            read_data2_out       <= read_data2_in;
            imm_add_out          <= imm_add_in;
            address_out_out      <= address_out_in;
            pc1_out_out          <= pc1_out_in;
            aluscr_mux_out       <= aluscr_mux_in;
            auipc_out            <= auipc_in;
            alucntrl_alu_out     <= alucntrl_alu_in;
            b_en_out             <= b_en_in;
            jump_en_out          <= jump_en_in;
            memread_en_out       <= memread_en_in;
            memwrite_en_out      <= memwrite_en_in;
            memtoreg_en_out      <= memtoreg_en_in;
            regwrite_from_id_out <= regwrite_from_id_in;
            rs1_out              <= rs1_in;
            rs2_out              <= rs2_in;
            rd_out               <= rd_in;
        end
    end
endmodule


// EX/MEM register
module reg_EX_MEM (
    input             clk, rst,
    input      [31:0] alu_address_in,
    input      [31:0] read_data2_in,
    input             memread_en_in,
    input             memwrite_en_in,
    input      [1:0]  memtoreg_en_in,
    input             regwrite_reg_in,
    input      [31:0] pc1_out_in,
    input      [4:0]  rd_in,
    output reg [31:0] alu_address_out,
    output reg [31:0] read_data2_out,
    output reg        memread_en_out,
    output reg        memwrite_en_out,
    output reg [1:0]  memtoreg_en_out,
    output reg        regwrite_reg_out,
    output reg [31:0] pc1_out_out,
    output reg [4:0]  rd_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_address_out  <= 32'b0;
            read_data2_out   <= 32'b0;
            memread_en_out   <= 1'b0;
            memwrite_en_out  <= 1'b0;
            memtoreg_en_out  <= 2'b0;
            regwrite_reg_out <= 1'b0;
            pc1_out_out      <= 32'b0;
            rd_out           <= 5'b0;
        end else begin
            alu_address_out  <= alu_address_in;
            read_data2_out   <= read_data2_in;
            memread_en_out   <= memread_en_in;
            memwrite_en_out  <= memwrite_en_in;
            memtoreg_en_out  <= memtoreg_en_in;
            regwrite_reg_out <= regwrite_reg_in;
            pc1_out_out      <= pc1_out_in;
            rd_out           <= rd_in;
        end
    end
endmodule


// MEM/WB register
module reg_MEM_WB (
    input             clk, rst,
    input      [31:0] alu_address_in,
    input      [31:0] read_data_final_in,
    input      [31:0] pc1_out_in,
    input      [1:0]  memtoreg_en_in,
    input             regwrite_reg_in,
    input      [4:0]  rd_in,
    output reg [31:0] alu_address_out,
    output reg [31:0] read_data_final_out,
    output reg [31:0] pc1_out_out,
    output reg [1:0]  memtoreg_en_out,
    output reg        regwrite_reg_out,
    output reg [4:0]  rd_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_address_out     <= 32'b0;
            read_data_final_out <= 32'b0;
            pc1_out_out         <= 32'b0;
            memtoreg_en_out     <= 2'b0;
            regwrite_reg_out    <= 1'b0;
            rd_out              <= 5'b0;
        end else begin
            alu_address_out     <= alu_address_in;
            read_data_final_out <= read_data_final_in;
            pc1_out_out         <= pc1_out_in;
            memtoreg_en_out     <= memtoreg_en_in;
            regwrite_reg_out    <= regwrite_reg_in;
            rd_out              <= rd_in;
        end
    end
endmodule


// IF stage
module stage_IF (
    input         clk, rst,
    input  [31:0] address_in,
    input  [1:0]  pc_selector,
    input  [31:0] alu_address,
    input         stall,
    output [31:0] address_out,
    output [31:0] pc1_out,
    output [31:0] instruction
);
    wire [31:0] next_pc;

    muxy3 m3(.imm_plus_pc_in(address_in), .pc_plus_4_in(pc1_out),
             .alu_in(alu_address), .pc_select(pc_selector), .pc_in(next_pc));

    program_count pc1(.clk(clk), .rst(rst), .stall(stall),
                      .pc_in(next_pc), .address(address_out));

    pcplus4 pc2(.pc1_in(address_out), .pc1_out(pc1_out));

    instr_mem imem(.address(address_out), .instr_out(instruction));
endmodule


// ID stage
module stage_ID (
    input         clk, rst,
    input  [31:0] instruction,
    input         regwrite_reg,
    input  [31:0] rd_write,
    output [31:0] read_data1,
    output [31:0] read_data2,
    output [31:0] imm_add,
    output        aluscr_mux,
    output [1:0]  memtoreg_en,
    output        regwrite_reg_out,
    output        memread_en,
    output        memwrite_en,
    output        b_en,
    output [1:0]  ALU_op_in,
    output [1:0]  jump_en,
    output        auipc,
    output [3:0]  alucntrl_alu,
    output [4:0]  rs1, rs2, rd,
    input  [4:0]  wb_rd
);
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd  = instruction[11:7];

    reg_file rf1(.clk(clk), .rst(rst),
                 .r1(instruction[19:15]), .r2(instruction[24:20]),
                 .rd(wb_rd), .write_en(regwrite_reg),
                 .write_instr(rd_write),
                 .read_instr_1(read_data1), .read_instr_2(read_data2));

    imm_value imm1(.opcode(instruction[6:0]), .instr_in(instruction), .imm_val(imm_add));

    cntrl_unit cu1(.opcode(instruction[6:0]),
                   .ALUscr(aluscr_mux), .memtoreg(memtoreg_en),
                   .regwrite(regwrite_reg_out), .memread(memread_en),
                   .memwrite(memwrite_en), .branch(b_en),
                   .ALUop(ALU_op_in), .jump(jump_en), .auipc_sel(auipc));

    ALU_control alu_cntr1(.fun3(instruction[14:12]), .fun7(instruction[30]),
                          .ALU_op_in(ALU_op_in), .ALU_control_out(alucntrl_alu));
endmodule


// EX stage
module stage_EX (
    input  [31:0] read_data1, read_data2, imm_add,
    input  [31:0] address_out, pc1_out_in,
    input         aluscr_mux, auipc,
    input  [3:0]  alucntrl_alu,
    input         b_en,
    input  [1:0]  jump_en,
    input         memread_en_in, memwrite_en_in,
    input  [1:0]  memtoreg_en_in,
    input         regwrite_reg_in,
    input  [1:0]  forwardA, forwardB, forwardS,
    input  [31:0] exmem_alu_address, memwb_rd_write,
    output [31:0] mux1_out, alu_address,
    output        zero_en,
    output [31:0] adder_out,
    output [1:0]  pc_selector,
    output [31:0] read_data2_out,
    output        memread_en_out, memwrite_en_out,
    output [1:0]  memtoreg_en_out,
    output        regwrite_reg_out,
    output [31:0] pc1_out_out
);
    wire [31:0] read_data1_mux4;
    wire [31:0] alu_input_A, alu_input_B;
    wire [31:0] forwarded_rs2;

    assign forwarded_rs2    = (forwardS == 2'b10) ? exmem_alu_address :
                              (forwardS == 2'b01) ? memwb_rd_write : read_data2;
    assign read_data2_out   = forwarded_rs2;
    assign memread_en_out   = memread_en_in;
    assign memwrite_en_out  = memwrite_en_in;
    assign memtoreg_en_out  = memtoreg_en_in;
    assign regwrite_reg_out = regwrite_reg_in;
    assign pc1_out_out      = pc1_out_in;

    muxy4 m4(.read_data1_in(read_data1), .pc_in(address_out),
             .auipc_sel(auipc), .mux4_out(read_data1_mux4));

    muxy1 m1(.r2_in(read_data2), .imm_in(imm_add),
             .ALU_scr(aluscr_mux), .mux1(mux1_out));

    muxy5 m5(.read_data1_mux4(read_data1_mux4), .memwb_rd_write(memwb_rd_write),
             .exmem_alu_address(exmem_alu_address), .forwardA(forwardA),
             .alu_input_A(alu_input_A));

    muxy6 m6(.mux1_out(mux1_out), .memwb_rd_write(memwb_rd_write),
             .exmem_alu_address(exmem_alu_address), .forwardB(forwardB),
             .alu_input_B(alu_input_B));

    ALU_op alu1(.A(alu_input_A), .B(alu_input_B),
                .ALU_control_in(alucntrl_alu),
                .ALU_result(alu_address), .zero(zero_en));

    adder a1(.imm_val(imm_add), .pc_out(address_out), .imm_plus_pc_out(adder_out));

    anding and1(.branch(b_en), .zero(zero_en), .jump(jump_en), .pc_select(pc_selector));
endmodule


// MEM stage
module stage_MEM (
    input         clk, rst,
    input  [31:0] alu_address, read_data2,
    input         memread_en, memwrite_en,
    output [31:0] read_data_final
);
    data_memory d1(.clk(clk), .rst(rst),
                   .write_data(read_data2),
                   .mem_read(memread_en), .mem_write(memwrite_en),
                   .mem_address(alu_address), .read_data(read_data_final));
endmodule


// WB stage
module stage_WB (
    input  [31:0] alu_address, read_data_final, pc1_out,
    input  [1:0]  memtoreg_en,
    input         regwrite_reg_in,
    output        regwrite_reg_out,
    output [31:0] rd_write
);
    assign regwrite_reg_out = regwrite_reg_in;

    muxy2 m2(.rd_in(alu_address), .read_data_out(read_data_final),
             .pc_jump_in(pc1_out), .memtoreg(memtoreg_en),
             .reg_write_data(rd_write));
endmodule


// base modules

module program_count(clk, rst, stall, address, pc_in);
    input clk, rst, stall;
    input [31:0] pc_in;
    output reg [31:0] address;
    always @(posedge clk or posedge rst) begin
        if (rst)         address <= 32'b0;
        else if (!stall) address <= pc_in;
    end
endmodule

module pcplus4(pc1_out, pc1_in);
    input  [31:0] pc1_in;
    output [31:0] pc1_out;
    assign pc1_out = pc1_in + 4;
endmodule

module instr_mem(address, instr_out);
    input  [31:0] address;
    output [31:0] instr_out;
    reg [31:0] inst_mem [63:0];
    integer i;
    initial begin
        for(i = 0; i < 64; i = i+1)
            inst_mem[i] = 32'h00000013;
        inst_mem[0] = 32'h00500093; // addi x1, x0, 5
        inst_mem[1] = 32'h00100113; // addi x2, x0, 1
        inst_mem[2] = 32'h002081B3; // add  x3, x1, x2
        inst_mem[3] = 32'h003101B3; // add  x3, x2, x3
        inst_mem[4] = 32'h00312023; // sw   x3, 0(x2)
        inst_mem[5] = 32'h00012203; // lw   x4, 0(x2)
        inst_mem[6] = 32'h004202B3; // add  x5, x4, x4
        inst_mem[7] = 32'h00519263; // bne  x3, x5, +4
        inst_mem[8] = 32'h00300313; // addi x6, x0, 3
        inst_mem[9] = 32'h006283B3; // add  x7, x5, x6
    end
    assign instr_out = inst_mem[address[7:2]];
endmodule

module reg_file(clk, rst, r1, r2, rd, write_en, write_instr, read_instr_1, read_instr_2);
    input clk, rst;
    input [4:0] r1, r2, rd;
    input write_en;
    input [31:0] write_instr;
    output [31:0] read_instr_1, read_instr_2;
    integer i;
    reg [31:0] register [31:0];
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for(i = 0; i < 32; i = i+1)
                register[i] <= 32'b0;
        end else if (write_en && rd != 5'b0)
            register[rd] <= write_instr;
    end
    assign read_instr_1 = (write_en && rd != 5'b0 && rd == r1) ? write_instr : register[r1];
    assign read_instr_2 = (write_en && rd != 5'b0 && rd == r2) ? write_instr : register[r2];
endmodule

module imm_value(opcode, imm_val, instr_in);
    input [6:0] opcode;
    input [31:0] instr_in;
    output reg [31:0] imm_val;
    always @(*) begin
        case(opcode)
            7'b0000011: imm_val = {{20{instr_in[31]}}, instr_in[31:20]};
            7'b0010011: imm_val = {{20{instr_in[31]}}, instr_in[31:20]};
            7'b0100011: imm_val = {{20{instr_in[31]}}, instr_in[31:25], instr_in[11:7]};
            7'b1100011: imm_val = {{19{instr_in[31]}}, instr_in[31], instr_in[7], instr_in[30:25], instr_in[11:8], 1'b0};
            7'b1100111: imm_val = {{20{instr_in[31]}}, instr_in[31:20]};
            7'b1101111: imm_val = {{11{instr_in[31]}}, instr_in[31], instr_in[19:12], instr_in[20], instr_in[30:21], 1'b0};
            7'b0110111: imm_val = {instr_in[31:12], 12'b0};
            7'b0010111: imm_val = {instr_in[31:12], 12'b0};
            default:    imm_val = 32'b0;
        endcase
    end
endmodule

module cntrl_unit(ALUscr, memtoreg, regwrite, memread, memwrite, branch, ALUop, opcode, jump, auipc_sel);
    input [6:0] opcode;
    output reg ALUscr, regwrite, memread, memwrite, branch, auipc_sel;
    output reg [1:0] ALUop, memtoreg, jump;
    always @(*) begin
        case(opcode)
            7'b0110011: {ALUscr,memtoreg,regwrite,memread,memwrite,branch,ALUop,jump,auipc_sel} = 12'b0_00_1_0_0_0_10_00_0;
            7'b0000011: {ALUscr,memtoreg,regwrite,memread,memwrite,branch,ALUop,jump,auipc_sel} = 12'b1_01_1_1_0_0_00_00_0;
            7'b0100011: {ALUscr,memtoreg,regwrite,memread,memwrite,branch,ALUop,jump,auipc_sel} = 12'b1_00_0_0_1_0_00_00_0;
            7'b1100011: {ALUscr,memtoreg,regwrite,memread,memwrite,branch,ALUop,jump,auipc_sel} = 12'b0_00_0_0_0_1_01_00_0;
            7'b0010011: {ALUscr,memtoreg,regwrite,memread,memwrite,branch,ALUop,jump,auipc_sel} = 12'b1_00_1_0_0_0_11_00_0;
            7'b1101111: {ALUscr,memtoreg,regwrite,memread,memwrite,branch,ALUop,jump,auipc_sel} = 12'b0_10_1_0_0_0_00_01_0;
            7'b1100111: {ALUscr,memtoreg,regwrite,memread,memwrite,branch,ALUop,jump,auipc_sel} = 12'b1_10_1_0_0_0_00_10_0;
            7'b0110111: {ALUscr,memtoreg,regwrite,memread,memwrite,branch,ALUop,jump,auipc_sel} = 12'b1_00_1_0_0_0_00_00_0;
            7'b0010111: {ALUscr,memtoreg,regwrite,memread,memwrite,branch,ALUop,jump,auipc_sel} = 12'b1_00_1_0_0_0_00_00_1;
            default:    {ALUscr,memtoreg,regwrite,memread,memwrite,branch,ALUop,jump,auipc_sel} = 12'b0;
        endcase
    end
endmodule

module ALU_op(A, B, ALU_result, ALU_control_in, zero);
    input [31:0] A, B;
    input [3:0] ALU_control_in;
    output reg zero;
    output reg [31:0] ALU_result;
    always @(*) begin
        case(ALU_control_in)
            4'b0000: begin zero=0; ALU_result = A & B; end
            4'b0001: begin zero=0; ALU_result = A | B; end
            4'b0010: begin zero=0; ALU_result = A + B; end
            4'b0110: begin if(A==B) zero=1; else zero=0; ALU_result = A - B; end
            4'b0011: begin zero=0; ALU_result = A ^ B; end
            4'b0100: begin zero=0; ALU_result = A << B[4:0]; end
            4'b0101: begin zero=0; ALU_result = A >> B[4:0]; end
            4'b1000: begin zero=0; ALU_result = A >>> B[4:0]; end
            4'b0111: begin zero=0; ALU_result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; end
            4'b1001: begin if(A!=B) zero=1; else zero=0; ALU_result = A - B; end
            4'b1010: begin
                if($signed(A) < $signed(B)) zero=1; else zero=0;
                ALU_result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; end
            4'b1011: begin
                if($signed(A) >= $signed(B)) zero=1; else zero=0;
                ALU_result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; end
            default: begin zero=0; ALU_result = 32'b0; end
        endcase
    end
endmodule

module ALU_control(fun3, fun7, ALU_op_in, ALU_control_out);
    input [2:0] fun3;
    input fun7;
    input [1:0] ALU_op_in;
    output reg [3:0] ALU_control_out;
    always @(*) begin
        case({ALU_op_in, fun7, fun3})
            6'b00_0_000: ALU_control_out = 4'b0010;
            6'b00_0_010: ALU_control_out = 4'b0010;
            6'b01_0_000: ALU_control_out = 4'b0110;
            6'b10_0_000: ALU_control_out = 4'b0010;
            6'b10_1_000: ALU_control_out = 4'b0110;
            6'b10_0_111: ALU_control_out = 4'b0000;
            6'b10_0_110: ALU_control_out = 4'b0001;
            6'b10_0_100: ALU_control_out = 4'b0011;
            6'b10_0_001: ALU_control_out = 4'b0100;
            6'b10_0_101: ALU_control_out = 4'b0101;
            6'b10_1_101: ALU_control_out = 4'b1000;
            6'b10_0_010: ALU_control_out = 4'b0111;
            6'b11_0_000: ALU_control_out = 4'b0010;
            6'b11_0_111: ALU_control_out = 4'b0000;
            6'b11_0_110: ALU_control_out = 4'b0001;
            6'b11_0_010: ALU_control_out = 4'b0111;
            6'b11_1_101: ALU_control_out = 4'b1000;
            6'b11_0_100: ALU_control_out = 4'b0011;
            6'b11_0_001: ALU_control_out = 4'b0100;
            6'b11_0_101: ALU_control_out = 4'b0101;
            6'b01_0_001: ALU_control_out = 4'b1001;
            6'b01_0_100: ALU_control_out = 4'b1010;
            6'b01_0_101: ALU_control_out = 4'b1011;
            default:     ALU_control_out = 4'b1111;
        endcase
    end
endmodule

module data_memory(write_data, mem_read, mem_write, mem_address, read_data, clk, rst);
    input clk, rst;
    input mem_read, mem_write;
    input [31:0] write_data, mem_address;
    output [31:0] read_data;
    integer i;
    reg [31:0] data_mem [63:0];
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            for(i = 0; i < 64; i = i+1)
                data_mem[i] <= 32'b0;
        end else if(mem_write)
            data_mem[mem_address[7:2]] <= write_data;
    end
    assign read_data = mem_read ? data_mem[mem_address[7:2]] : 32'b0;
endmodule

module muxy1(r2_in, imm_in, mux1, ALU_scr);
    input [31:0] r2_in, imm_in;
    input ALU_scr;
    output [31:0] mux1;
    assign mux1 = ALU_scr ? imm_in : r2_in;
endmodule

module muxy2(rd_in, read_data_out, reg_write_data, memtoreg, pc_jump_in);
    input [31:0] rd_in, read_data_out, pc_jump_in;
    input [1:0] memtoreg;
    output reg [31:0] reg_write_data;
    always @(*) begin
        case(memtoreg)
            2'b00:   reg_write_data = rd_in;
            2'b01:   reg_write_data = read_data_out;
            2'b10:   reg_write_data = pc_jump_in;
            default: reg_write_data = 32'b0;
        endcase
    end
endmodule

module muxy3(imm_plus_pc_in, pc_plus_4_in, alu_in, pc_in, pc_select);
    input [31:0] imm_plus_pc_in, pc_plus_4_in, alu_in;
    input [1:0] pc_select;
    output reg [31:0] pc_in;
    always @(*) begin
        case(pc_select)
            2'b00:   pc_in = pc_plus_4_in;
            2'b01:   pc_in = imm_plus_pc_in;
            2'b10:   pc_in = alu_in;
            default: pc_in = pc_plus_4_in;
        endcase
    end
endmodule

module muxy4(read_data1_in, pc_in, mux4_out, auipc_sel);
    input [31:0] read_data1_in, pc_in;
    input auipc_sel;
    output [31:0] mux4_out;
    assign mux4_out = auipc_sel ? pc_in : read_data1_in;
endmodule

module adder(imm_val, pc_out, imm_plus_pc_out);
    input [31:0] imm_val, pc_out;
    output [31:0] imm_plus_pc_out;
    assign imm_plus_pc_out = imm_val + pc_out;
endmodule

module anding(branch, zero, pc_select, jump);
    input branch, zero;
    input [1:0] jump;
    output [1:0] pc_select;
    assign pc_select[0] = (branch & zero) | jump[0];
    assign pc_select[1] = jump[1];
endmodule

module muxy5(read_data1_mux4, memwb_rd_write, exmem_alu_address, forwardA, alu_input_A);
    input [31:0] read_data1_mux4, memwb_rd_write, exmem_alu_address;
    input [1:0] forwardA;
    output reg [31:0] alu_input_A;
    always @(*) begin
        case(forwardA)
            2'b00:   alu_input_A = read_data1_mux4;
            2'b01:   alu_input_A = memwb_rd_write;
            2'b10:   alu_input_A = exmem_alu_address;
            default: alu_input_A = read_data1_mux4;
        endcase
    end
endmodule

module muxy6(mux1_out, memwb_rd_write, exmem_alu_address, forwardB, alu_input_B);
    input [31:0] mux1_out, memwb_rd_write, exmem_alu_address;
    input [1:0] forwardB;
    output reg [31:0] alu_input_B;
    always @(*) begin
        case(forwardB)
            2'b00:   alu_input_B = mux1_out;
            2'b01:   alu_input_B = memwb_rd_write;
            2'b10:   alu_input_B = exmem_alu_address;
            default: alu_input_B = mux1_out;
        endcase
    end
endmodule

module forwarding_unit(idex_rs1, idex_rs2, exmem_rd, exmem_regwrite, exmem_memread_en,
                       memwb_rd, memwb_regwrite, idex_aluscr_mux, forwardA, forwardB, forwardS);
    input [4:0] idex_rs1, idex_rs2, exmem_rd, memwb_rd;
    input exmem_regwrite, exmem_memread_en, memwb_regwrite, idex_aluscr_mux;
    output reg [1:0] forwardA, forwardB, forwardS;

    wire exmem_fwd_ok = exmem_regwrite && (exmem_rd != 5'b0) && !exmem_memread_en;

    always @(*) begin
        if (exmem_fwd_ok && exmem_rd == idex_rs1)
            forwardA = 2'b10;
        else if (memwb_regwrite && memwb_rd != 5'b0 && memwb_rd == idex_rs1)
            forwardA = 2'b01;
        else
            forwardA = 2'b00;

        if (!idex_aluscr_mux && exmem_fwd_ok && exmem_rd == idex_rs2)
            forwardB = 2'b10;
        else if (!idex_aluscr_mux && memwb_regwrite && memwb_rd != 5'b0 && memwb_rd == idex_rs2)
            forwardB = 2'b01;
        else
            forwardB = 2'b00;

        if (exmem_fwd_ok && exmem_rd == idex_rs2)
            forwardS = 2'b10;
        else if (memwb_regwrite && memwb_rd != 5'b0 && memwb_rd == idex_rs2)
            forwardS = 2'b01;
        else
            forwardS = 2'b00;
    end
endmodule

module hazard_detection_unit(idex_memread_en, idex_rd, id_rs1, id_rs2, stall);
    input idex_memread_en;
    input [4:0] idex_rd, id_rs1, id_rs2;
    output reg stall;
    always @(*) begin
        if (idex_memread_en && idex_rd != 5'b0 &&
            (idex_rd == id_rs1 || idex_rd == id_rs2))
            stall = 1'b1;
        else
            stall = 1'b0;
    end
endmodule
