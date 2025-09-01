`include "general_defines.svh"

// split a matrix from a blockram as each row/col put in separate bram
module matrix_split #( parameter STYLE = "ROW", parameter int CNT = 64, parameter int BIT = $clog2(CNT) )
(
   input  wire                  clk         ,
   input  wire                  start_in    ,
   input  wire          [BIT:0] row_cnt_in  ,
   input  wire          [BIT:0] col_cnt_in  ,
   output logic          [11:0] addrb_out   ,
   input  wire           [15:0] doutb_in    ,

   output logic                 rdy_out     ,
   input  wire            [5:0] addrb_in    ,
   output logic [CNT-1:0][15:0] doutb_out 
);
//--------------------------------------------------------------------------------------------------
// Signals
//--------------------------------------------------------------------------------------------------

   enum logic [1:0] {IDLE, WAIT_LATENCY, GET_DATA, UPDATE_BLOCK} state_next, state_reg = IDLE;
   
   logic            start_reg ;     
   logic  [CNT-1:0] wr_en_next     , wr_en_reg     ;     
   logic     [15:0] dina_next      , dina_reg      ;
   logic  [BIT-1:0] addra_next     , addra_reg     ;
   logic  [BIT-1:0] wr_addr_next   , wr_addr_reg   ;
   logic  [BIT-1:0] ram_id_next    , ram_id_reg    ;
   logic     [11:0] addrb_next     , addrb_reg     ;
   logic     [11:0] start_addr_next, start_addr_reg;
   logic  [BIT-1:0] data_cnt_next  , data_cnt_reg  ;
   logic  [BIT-1:0] block_cnt_next , block_cnt_reg ;
   
//--------------------------------------------------------------------------------------------------
// Begin
//--------------------------------------------------------------------------------------------------

   always_comb begin : split_into_brams
      wr_en_next      = '0;
      dina_next       = doutb_in      ;
      addra_next      = wr_addr_reg   ;
      ram_id_next     = ram_id_reg    ;
      addrb_next      = addrb_reg     ;
      start_addr_next = start_addr_reg;
      wr_addr_next    = wr_addr_reg   ;
      data_cnt_next   = data_cnt_reg  ;
      block_cnt_next  = block_cnt_reg ;
      state_next      = state_reg     ;
      
      case (state_reg)
         IDLE: begin
            ram_id_next     = '0;
            addrb_next      = '0;
            start_addr_next =(STYLE == "ROW") ? col_cnt_in : 'd1;
            wr_addr_next    = '0;
            data_cnt_next   = '0;
            block_cnt_next  = '0;
            state_next      =(start_in & ~start_reg) ?  WAIT_LATENCY : state_reg;
         end
         WAIT_LATENCY : begin
            addrb_next      =(STYLE == "ROW") ? (addrb_reg + 'd1) : (addrb_reg + col_cnt_in);
            state_next      = GET_DATA;
         end
         GET_DATA : begin
            addrb_next      =(STYLE == "ROW") ? (addrb_reg + 'd1) : (addrb_reg + col_cnt_in);
            data_cnt_next   = data_cnt_reg + 'd1;
            state_next      =(((STYLE == "ROW") & (data_cnt_reg >= col_cnt_in-1)) | ((STYLE != "ROW") & (data_cnt_reg >= row_cnt_in-1))) ? UPDATE_BLOCK : state_reg;
            wr_addr_next    = wr_addr_reg + 'd1;
            wr_en_next [ram_id_reg] = '1;
         end   
         UPDATE_BLOCK : begin
            ram_id_next     = ram_id_reg + 'd1;
            addrb_next      = start_addr_reg;
            start_addr_next =(STYLE == "ROW") ? (start_addr_reg + col_cnt_in) : (start_addr_reg + 'd1);
            wr_addr_next    = '0;
            data_cnt_next   = '0;
            block_cnt_next  = block_cnt_reg + 'd1;
            state_next      =(((STYLE == "ROW") & (block_cnt_reg >= row_cnt_in-1)) | ((STYLE != "ROW") & (block_cnt_reg >= col_cnt_in-1))) ? IDLE : WAIT_LATENCY;
         end
         default : begin
            state_next = IDLE;
         end
      endcase
   end   

   assign addrb_out = addrb_reg;
   assign rdy_out   = (state_reg == IDLE);
   
   always_ff @(posedge clk) begin : reg_signals
      start_reg      <= start_in       ;     
      wr_en_reg      <= wr_en_next     ;     
      dina_reg       <= dina_next      ;
      addra_reg      <= addra_next     ;
      ram_id_reg     <= ram_id_next    ;
      addrb_reg      <= addrb_next     ;
      start_addr_reg <= start_addr_next;
      wr_addr_reg    <= wr_addr_next   ;
      data_cnt_reg   <= data_cnt_next  ;
      block_cnt_reg  <= block_cnt_next ;
      state_reg      <= state_next     ;
   end
   
   generate
   for (genvar i=0; i<CNT; i++) begin : gen_sdpram
      SDPRAM #(
         .CLOCKING_MODE      ( "common_clock" ),
         .WRITE_DATA_WIDTH_A ( 16   ),
         .ADDR_WIDTH_A       ( 6    ),
         .MEMORY_DEPTH       ( 64   ),
         .READ_DATA_WIDTH_B  ( 16   ),
         .ADDR_WIDTH_B       ( 6    )
      )
      inst_SDPRAM
      (
         .clka  ( clk           ),
         .wea   ( wr_en_reg [i] ),
         .addra ( addra_reg     ),
         .dina  ( dina_reg      ),
 
         .clkb  ( clk           ),
         .addrb ( addrb_in      ),
         .doutb ( doutb_out [i] )
      );      
   end
   endgenerate
   
endmodule