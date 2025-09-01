`include "general_defines.svh"

module matrix_unite #( parameter STYLE = "ROW", parameter int CNT = 64, parameter int BIT = $clog2(CNT) )
(
   input  wire                     clk         ,
   input  wire                     start_in    ,
   input  wire             [BIT:0] row_cnt_in  ,
   input  wire             [BIT:0] col_cnt_in  ,
   output logic          [BIT-1:0] addrb_out   ,
   input  wire     [CNT-1:0][31:0] doutb_in    ,

   output logic                    rdy_out     ,
   output logic                    wr_en_out   ,
   output logic            [11:0]  addr_out    ,
   output logic            [31:0]  din_out    
);
//--------------------------------------------------------------------------------------------------
// Signals
//--------------------------------------------------------------------------------------------------
   enum logic [1:0] {IDLE, WAIT_LATENCY, GET_DATA, UPDATE_BLOCK} state_next, state_reg = IDLE;
   
   logic            start_reg ;     
   logic            wr_en_next     , wr_en_reg     ;     
   logic     [31:0] dina_next      , dina_reg      ;
   logic     [11:0] addra_next     , addra_reg     ;
   logic     [11:0] wr_addr_next   , wr_addr_reg   ;
   logic  [BIT-1:0] ram_id_next    , ram_id_reg    ;
   logic  [BIT-1:0] addrb_next     , addrb_reg     ;
   logic      [5:0] data_cnt_next  , data_cnt_reg  ;
   logic  [BIT-1:0] block_cnt_next , block_cnt_reg ;

//--------------------------------------------------------------------------------------------------
// Begin
//--------------------------------------------------------------------------------------------------
   always_comb begin : unite_brams
      wr_en_next      = '0;
      dina_next       = doutb_in[ram_id_reg];
      addra_next      = wr_addr_reg   ;
      ram_id_next     = ram_id_reg    ;
      addrb_next      = addrb_reg     ;
      wr_addr_next    = wr_addr_reg   ;
      data_cnt_next   = data_cnt_reg  ;
      block_cnt_next  = block_cnt_reg ;
      state_next      = state_reg     ;
      
      case (state_reg)
         IDLE: begin
            wr_addr_next   = '0;
            addrb_next     = '0;
            block_cnt_next = '0;
            ram_id_next    = '0;
            state_next     =(start_in & ~start_reg) ?  WAIT_LATENCY : state_reg;
         end
         WAIT_LATENCY : begin
            addrb_next    = (STYLE == "ROW") ? (addrb_reg + 'd1) : addrb_reg;
            data_cnt_next = '0;
            state_next    = GET_DATA;
         end
         GET_DATA : begin
            addrb_next    = (STYLE == "ROW") ? (addrb_reg + 'd1) : addrb_reg;
            ram_id_next   = (STYLE == "ROW") ? ram_id_reg        : (ram_id_reg + 'd1);
            data_cnt_next = data_cnt_reg + 'd1;
            state_next    =(((STYLE == "ROW") & (data_cnt_reg >= row_cnt_in-1)) | ((STYLE != "ROW") & (data_cnt_reg >= col_cnt_in-1))) ? UPDATE_BLOCK : state_reg;
            wr_addr_next  = wr_addr_reg + 'd1;
            wr_en_next    = '1;            
         end   
         UPDATE_BLOCK : begin
            addrb_next     = (STYLE == "ROW") ? '0                 : (addrb_reg + 'd1);
            ram_id_next    = (STYLE == "ROW") ? (ram_id_reg + 'd1) : '0;
            block_cnt_next = block_cnt_reg + 'd1;
            state_next     =(((STYLE == "ROW") & (block_cnt_reg >= col_cnt_in-1)) | ((STYLE != "ROW") & (block_cnt_reg >= row_cnt_in-1))) ? IDLE : WAIT_LATENCY;
         end
         default : begin
            state_next = IDLE;
         end
      endcase
   end          

   
   always_ff @(posedge clk) begin : reg_signals
      start_reg      <= start_in       ;     
      wr_en_reg      <= wr_en_next     ;     
      dina_reg       <= dina_next      ;
      addra_reg      <= addra_next     ;
      ram_id_reg     <= ram_id_next    ;
      addrb_reg      <= addrb_next     ;
      wr_addr_reg    <= wr_addr_next   ;
      data_cnt_reg   <= data_cnt_next  ;
      block_cnt_reg  <= block_cnt_next ;
      state_reg      <= state_next     ;
   end
   
   assign addrb_out = addrb_reg;
   assign rdy_out   =(state_reg == IDLE);
   assign wr_en_out = wr_en_reg;
   assign addr_out  = addra_reg;
   assign din_out   = dina_reg;

endmodule