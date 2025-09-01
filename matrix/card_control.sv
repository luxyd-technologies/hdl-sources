`include "general_defines.svh"

// control card operation sequentially
module card_control #( parameter int CNT = 64, parameter int BIT = $clog2(CNT) )
(
   input  wire        clk             ,
   input  wire        resetn          ,
   input  wire        host_start_in   ,
   input  wire  [1:0] split_rdy_in    ,
   input  wire        mult_rdy_in     ,
   input  wire        unite_rdy_in    ,
                      
   output logic       rdy_out         ,
   output logic       split_start_out ,
   output logic       mult_start_out  ,
   output logic       unite_start_out 
);
//--------------------------------------------------------------------------------------------------
// Signals
//--------------------------------------------------------------------------------------------------
   enum logic [2:0] {IDLE, 
                     RUN_SPLIT, WAIT_SPLIT,
                     RUN_MULT, WAIT_MULT,
                     RUN_UNITE, WAIT_UNITE} state_next, state_reg = IDLE;
                     
   logic [15:0]  wait_cnt_next   , wait_cnt_reg    ;
   logic         host_start_reg  ;
   logic         split_start_next, split_start_reg ;
   logic         mult_start_next , mult_start_reg  ;
   logic         unite_start_next, unite_start_reg ;
   
//--------------------------------------------------------------------------------------------------
// Begin
//--------------------------------------------------------------------------------------------------
   always_comb begin : control_operation
      wait_cnt_next    = wait_cnt_reg + 'd1;
      split_start_next = '0;
      mult_start_next  = '0;
      unite_start_next = '0;
      state_next       = state_reg;
      
      case (state_reg) 
         IDLE : begin
            state_next =(host_start_in & ~host_start_reg) ? RUN_SPLIT : state_reg;
         end         
         RUN_SPLIT : begin
            split_start_next = '1;
            wait_cnt_next    = '0;
            state_next       = WAIT_SPLIT;
         end
         WAIT_SPLIT : begin
            wait_cnt_next = wait_cnt_reg + 'd1;
            state_next    =((&split_rdy_in & ~split_start_reg) | wait_cnt_reg[15]) ? RUN_MULT : state_reg;
         end
         RUN_MULT : begin
            mult_start_next = '1;
            wait_cnt_next   = '0;
            state_next      = WAIT_MULT;            
         end
         WAIT_MULT : begin
            wait_cnt_next = wait_cnt_reg + 'd1;
            state_next    =(mult_rdy_in & ~mult_start_reg) ? RUN_UNITE : state_reg;
         end
         RUN_UNITE : begin
            unite_start_next = '1;
            wait_cnt_next    = '0;
            state_next       = WAIT_UNITE;
         end
         WAIT_UNITE : begin
            wait_cnt_next = wait_cnt_reg + 'd1;
            state_next    =((unite_rdy_in & ~unite_start_reg) | wait_cnt_reg[15]) ? IDLE : state_reg;
         end       
         default  : begin
            state_next = IDLE;
         end
      endcase
   end
   
   always_ff @(posedge clk) begin : reg_signals
      if (~resetn) begin
         wait_cnt_reg    <= '0;
         host_start_reg  <= '0;
         split_start_reg <= '0;
         mult_start_reg  <= '0;
         unite_start_reg <= '0;
         state_reg       <= IDLE;      
      end else begin
         wait_cnt_reg    <= wait_cnt_next   ;
         host_start_reg  <= host_start_in   ;
         split_start_reg <= split_start_next;
         mult_start_reg  <= mult_start_next ;
         unite_start_reg <= unite_start_next;
         state_reg       <= state_next      ;
      end
   end

   assign rdy_out         =(state_reg == IDLE);
   assign split_start_out = split_start_reg   ;
   assign mult_start_out  = mult_start_reg    ;
   assign unite_start_out = unite_start_reg   ;
   
endmodule