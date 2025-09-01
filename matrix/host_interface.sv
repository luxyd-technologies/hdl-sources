`include "general_defines.svh"

module host_interface
(
   input  wire              clk              ,
   input  wire              resetn           ,
   input  wire              host_wren_in     ,
   input  wire              host_rden_in     ,
   input  wire       [31:0] host_addr_wr_in  ,
   input  wire       [31:0] host_addr_rd_in  ,
   input  wire       [31:0] host_data_wr_in  ,
   output logic      [31:0] host_data_rd_out ,
   
   output logic             start_out    ,
   input  wire              rdy_in       ,
   output logic  [1:0][7:0] row_cnt_out  ,
   output logic  [1:0][7:0] col_cnt_out  
);
//--------------------------------------------------------------------------------------------------
// Signals
//--------------------------------------------------------------------------------------------------   
   localparam COMMAND_REG_ADDR = 32'h000C_0000 ;
   localparam INFO_REG_ADDR    = 32'h000C_0004 ;
   localparam STATUS_REG_ADDR  = 32'h000C_0008 ;
   
   localparam HOST_SIGNATURE   = 8'hAC;
   localparam FPGA_SIGNATURE   = 8'hFC;
   
   logic [31:0] command_reg;
   logic [31:0] info_reg   ;
   logic [31:0] status_reg ;
   
   logic [31:0] host_data_rd_next, host_data_rd_reg;

//--------------------------------------------------------------------------------------------------
// Begin
//--------------------------------------------------------------------------------------------------  
   always_comb begin
      host_data_rd_next = host_data_rd_reg;
      if (host_rden_in) begin
         host_data_rd_next =(host_addr_rd_in == COMMAND_REG_ADDR) ? command_reg :
                            (host_addr_rd_in == INFO_REG_ADDR   ) ? info_reg    : 
                            (host_addr_rd_in == STATUS_REG_ADDR ) ? status_reg  : 32'b0;
      end
   end   

   always_ff @(posedge clk) begin : reg_signals
      if (~resetn) begin
         host_data_rd_reg <= '0;
      end else begin
         host_data_rd_reg <= host_data_rd_next;
      end
   end
         
         
   always_ff @(posedge clk) begin : reg_update
      if (~resetn) begin
         command_reg  <= '0;
         info_reg     <= '0;
      end else if (host_wren_in) begin
         command_reg  <=(host_addr_wr_in == COMMAND_REG_ADDR) ? host_data_wr_in : command_reg;
         info_reg     <=(host_addr_wr_in == INFO_REG_ADDR   ) ? host_data_wr_in : info_reg   ;
      end
   end
   
   
   assign host_data_rd_out = host_data_rd_next;

   assign start_out      = command_reg[8] & (command_reg[7:0] == HOST_SIGNATURE);
   assign row_cnt_out[0] = info_reg[ 7: 0];
   assign col_cnt_out[0] = info_reg[15: 8];
   assign row_cnt_out[1] = info_reg[23:16];
   assign col_cnt_out[1] = info_reg[31:24];
   
   assign status_reg [7:0]  = FPGA_SIGNATURE;
   assign status_reg [8]    = rdy_in;
   assign status_reg [31:9] = '0;
   
endmodule