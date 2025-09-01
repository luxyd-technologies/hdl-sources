`include "general_defines.svh"

// map three matrix to three dualport bram
module matrix_map 
(
   input  wire                bram_clk_in     ,
   input  wire                bram_rst_in     ,
   input  wire                bram_en_in      ,
   input  wire         [15:0] bram_we_in      ,
   input  wire         [63:0] bram_addr_in    ,
   input  wire        [127:0] bram_wrdata_in  ,
   output logic       [127:0] bram_rddata_out ,

   input  wire                clk             ,
   input  wire    [2:2]       web_in          ,
   input  wire    [2:0][11:0] addrb_in        ,
   input  wire    [2:2][31:0] dinb_in         ,
   output logic   [1:0][15:0] doutb_out 
);
//--------------------------------------------------------------------------------------------------
// Signals
//--------------------------------------------------------------------------------------------------
   logic              bram_we_int;
   logic [2:0]        bram_en_int;
   logic [2:0][127:0] bram_rddata_int;
   
//--------------------------------------------------------------------------------------------------
// Begin
//--------------------------------------------------------------------------------------------------
   // based on address range of bram_addr_in, corresponding ram would be enabled
`ifdef SIMULATION
   assign bram_en_int[0]  = bram_en_in & (~|bram_addr_in[63:16] & (bram_addr_in[15:13] == 3'b000)); // A: 4096*2 byte => bram_addr < 'h2000
   assign bram_en_int[1]  = bram_en_int[0];
   assign bram_en_int[2]  = bram_en_in & (~|bram_addr_in[63:16] & (bram_addr_in[14]    == 1'b1  )); // C: 4096*4 byte => bram_addr < 'h8000
`else   
   assign bram_en_int[0]  = bram_en_in & (~|bram_addr_in[63:16] & (bram_addr_in[15:13] == 3'b000)); // A: 4096*2 byte => bram_addr < 'h2000
   assign bram_en_int[1]  = bram_en_in & (~|bram_addr_in[63:16] & (bram_addr_in[15:13] == 3'b001)); // B: 4096*2 byte => bram_addr < 'h4000
   assign bram_en_int[2]  = bram_en_in & (~|bram_addr_in[63:16] & (bram_addr_in[14]    == 1'b1  )); // C: 4096*4 byte => bram_addr < 'h8000
`endif
   
   assign bram_we_int     = bram_we_in [0];
   assign bram_rddata_out = bram_en_int[0] ? bram_rddata_int[0] : 
                            bram_en_int[1] ? bram_rddata_int[1] : 
                            bram_en_int[2] ? bram_rddata_int[2] : '0;
                            
   // matrix A, B
   generate
   for (genvar i=0; i<=1; i++) begin : gen_TDPRAM
      TDPRAM
      #(
         .CLOCKING_MODE      ( "independent_clock" ),
         .WRITE_DATA_WIDTH_A ( 128                 ),
         .READ_DATA_WIDTH_A  ( 128                 ),
         .ADDR_WIDTH_A       ( 9                   ),
         .WRITE_DATA_WIDTH_B ( 16                  ),
         .READ_DATA_WIDTH_B  ( 16                  ),
         .ADDR_WIDTH_B       ( 12                  )
      ) 
      inst0_TDPRAM
      (
         .clka  ( bram_clk_in           ), // input  wire 
         .rst   ( '0                    ), // input  wire 
         .ena   ( bram_en_int     [i]   ), // input  wire 
         .wea   ( bram_we_int           ), // input  wire 
         .addra ( bram_addr_in    [12:4]), // input  wire        [ADDR_WIDTH_A-1:0]
         .dina  ( bram_wrdata_in        ), // input  wire  [WRITE_DATA_WIDTH_A-1:0]
         .douta ( bram_rddata_int [i]   ), // output wire   [READ_DATA_WIDTH_A-1:0]

         .clkb  ( clk                   ), // input  wire 
         .enb   ( 1'b1                  ), // input  wire 
         .web   ( 1'b0                  ), // input  wire 
         .addrb ( addrb_in        [i]   ), // input  wire        [ADDR_WIDTH_A-1:0]                      
         .dinb  ( '0                    ), // input  wire  [WRITE_DATA_WIDTH_A-1:0]                      
         .doutb ( doutb_out       [i]   )  // output wire   [READ_DATA_WIDTH_A-1:0]      
      ); 
   end
   endgenerate
   
   // matrix C
   TDPRAM
   #(
      .CLOCKING_MODE      ( "independent_clock" ),
      .WRITE_DATA_WIDTH_A ( 128                 ),
      .READ_DATA_WIDTH_A  ( 128                 ),
      .ADDR_WIDTH_A       ( 10                  ),
      .WRITE_DATA_WIDTH_B ( 32                  ),
      .READ_DATA_WIDTH_B  ( 32                  ),
      .ADDR_WIDTH_B       ( 12                  )
   ) 
   inst1_TDPRAM
   (
      .clka  ( bram_clk_in           ), // input  wire 
      .rst   ( '0                    ), // input  wire 
      .ena   ( bram_en_int     [2]   ), // input  wire 
      .wea   ( bram_we_int           ), // input  wire 
      .addra ( bram_addr_in    [13:4]), // input  wire        [ADDR_WIDTH_A-1:0]
      .dina  ( bram_wrdata_in        ), // input  wire  [WRITE_DATA_WIDTH_A-1:0]
      .douta ( bram_rddata_int [2]   ), // output wire   [READ_DATA_WIDTH_A-1:0]

      .clkb  ( clk                   ), // input  wire 
      .enb   ( 1'b1                  ), // input  wire 
      .web   ( web_in          [2]   ), // input  wire 
      .addrb ( addrb_in        [2]   ), // input  wire        [ADDR_WIDTH_B-1:0]
      .dinb  ( dinb_in         [2]   ), // input  wire  [WRITE_DATA_WIDTH_B-1:0]
      .doutb (                       )  // output wire   [READ_DATA_WIDTH_B-1:0]
   ); 
   
endmodule