`include "general_defines.svh"
`include "host_interface_defines.svh"

module accelerator_top
(
   // pcie x4                         
   input  wire          pcie_ref_clkp       ,
   input  wire          pcie_ref_clkn       ,
   input  wire    [3:0] pcie_mgt_rxp        ,
   input  wire    [3:0] pcie_mgt_rxn        ,
   output wire    [3:0] pcie_mgt_txp        ,
   output wire    [3:0] pcie_mgt_txn        ,

`ifdef SIMULATION
   input  wire   [25:0] common_commands_in  ,
   input  wire   [83:0] pipe_rx_0_sigs      ,
   input  wire   [83:0] pipe_rx_1_sigs      ,
   input  wire   [83:0] pipe_rx_2_sigs      ,
   input  wire   [83:0] pipe_rx_3_sigs      ,
   output wire   [25:0] common_commands_out ,
   output wire   [83:0] pipe_tx_0_sigs      ,
   output wire   [83:0] pipe_tx_1_sigs      ,
   output wire   [83:0] pipe_tx_2_sigs      ,
   output wire   [83:0] pipe_tx_3_sigs      ,   
`endif
   
   // general        
   input  wire          user_resetn         ,
   output logic   [7:0] user_led 
);
//--------------------------------------------------------------------------------------------------
// Signals
//--------------------------------------------------------------------------------------------------
   localparam int CNT = 64;
   localparam int BIT = $clog2(CNT);

   logic                    axi_aclk    ; 
   logic                    axi_aresetn ; 
   logic                    user_linkup ; 
   logic                    host_wren   ; 
   logic                    host_rden   ; 
   logic             [31:0] host_addr_wr; 
   logic             [31:0] host_addr_rd; 
   logic             [31:0] host_data_wr; 
   logic             [31:0] host_data_rd; 
   logic                    bram_rst    ; 
   logic                    bram_clk    ; 
   logic                    bram_en     ; 
   logic             [15:0] bram_we     ; 
   logic             [63:0] bram_addr   ; 
   logic            [127:0] bram_wrdata ; 
   logic            [127:0] bram_rddata ; 
              
   logic             [27:0] led_cnt_reg = '0;
   logic                    host_start    ;
   logic                    card_rdy      ;
   logic              [1:0] split_rdy     ;
   logic                    mult_rdy      ;
   logic                    unite_rdy     ;
   logic                    split_start   ;
   logic                    mult_start    ;
   logic                    unite_start   ;
   logic         [1:0][7:0] matrix_row_cnt;
   logic         [1:0][7:0] matrix_col_cnt;
   logic              [2:2] matrix_we     ;
   logic        [2:0][11:0] matrix_addrb  ;
   logic        [2:2][31:0] matrix_dinb   ;
   logic        [1:0][15:0] matrix_doutb  ;
            
   logic              [5:0] array_addrb[1:0] ;
   logic [CNT-1:0]   [15:0] array_dinb [1:0] ; 
   logic          [BIT-1:0] mult_addrb  ;
   logic [CNT-1:0]   [31:0] mult_doutb  ;

//--------------------------------------------------------------------------------------------------
// Begin
//--------------------------------------------------------------------------------------------------

   pcie_interface
   inst_pcie_interface
   (                           
      .PCIE_RST_N          ( user_resetn         ), // input  wire             
      .P_PCIE_REFCLKp      ( pcie_ref_clkp       ), // input  wire             
      .P_PCIE_REFCLKn      ( pcie_ref_clkn       ), // input  wire             
      .P_PCIE_RXp          ( pcie_mgt_rxp        ), // input  wire       [3:0] 
      .P_PCIE_RXn          ( pcie_mgt_rxn        ), // input  wire       [3:0] 
      .P_PCIE_TXp          ( pcie_mgt_txp        ), // output wire       [3:0] 
      .P_PCIE_TXn          ( pcie_mgt_txn        ), // output wire       [3:0] 

   `ifdef SIMULATION
      .common_commands_in  ( common_commands_in  ), // input  wire      [25:0]
      .pipe_rx_0_sigs      ( pipe_rx_0_sigs      ), // input  wire      [83:0]
      .pipe_rx_1_sigs      ( pipe_rx_1_sigs      ), // input  wire      [83:0]
      .pipe_rx_2_sigs      ( pipe_rx_2_sigs      ), // input  wire      [83:0]
      .pipe_rx_3_sigs      ( pipe_rx_3_sigs      ), // input  wire      [83:0]
      .common_commands_out ( common_commands_out ), // output wire      [25:0]
      .pipe_tx_0_sigs      ( pipe_tx_0_sigs      ), // output wire      [83:0]
      .pipe_tx_1_sigs      ( pipe_tx_1_sigs      ), // output wire      [83:0]
      .pipe_tx_2_sigs      ( pipe_tx_2_sigs      ), // output wire      [83:0]
      .pipe_tx_3_sigs      ( pipe_tx_3_sigs      ), // output wire      [83:0]   
   `endif
   
      .axi_aclk            ( axi_aclk            ), // output wire               
      .axi_aresetn         ( axi_aresetn         ), // output wire                
      .user_lnk_up         ( user_linkup         ), // output wire                                     
      .host_wren_out       ( host_wren           ), // output wire             
      .host_rden_out       ( host_rden           ), // output wire             
      .host_addr_wr_out    ( host_addr_wr        ), // output wire      [31:0] 
      .host_addr_rd_out    ( host_addr_rd        ), // output wire      [31:0] 
      .host_data_wr_out    ( host_data_wr        ), // output wire      [31:0] 
      .host_data_rd_in     ( host_data_rd        ), // input  wire      [31:0] 

      .bram_rst_out        ( bram_rst            ), // output wire             
      .bram_clk_out        ( bram_clk            ), // output wire             
      .bram_en_out         ( bram_en             ), // output wire             
      .bram_we_out         ( bram_we             ), // output wire      [15:0] 
      .bram_addr_out       ( bram_addr           ), // output wire      [63:0] 
      .bram_wrdata_out     ( bram_wrdata         ), // output wire     [127:0] 
      .bram_rddata_in      ( bram_rddata         )  // input  wire     [127:0] 
   );                      

   always_ff @(posedge axi_aclk) begin : led_clk
      if (~axi_aresetn) begin
         led_cnt_reg <= '0;
      end else begin
         led_cnt_reg <= led_cnt_reg + 'd1;
      end
   end
   
   assign user_led [0]   = led_cnt_reg[25];
   assign user_led [1]   = user_linkup;
   assign user_led [2]   = card_rdy;
   assign user_led [7:3] = '0;
   
   host_interface
   inst_host_interface
   (
      .clk              ( axi_aclk       ), // input  wire              
      .resetn           ( axi_aresetn    ), // input  wire              
      .host_wren_in     ( host_wren      ), // input  wire              
      .host_rden_in     ( host_rden      ), // input  wire              
      .host_addr_wr_in  ( host_addr_wr   ), // input  wire       [31:0] 
      .host_addr_rd_in  ( host_addr_rd   ), // input  wire       [31:0] 
      .host_data_wr_in  ( host_data_wr   ), // input  wire       [31:0] 
      .host_data_rd_out ( host_data_rd   ), // output logic      [31:0] 
  
      .start_out        ( host_start     ), // output logic             
      .rdy_in           ( card_rdy       ), // input  wire              
      .row_cnt_out      ( matrix_row_cnt ), // output logic  [1:0][7:0] 
      .col_cnt_out      ( matrix_col_cnt )  // output logic  [1:0][7:0] 
   );
   
   matrix_map 
   inst_matrix_map 
   (
      .bram_clk_in     ( bram_clk      ), // input  wire          
      .bram_rst_in     ( bram_rst      ), // input  wire          
      .bram_en_in      ( bram_en       ), // input  wire          
      .bram_we_in      ( bram_we       ), // input  wire   [15:0] 
      .bram_addr_in    ( bram_addr     ), // input  wire   [63:0] 
      .bram_wrdata_in  ( bram_wrdata   ), // input  wire  [127:0] 
      .bram_rddata_out ( bram_rddata   ), // output logic [127:0] 
  
      .clk             ( axi_aclk      ), // input  wire          
      .web_in          ( matrix_we     ), // input  wire    [2:2] 
      .addrb_in        ( matrix_addrb  ), // input  wire    [2:0][11:0] 
      .dinb_in         ( matrix_dinb   ), // input  wire    [2:2][31:0] 
      .doutb_out       ( matrix_doutb  )  // output logic   [1:0][15:0] 
   );
   
   card_control
   inst_card_control
   (
      .clk             ( axi_aclk    ), // input  wire    
      .resetn          ( axi_aresetn ), // input  wire    
      .host_start_in   ( host_start  ), // input  wire    
      .split_rdy_in    ( split_rdy   ), // input  wire [1:0]   
      .mult_rdy_in     ( mult_rdy    ), // input  wire    
      .unite_rdy_in    ( unite_rdy   ), // input  wire    
 
      .rdy_out         ( card_rdy    ), // output logic   
      .split_start_out ( split_start ), // output logic   
      .mult_start_out  ( mult_start  ), // output logic   
      .unite_start_out ( unite_start )  // output logic   
   );
   
   generate
   for (genvar i=0; i<=1; i++) begin : gen_matrix_split
      matrix_split #( .STYLE (( i == 0 ) ? "ROW" : "COL") )
      inst_matrix_split
      (
         .clk         ( axi_aclk           ), // input  wire                  
         .start_in    ( split_start        ), // input  wire                  
         .row_cnt_in  ( matrix_row_cnt [i] ), // input  wire          [BIT:0] 
         .col_cnt_in  ( matrix_col_cnt [i] ), // input  wire          [BIT:0] 
         .addrb_out   ( matrix_addrb   [i] ), // output logic          [11:0] 
         .doutb_in    ( matrix_doutb   [i] ), // input  wire           [15:0] 

         .rdy_out     ( split_rdy      [i] ), // output logic                 
         .addrb_in    ( array_addrb    [i] ), // input  wire            [5:0] 
         .doutb_out   ( array_dinb     [i] )  // output logic [CNT-1:0][15:0] 
      );   
   end
   endgenerate
   
   matrix_mult
   inst_matrix_mult
   (
      .clk         ( axi_aclk           ), // input  wire                      
      .start_in    ( mult_start         ), // input  wire                      
      .a_row_in    ( matrix_row_cnt [0] ), // input  wire              [BIT:0] 
      .b_row_in    ( matrix_row_cnt [1] ), // input  wire              [BIT:0] 
      .a_col_in    ( matrix_col_cnt [0] ), // input  wire              [BIT:0] 
      .b_col_in    ( matrix_col_cnt [1] ), // input  wire              [BIT:0] 
      .a_doutb_in  ( array_dinb     [0] ), // input  wire   [CNT-1:0]   [15:0] 
      .b_doutb_in  ( array_dinb     [1] ), // input  wire   [CNT-1:0]   [15:0] 
      .a_addrb_out ( array_addrb    [0] ), // output logic           [BIT-1:0] 
      .b_addrb_out ( array_addrb    [1] ), // output logic           [BIT-1:0] 
 
      .rdy_out     ( mult_rdy           ), // output logic                     
      .addrb_in    ( mult_addrb         ), // input  wire            [BIT-1:0] 
      .doutb_out   ( mult_doutb         )  // output logic  [CNT-1:0]   [31:0] 
   );   
   
   matrix_unite #( .STYLE ( "COL" ) )
   inst_matrix_unite 
   (
      .clk        ( axi_aclk           ), // input  wire                  
      .start_in   ( unite_start        ), // input  wire                  
      .row_cnt_in ( matrix_row_cnt [0] ), // input  wire          [BIT:0] 
      .col_cnt_in ( matrix_col_cnt [1] ), // input  wire          [BIT:0] 
      .addrb_out  ( mult_addrb         ), // output logic           [5:0] 
      .doutb_in   ( mult_doutb         ), // input  wire  [CNT-1:0][31:0] 
  
      .rdy_out    ( unite_rdy          ), // output logic                 
      .wr_en_out  ( matrix_we      [2] ), // output logic                 
      .addr_out   ( matrix_addrb   [2] ), // output logic         [11:0]  
      .din_out    ( matrix_dinb    [2] )  // output logic         [31:0]  
   );
endmodule