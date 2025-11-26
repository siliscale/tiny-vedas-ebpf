`timescale 1ns / 1ps

`ifndef GLOBAL_SVH
`include "global.svh"
`endif

module core_top_tb;

  localparam string ICCM_INIT_FILE = `ICCM_INIT_FILE;
  localparam string DCCM_INIT_FILE = `DCCM_INIT_FILE;
  localparam logic [XLEN-1:0] STACK_POINTER_INIT_VALUE = `STACK_POINTER_INIT_VALUE;

  logic            clk = 0;
  logic            rstn;
  logic [XLEN-1:0] reset_vector = `RESET_VECTOR;

  logic [    31:0] cycle_count = 0;

  int              fd;
  int              fd_console;
  /* DUT Instantiation */
  core_top #(
      .ICCM_INIT_FILE          (ICCM_INIT_FILE),
      .DCCM_INIT_FILE          (DCCM_INIT_FILE),
      .STACK_POINTER_INIT_VALUE(STACK_POINTER_INIT_VALUE)
  ) core_top_i (
      .*
  );

  always #5 clk = ~clk;  // 100 MHz clock

  initial begin
    /* Create a log file in the current directory */
    $timeformat(-9, 3, " ns", 10);
    fd = $fopen("rtl.log", "w");
    fd_console = $fopen("console.log", "w");
    rstn = 0;
    for (int i = 0; i < 10; i++) begin
      @(negedge clk);
    end
    rstn = 1;
  end

  /* Finish Sequence Detector */
  logic [99:0] finish_seq_detected = 0;
  always_ff @(posedge clk) begin
    finish_seq_detected[0] <= 0;
    if (core_top_i.instr_mem_rdata[7:0] == 8'h95 && core_top_i.instr_mem_rdata_valid) begin
      finish_seq_detected[0] <= 1;
    end
    for (int i = 0; i < 99; i++) finish_seq_detected[i+1] <= finish_seq_detected[i];
  end

  /* Console output */
  //always_ff @(posedge clk) begin
  //  if (core_top_i.dccm_wen & core_top_i.dccm_waddr == 32'h00200000) begin
  //    $fwrite(fd_console, "%c", core_top_i.dccm_wdata[7:0]);
  //  end
  //end


  logic [31:0] cycle_count_last_retired;
  always_ff @(posedge clk) begin
    if (finish_seq_detected[99]) begin
      $finish;
    end
    if (cycle_count_last_retired > 1000) begin
      $fdisplay(fd, "Nothing retired in 1000 cycles... Aborting");
      $finish;
    end
  end

  /* Cycle counter */
  always_ff @(posedge clk) begin
    if (rstn) begin
      cycle_count <= cycle_count + 1;
      cycle_count_last_retired <= cycle_count + 1;
    end
    //if (core_top_i.exu_wb_rd_wr_en | (core_top_i.exu_inst.lsu_inst.dc2_legal & core_top_i.exu_inst.lsu_inst.dc2_store) | (core_top_i.exu_inst.lsu_inst.dc3_legal & core_top_i.exu_inst.lsu_inst.dc3_store)) begin
    if (core_top_i.exu_wb_rd_wr_en) begin
      cycle_count_last_retired <= 'b0;
    end
  end

  /* Use the monitor to log the log file */
  always_ff @(posedge clk) begin
    /* Log everytime we touch the state of our core: Write to the register file, change the PC and store to memory */
    if (core_top_i.exu_wb_rd_wr_en & ~core_top_i.ifu_inst.pc_load) begin  /* Hierarchical naming */
      $fdisplay(fd, "%5d;0x%H;0x%H;r%0D=0x%H", cycle_count, core_top_i.exu_instr_tag_out,
                core_top_i.exu_instr_out, core_top_i.exu_wb_rd_addr, core_top_i.exu_wb_data);
    end

    if (core_top_i.exu_inst.exit & !(core_top_i.pipe_stall)) begin  /* exit */
      $fdisplay(fd, "%5d;0x%H;0x%H;exit", cycle_count, core_top_i.exu_inst.exit_instr_tag_out,
                core_top_i.exu_inst.exit_instr_out);
    end

    if (core_top_i.exu_wb_rd_wr_en & core_top_i.ifu_inst.pc_load) begin  /* JAL/JALR */
      $fdisplay(fd, "%5d;0x%H;0x%H;x%0D=0x%H;pc=0x%H", cycle_count, core_top_i.exu_instr_tag_out,
                core_top_i.exu_instr_out, core_top_i.exu_wb_rd_addr, core_top_i.exu_wb_data,
                core_top_i.ifu_inst.pc_exu);
    end

    if (~core_top_i.exu_inst.alu_wb_rd_wr_en & core_top_i.ifu_inst.pc_load) begin  /* BEQ/BNE/BGE/BLT/BLTU/BGEU taken */
      $fdisplay(fd, "%5d;0x%H;0x%H;taken=true;pc=0x%H", cycle_count,
                core_top_i.exu_inst.alu_instr_tag_out, core_top_i.exu_inst.alu_instr_out,
                core_top_i.ifu_inst.pc_exu);
    end

    if (core_top_i.exu_inst.alu_inst.alu_ctrl.condbr & ~core_top_i.exu_inst.alu_inst.brn_taken & core_top_i.exu_inst.alu_inst.alu_ctrl.legal) begin  /* BEQ/BNE/BGE/BLT/BLTU/BGEU not taken */
      $fdisplay(fd, "%5d;0x%H;0x%H;taken=false", cycle_count,
                core_top_i.exu_inst.alu_inst.alu_ctrl.instr_tag,
                core_top_i.exu_inst.alu_inst.alu_ctrl.instr);
    end

    //if (core_top_i.exu_inst.lsu_inst.dc2_legal & core_top_i.exu_inst.lsu_inst.dc2_store) begin
    //  $fdisplay(
    //      fd, "%5d;0x%H;0x%H;mem[0x%8H]=0x%H", cycle_count,
    //      core_top_i.exu_inst.lsu_inst.dc2_lsu_instr_tag_out,
    //      core_top_i.exu_inst.lsu_inst.dc2_lsu_instr_out,
    //      core_top_i.exu_inst.lsu_inst.dc2_computed_addr,
    //      core_top_i.exu_inst.lsu_inst.dc2_store_buffer[XLEN-1:0] & core_top_i.exu_inst.lsu_inst.dc2_store_mask_base[XLEN-1:0]);
    //end

    //if (core_top_i.exu_inst.lsu_inst.dc3_legal & core_top_i.exu_inst.lsu_inst.dc3_store & core_top_i.exu_inst.lsu_inst.dc3_unaligned_addr) begin
    //  $fdisplay(
    //      fd, "%5d;0x%H;0x%H;mem[0x%8H]=0x%H", cycle_count,
    //      core_top_i.exu_inst.lsu_inst.dc3_lsu_instr_tag_out,
    //      core_top_i.exu_inst.lsu_inst.dc3_lsu_instr_out,
    //      core_top_i.exu_inst.lsu_inst.dc3_computed_addr,
    //      core_top_i.exu_inst.lsu_inst.dc3_store_buffer[XLEN-1:0] & core_top_i.exu_inst.lsu_inst.dc3_wb_data_mask[XLEN-1:0]);
    //end
  end


endmodule
