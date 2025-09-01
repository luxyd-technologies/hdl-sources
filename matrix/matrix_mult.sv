`include "general_defines.svh"

// do a * b = c, (a_col_in == b_row_in)
module matrix_mult #( parameter int CNT = 64, parameter int BIT = $clog2(CNT) )
(
   input  wire                      clk         ,
   input  wire                      start_in    ,
   input  wire              [BIT:0] a_row_in    ,
   input  wire              [BIT:0] a_col_in    ,
   input  wire              [BIT:0] b_row_in    ,
   input  wire              [BIT:0] b_col_in    ,
   input  wire   [CNT-1:0]   [15:0] a_doutb_in  ,
   input  wire   [CNT-1:0]   [15:0] b_doutb_in  ,
   output logic           [BIT-1:0] a_addrb_out ,
   output logic           [BIT-1:0] b_addrb_out ,
   
   output logic                     rdy_out     ,
   input  wire            [BIT-1:0] addrb_in    ,
   output logic  [CNT-1:0]   [31:0] doutb_out 
);
//--------------------------------------------------------------------------------------------------
// Signals
//--------------------------------------------------------------------------------------------------
   localparam CNT_CHUNK = 8;
   localparam BIT_CHUNK = $clog2(CNT_CHUNK);

   enum logic [2:0] {IDLE, 
                     WAIT_LATENCY, 
                     MULT_CHUNK, 
                     WAIT_ACCUMULATE, 
                     CHECK_END} state_next, state_reg, state_reg_d1, state_reg_d2, state_reg_d3;

   logic               start_reg;
   logic        [15:0] mult_a_int  [CNT_CHUNK-1:0];
   logic        [15:0] mult_b_int  [CNT-1:0];
   logic        [31:0] prod_ab     [CNT_CHUNK-1:0][CNT-1:0];
   logic        [37:0] mac_next    [CNT_CHUNK-1:0][CNT-1:0]; 
   logic        [37:0] mac_reg     [CNT_CHUNK-1:0][CNT-1:0]; 
   logic [BIT_CHUNK:0] num_chunk_next, num_chunk_reg;
   logic [BIT_CHUNK:0] cnt_mult_next , cnt_mult_reg ;
   logic [BIT_CHUNK:0] cnt_chunk_next, cnt_chunk_reg;
   logic [BIT_CHUNK:0] cnt_wait_next , cnt_wait_reg ;
   logic [BIT_CHUNK:0] cnt_res_next  , cnt_res_reg  ;
   logic     [BIT-1:0] addrb_next    , addrb_reg    ;  
   logic     [BIT-1:0] wr_addr_next  , wr_addr_reg  ;
   logic     [BIT-1:0] addra_next    , addra_reg    ;
   logic     [CNT-1:0] wr_en_next    , wr_en_reg    ;
   logic        [31:0] dina_next [CNT-1:0];
   logic        [31:0] dina_reg  [CNT-1:0];
//--------------------------------------------------------------------------------------------------
// Begin
//--------------------------------------------------------------------------------------------------
   generate
   for (genvar i=0; i<CNT_CHUNK; i++) begin : geni_MULT
      for (genvar j=0; j<CNT; j++) begin : genj_MULT
         //MULT_MACRO #(
         //   .DEVICE  ( "7SERIES" ), 
         //   .LATENCY ( 3         ), 
         //   .WIDTH_A ( 16        ), 
         //   .WIDTH_B ( 16        )  
         //) 
         //inst_MULT
         //(
         //   .P    ( prod_ab   [i][j] ), 
         //   .A    ( mult_a_int[i]    ), // a(i,0)
         //   .B    ( mult_b_int[j]    ), // b(0,j)
         //   .CE   ( '1               ), 
         //   .CLK  ( clk              ), 
         //   .RST  ( '0               )  
         //); 
         mult_gen_0 
         inst_MULT
         (
           .CLK   ( clk              ),  // input wire CLK
           .A     ( mult_a_int[i]    ),  // input wire [15 : 0] A
           .B     ( mult_b_int[j]    ),  // input wire [15 : 0] B
           .P     ( prod_ab   [i][j] )   // output wire [31 : 0] P
         );         
      end
   end
   endgenerate
   
   always_comb begin : map_mult_input   
      num_chunk_next = a_row_in[BIT:3] + 1'(|a_row_in[2:0]);
      for (int i=0; i<CNT_CHUNK; i++) begin
         mult_a_int[i] = (cnt_chunk_reg == 0) ? a_doutb_in[i+0  ] :
                         (cnt_chunk_reg == 1) ? a_doutb_in[i+1*8] :
                         (cnt_chunk_reg == 2) ? a_doutb_in[i+2*8] :
                         (cnt_chunk_reg == 3) ? a_doutb_in[i+3*8] :
                         (cnt_chunk_reg == 4) ? a_doutb_in[i+4*8] :
                         (cnt_chunk_reg == 5) ? a_doutb_in[i+5*8] :
                         (cnt_chunk_reg == 6) ? a_doutb_in[i+6*8] : a_doutb_in[i+7*8];
      end
      for (int j=0; j<CNT; j++) begin
         mult_b_int[j] = b_doutb_in[j];
      end
   end
   
   // consider multple chunks
   always_comb begin : give_multiply
      cnt_mult_next  = cnt_mult_reg;
      cnt_chunk_next = cnt_chunk_reg;
      cnt_wait_next  = cnt_wait_reg;
      addrb_next     = addrb_reg;   
      state_next     = state_reg;   
   
      case (state_reg)
         IDLE : begin
            cnt_chunk_next = '0;
            addrb_next     = '0;
            state_next     =(start_in & ~start_reg) ? WAIT_LATENCY : state_reg;
         end
         WAIT_LATENCY : begin
            cnt_mult_next  = '0;
            cnt_wait_next  = '0;
            addrb_next     = addrb_reg + 'd1;
            state_next     = MULT_CHUNK;
         end
         MULT_CHUNK : begin
            addrb_next     = addrb_reg + 'd1;
            cnt_mult_next  = cnt_mult_reg + 'd1;
            state_next     =(cnt_mult_reg >= a_col_in-1) ? WAIT_ACCUMULATE : state_reg;
         end
         WAIT_ACCUMULATE : begin
            cnt_wait_next  = cnt_wait_reg + 'd1;
            state_next     =(cnt_wait_reg >= CNT_CHUNK-1) ? CHECK_END : state_reg;
         end
         CHECK_END : begin
            addrb_next     = '0;
            cnt_chunk_next = cnt_chunk_reg + 'd1;
            state_next     =(cnt_chunk_reg >= num_chunk_reg-1) ? IDLE : WAIT_LATENCY;
         end

         default : begin
            state_next = IDLE;
         end
      endcase
   end
   
   // consider multplier latency   
   always_comb begin : get_multiply
      mac_next = mac_reg;
      
      case (1'b1)
         (state_reg_d3 == WAIT_LATENCY) : begin
            mac_next = '{default:'0};
         end
         (state_reg_d3 == MULT_CHUNK) : begin
            for (int i=0; i<CNT_CHUNK; i++) begin 
               for (int j=0; j<CNT; j++) begin 
                  mac_next[i][j] = mac_reg[i][j] + prod_ab[i][j];
               end
            end
         end
      endcase
   end
      
   // write result into separate ram and do truncation/saturation 
   always_comb begin : collect_multiply
      wr_en_next   = '0;
      wr_addr_next = wr_addr_reg;
      addra_next   = wr_addr_reg;
      cnt_res_next = cnt_res_reg;
      for (int j=0;j<CNT; j++) begin
         dina_next [j] = mac_reg[cnt_res_reg][j];
      end
      
      case (1'b1)
         (state_reg_d3 == IDLE) : begin
            wr_addr_next = '0;
            cnt_res_next = '1;
         end
         (cnt_res_reg < CNT_CHUNK) : begin
            wr_en_next   = '1;
            wr_addr_next = wr_addr_reg + 'd1;
            cnt_res_next = cnt_res_reg + 'd1;
         end
         (state_reg_d3 == WAIT_ACCUMULATE) : begin
            cnt_res_next = '0;
         end
      endcase
   end

   always_ff @(posedge clk) begin : reg_signals
      start_reg     <= start_in;
      num_chunk_reg <= num_chunk_next;
      cnt_mult_reg  <= cnt_mult_next ;
      cnt_chunk_reg <= cnt_chunk_next;
      cnt_wait_reg  <= cnt_wait_next ;
      addrb_reg     <= addrb_next    ;  
      mac_reg       <= mac_next      ;
      wr_en_reg     <= wr_en_next    ;
      wr_addr_reg   <= wr_addr_next  ;
      addra_reg     <= addra_next    ;
      cnt_res_reg   <= cnt_res_next  ;
      dina_reg      <= dina_next     ;
      state_reg     <= state_next    ;   
      state_reg_d1  <= state_reg     ;   
      state_reg_d2  <= state_reg_d1  ;   
      state_reg_d3  <= state_reg_d2  ;   
   end
   
   assign rdy_out     =(state_reg == IDLE) & (state_reg_d3 == IDLE);
   assign a_addrb_out = addrb_reg;
   assign b_addrb_out = addrb_reg;
   
   generate
   for (genvar i=0; i<CNT; i++) begin : gen_sdpram
      SDPRAM #(
         .CLOCKING_MODE      ( "common_clock" ),
         .WRITE_DATA_WIDTH_A ( 32   ),
         .ADDR_WIDTH_A       ( 6    ),
         .MEMORY_DEPTH       ( 64   ),
         .READ_DATA_WIDTH_B  ( 32   ),
         .ADDR_WIDTH_B       ( 6    )
      )
      inst_SDPRAM
      (
         .clka  ( clk           ),
         .wea   ( wr_en_reg [i] ),
         .addra ( addra_reg     ),
         .dina  ( dina_reg  [i] ),
 
         .clkb  ( clk           ),
         .addrb ( addrb_in      ),
         .doutb ( doutb_out [i] )
      );      
   end
   endgenerate      
   
endmodule