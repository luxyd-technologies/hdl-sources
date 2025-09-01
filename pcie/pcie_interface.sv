`include "general_defines.svh"
`include "host_interface_defines.svh"

module pcie_interface
(                           
   input  wire             PCIE_RST_N           ,
   input  wire             P_PCIE_REFCLKp       ,
   input  wire             P_PCIE_REFCLKn       ,
   input  wire       [3:0] P_PCIE_RXp           ,
   input  wire       [3:0] P_PCIE_RXn           ,
   output wire       [3:0] P_PCIE_TXp           ,
   output wire       [3:0] P_PCIE_TXn           ,
                                                
   output wire             axi_aclk             ,   
   output wire             axi_aresetn          ,    
   output wire             user_lnk_up          ,
                                                
   output wire             host_wren_out        ,
   output wire             host_rden_out        ,
   output wire      [31:0] host_addr_wr_out     ,
   output wire      [31:0] host_addr_rd_out     ,
   output wire      [31:0] host_data_wr_out     ,
   input  wire      [31:0] host_data_rd_in      ,
                                                
   output wire             bram_rst_out         ,
   output wire             bram_clk_out         ,
   output wire             bram_en_out          ,
   output wire      [15:0] bram_we_out          ,
   output wire      [63:0] bram_addr_out        ,
   output wire     [127:0] bram_wrdata_out      ,
   input  wire     [127:0] bram_rddata_in       ,
                                                
   input  wire      [25:0] common_commands_in   ,
   input  wire      [83:0] pipe_rx_0_sigs       ,
   input  wire      [83:0] pipe_rx_1_sigs       ,
   input  wire      [83:0] pipe_rx_2_sigs       ,
   input  wire      [83:0] pipe_rx_3_sigs       ,
   input  wire      [83:0] pipe_rx_4_sigs       ,
   input  wire      [83:0] pipe_rx_5_sigs       ,
   input  wire      [83:0] pipe_rx_6_sigs       ,
   input  wire      [83:0] pipe_rx_7_sigs       ,
   output wire      [25:0] common_commands_out  ,
   output wire      [83:0] pipe_tx_0_sigs       ,
   output wire      [83:0] pipe_tx_1_sigs       ,
   output wire      [83:0] pipe_tx_2_sigs       ,
   output wire      [83:0] pipe_tx_3_sigs       ,
   output wire      [83:0] pipe_tx_4_sigs       ,
   output wire      [83:0] pipe_tx_5_sigs       ,
   output wire      [83:0] pipe_tx_6_sigs       ,
   output wire      [83:0] pipe_tx_7_sigs       
);
//--------------------------------------------------------------------------------------------------
// Signals
//--------------------------------------------------------------------------------------------------

   axi4_intf      axi_if     ();
   axi4lite_intf  axilite_if ();
   
   wire           gtrefclk /*synthesis syn_noclockbuf=1*/;
   reg      [0:0] usr_irq_req = '0;
   wire     [0:0] usr_irq_ack     ;   
   wire           msi_enable      ;  
   wire     [2:0] msi_vector_width;  
   reg     [17:0] bram_addr_int   ;
   reg     [63:0] bram_addr_reg   ;
   
`ifdef SIMULATION
   localparam C_NUM_USR_IRQ	 = 1;
   localparam C_M_AXI_ID_WIDTH = 4;
   
   wire           user_clk;
   wire           user_resetn;
   wire           sys_rst_n_c;
   wire           m_axi_wvalid;
   wire           m_axi_wready;
   wire  [15 : 0] m_axi_wstrb ;
   wire [127 : 0] m_axi_wdata ;
   
`endif

//--------------------------------------------------------------------------------------------------
// Begin
//--------------------------------------------------------------------------------------------------

   //IBUFDS_GTE2
   IBUFDS_GTE2 
   inst_IBUFDS_GTE2
   (
      .O      ( gtrefclk       ),
      .ODIV2  (                ),
      .CEB    ( 1'b0           ),
      .I      ( P_PCIE_REFCLKp ),
      .IB     ( P_PCIE_REFCLKn )
   );         

   xdma_0 
   inst_xdma_0 
   (
     .sys_clk              ( gtrefclk         ),     // input wire sys_clk        
     .sys_rst_n            ( PCIE_RST_N       ),     // input wire sys_rst_n
     .user_lnk_up          ( user_lnk_up      ),     // output wire user_lnk_up
                                                     
     .pci_exp_txp          ( P_PCIE_TXp       ),     // output wire [3 : 0] pci_exp_txp
     .pci_exp_txn          ( P_PCIE_TXn       ),     // output wire [3 : 0] pci_exp_txn
     .pci_exp_rxp          ( P_PCIE_RXp       ),     // input wire [3 : 0] pci_exp_rxp
     .pci_exp_rxn          ( P_PCIE_RXn       ),     // input wire [3 : 0] pci_exp_rxn
                                                     
     .axi_aclk             ( axi_aclk         ),     // output wire axi_aclk 
     .axi_aresetn          ( axi_aresetn      ),     // output wire axi_aresetn
                                                     
     .usr_irq_req          ( usr_irq_req      ),     // input wire [0 : 0] usr_irq_req
     .usr_irq_ack          ( usr_irq_ack      ),     // output wire [0 : 0] usr_irq_ack
     .msi_enable           ( msi_enable       ),     // output wire msi_enable
     .msi_vector_width     ( msi_vector_width ),     // output wire [2 : 0] msi_vector_width
                                                     
     .m_axi_awready        ( axi_if.awready),        // input wire m_axi_awready
     .m_axi_wready         ( axi_if.wready),         // input wire m_axi_wready
     .m_axi_bid            ( axi_if.bid),            // input wire [3 : 0] m_axi_bid
     .m_axi_bresp          ( axi_if.bresp),          // input wire [1 : 0] m_axi_bresp
     .m_axi_bvalid         ( axi_if.bvalid),         // input wire m_axi_bvalid
     .m_axi_arready        ( axi_if.arready),        // input wire m_axi_arready
     .m_axi_rid            ( axi_if.rid),            // input wire [3 : 0] m_axi_rid
     .m_axi_rdata          ( axi_if.rdata),          // input wire [127 : 0] m_axi_rdata
     .m_axi_rresp          ( axi_if.rresp),          // input wire [1 : 0] m_axi_rresp
     .m_axi_rlast          ( axi_if.rlast),          // input wire m_axi_rlast
     .m_axi_rvalid         ( axi_if.rvalid),         // input wire m_axi_rvalid
     .m_axi_awid           ( axi_if.awid),           // output wire [3 : 0] m_axi_awid
     .m_axi_awaddr         ( axi_if.awaddr),         // output wire [63 : 0] m_axi_awaddr
     .m_axi_awlen          ( axi_if.awlen),          // output wire [7 : 0] m_axi_awlen
     .m_axi_awsize         ( axi_if.awsize),         // output wire [2 : 0] m_axi_awsize
     .m_axi_awburst        ( axi_if.awburst),        // output wire [1 : 0] m_axi_awburst
     .m_axi_awprot         ( axi_if.awprot),         // output wire [2 : 0] m_axi_awprot
     .m_axi_awvalid        ( axi_if.awvalid),        // output wire m_axi_awvalid
     .m_axi_awlock         ( axi_if.awlock),         // output wire m_axi_awlock
     .m_axi_awcache        ( axi_if.awcache),        // output wire [3 : 0] m_axi_awcache
     .m_axi_wdata          ( axi_if.wdata),          // output wire [127 : 0] m_axi_wdata
     .m_axi_wstrb          ( axi_if.wstrb),          // output wire [15 : 0] m_axi_wstrb
     .m_axi_wlast          ( axi_if.wlast),          // output wire m_axi_wlast
     .m_axi_wvalid         ( axi_if.wvalid),         // output wire m_axi_wvalid
     .m_axi_bready         ( axi_if.bready),         // output wire m_axi_bready
     .m_axi_arid           ( axi_if.arid),           // output wire [3 : 0] m_axi_arid
     .m_axi_araddr         ( axi_if.araddr),         // output wire [63 : 0] m_axi_araddr
     .m_axi_arlen          ( axi_if.arlen),          // output wire [7 : 0] m_axi_arlen
     .m_axi_arsize         ( axi_if.arsize),         // output wire [2 : 0] m_axi_arsize
     .m_axi_arburst        ( axi_if.arburst),        // output wire [1 : 0] m_axi_arburst
     .m_axi_arprot         ( axi_if.arprot),         // output wire [2 : 0] m_axi_arprot
     .m_axi_arvalid        ( axi_if.arvalid),        // output wire m_axi_arvalid
     .m_axi_arlock         ( axi_if.arlock),         // output wire m_axi_arlock
     .m_axi_arcache        ( axi_if.arcache),        // output wire [3 : 0] m_axi_arcache
     .m_axi_rready         ( axi_if.rready),         // output wire m_axi_rready
                                                            
     .m_axil_awaddr        ( axilite_if.awaddr),     // output wire [31 : 0] m_axil_awaddr
     .m_axil_awprot        ( axilite_if.awprot),     // output wire [2 : 0] m_axil_awprot
     .m_axil_awvalid       ( axilite_if.awvalid),    // output wire m_axil_awvalid
     .m_axil_awready       ( axilite_if.awready),    // input wire m_axil_awready
     .m_axil_wdata         ( axilite_if.wdata),      // output wire [31 : 0] m_axil_wdata
     .m_axil_wstrb         ( axilite_if.wstrb),      // output wire [3 : 0] m_axil_wstrb
     .m_axil_wvalid        ( axilite_if.wvalid),     // output wire m_axil_wvalid
     .m_axil_wready        ( axilite_if.wready),     // input wire m_axil_wready
     .m_axil_bvalid        ( axilite_if.bvalid),     // input wire m_axil_bvalid
     .m_axil_bresp         ( axilite_if.bresp),      // input wire [1 : 0] m_axil_bresp
     .m_axil_bready        ( axilite_if.bready),     // output wire m_axil_bready
     .m_axil_araddr        ( axilite_if.araddr),     // output wire [31 : 0] m_axil_araddr
     .m_axil_arprot        ( axilite_if.arprot),     // output wire [2 : 0] m_axil_arprot
     .m_axil_arvalid       ( axilite_if.arvalid),    // output wire m_axil_arvalid
     .m_axil_arready       ( axilite_if.arready),    // input wire m_axil_arready
     .m_axil_rdata         ( axilite_if.rdata),      // input wire [31 : 0] m_axil_rdata
     .m_axil_rresp         ( axilite_if.rresp),      // input wire [1 : 0] m_axil_rresp
     .m_axil_rvalid        ( axilite_if.rvalid),     // input wire m_axil_rvalid
     .m_axil_rready        ( axilite_if.rready),     // output wire m_axil_rready
                                                         
     .common_commands_in   ( common_commands_in  ),  // input wire [25 : 0] common_commands_in
     .pipe_rx_0_sigs       ( pipe_rx_0_sigs      ),  // input wire [83 : 0] pipe_rx_0_sigs
     .pipe_rx_1_sigs       ( pipe_rx_1_sigs      ),  // input wire [83 : 0] pipe_rx_1_sigs
     .pipe_rx_2_sigs       ( pipe_rx_2_sigs      ),  // input wire [83 : 0] pipe_rx_2_sigs
     .pipe_rx_3_sigs       ( pipe_rx_3_sigs      ),  // input wire [83 : 0] pipe_rx_3_sigs
     .pipe_rx_4_sigs       ( pipe_rx_4_sigs      ),  // input wire [83 : 0] pipe_rx_4_sigs
     .pipe_rx_5_sigs       ( pipe_rx_5_sigs      ),  // input wire [83 : 0] pipe_rx_5_sigs
     .pipe_rx_6_sigs       ( pipe_rx_6_sigs      ),  // input wire [83 : 0] pipe_rx_6_sigs
     .pipe_rx_7_sigs       ( pipe_rx_7_sigs      ),  // input wire [83 : 0] pipe_rx_7_sigs
     .common_commands_out  ( common_commands_out ),  // output wire [25 : 0] common_commands_out
     .pipe_tx_0_sigs       ( pipe_tx_0_sigs      ),  // output wire [83 : 0] pipe_tx_0_sigs
     .pipe_tx_1_sigs       ( pipe_tx_1_sigs      ),  // output wire [83 : 0] pipe_tx_1_sigs
     .pipe_tx_2_sigs       ( pipe_tx_2_sigs      ),  // output wire [83 : 0] pipe_tx_2_sigs
     .pipe_tx_3_sigs       ( pipe_tx_3_sigs      ),  // output wire [83 : 0] pipe_tx_3_sigs
     .pipe_tx_4_sigs       ( pipe_tx_4_sigs      ),  // output wire [83 : 0] pipe_tx_4_sigs
     .pipe_tx_5_sigs       ( pipe_tx_5_sigs      ),  // output wire [83 : 0] pipe_tx_5_sigs
     .pipe_tx_6_sigs       ( pipe_tx_6_sigs      ),  // output wire [83 : 0] pipe_tx_6_sigs
     .pipe_tx_7_sigs       ( pipe_tx_7_sigs      )   // output wire [83 : 0] pipe_tx_7_sigs
   );

   // send out full axi_if.awaddr and axi_if.araddr
   always_ff @(posedge axi_aclk) begin : reg_bram_addr
      if (~axi_aresetn) begin
         bram_addr_reg <= 64'b0;
      end else if (axi_if.awvalid & axi_if.awready) begin
         bram_addr_reg <= axi_if.awaddr;
      end else if (axi_if.arvalid & axi_if.arready) begin
         bram_addr_reg <= axi_if.araddr;
      end
   end
   
   axi_bram_ctrl_0 
   inst_axi_bram_ctrl_0 
   (
      .s_axi_aclk    ( axi_aclk            ), // input wire s_axi_aclk
      .s_axi_aresetn ( axi_aresetn         ), // input wire s_axi_aresetn
      .s_axi_awaddr  ( axi_if.awaddr[17:0] ), // input wire [17 : 0] s_axi_awaddr
      .s_axi_awlen   ( axi_if.awlen        ), // input wire [7 : 0] s_axi_awlen
      .s_axi_awsize  ( axi_if.awsize       ), // input wire [2 : 0] s_axi_awsize
      .s_axi_awburst ( axi_if.awburst      ), // input wire [1 : 0] s_axi_awburst
      .s_axi_awlock  ( axi_if.awlock       ), // input wire s_axi_awlock
      .s_axi_awcache ( axi_if.awcache      ), // input wire [3 : 0] s_axi_awcache
      .s_axi_awprot  ( axi_if.awprot       ), // input wire [2 : 0] s_axi_awprot
      .s_axi_awvalid ( axi_if.awvalid      ), // input wire s_axi_awvalid
      .s_axi_awready ( axi_if.awready      ), // output wire s_axi_awready
      .s_axi_wdata   ( axi_if.wdata        ), // input wire [127 : 0] s_axi_wdata
      .s_axi_wstrb   ( axi_if.wstrb        ), // input wire [15 : 0] s_axi_wstrb
      .s_axi_wlast   ( axi_if.wlast        ), // input wire s_axi_wlast
      .s_axi_wvalid  ( axi_if.wvalid       ), // input wire s_axi_wvalid
      .s_axi_wready  ( axi_if.wready       ), // output wire s_axi_wready
      .s_axi_bresp   ( axi_if.bresp        ), // output wire [1 : 0] s_axi_bresp
      .s_axi_bvalid  ( axi_if.bvalid       ), // output wire s_axi_bvalid
      .s_axi_bready  ( axi_if.bready       ), // input wire s_axi_bready
      .s_axi_araddr  ( axi_if.araddr[17:0] ), // input wire [17 : 0] s_axi_araddr
      .s_axi_arlen   ( axi_if.arlen        ), // input wire [7 : 0] s_axi_arlen
      .s_axi_arsize  ( axi_if.arsize       ), // input wire [2 : 0] s_axi_arsize
      .s_axi_arburst ( axi_if.arburst      ), // input wire [1 : 0] s_axi_arburst
      .s_axi_arlock  ( axi_if.arlock       ), // input wire s_axi_arlock
      .s_axi_arcache ( axi_if.arcache      ), // input wire [3 : 0] s_axi_arcache
      .s_axi_arprot  ( axi_if.arprot       ), // input wire [2 : 0] s_axi_arprot
      .s_axi_arvalid ( axi_if.arvalid      ), // input wire s_axi_arvalid
      .s_axi_arready ( axi_if.arready      ), // output wire s_axi_arready
      .s_axi_rdata   ( axi_if.rdata        ), // output wire [127 : 0] s_axi_rdata
      .s_axi_rresp   ( axi_if.rresp        ), // output wire [1 : 0] s_axi_rresp
      .s_axi_rlast   ( axi_if.rlast        ), // output wire s_axi_rlast
      .s_axi_rvalid  ( axi_if.rvalid       ), // output wire s_axi_rvalid
      .s_axi_rready  ( axi_if.rready       ), // input wire s_axi_rready
 
      .bram_rst_a    ( bram_rst_out        ), // output wire bram_rst_a
      .bram_clk_a    ( bram_clk_out        ), // output wire bram_clk_a
      .bram_en_a     ( bram_en_out         ), // output wire bram_en_a
      .bram_we_a     ( bram_we_out         ), // output wire [15 : 0] bram_we_a
      .bram_addr_a   ( bram_addr_int       ), // output wire [17 : 0] bram_addr_a
      .bram_wrdata_a ( bram_wrdata_out     ), // output wire [127 : 0] bram_wrdata_a
      .bram_rddata_a ( bram_rddata_in      )  // input  wire [127 : 0] bram_rddata_a
   );
   
   assign axi_if.rid    = '0;
   assign axi_if.bid    = '0;
   assign bram_addr_out = {bram_addr_reg[63:18], bram_addr_int[17:0]};
   
   axi4lite_to_native
   inst_axi4lite_to_native
   (
      .axi_aclk          ( axi_aclk         ), // input  wire                  
      .axi_aresetn       ( axi_aresetn      ), // input  wire                  
      .axi4lite_slave_if ( axilite_if       ), // axi4lite_intf.slave          
                                            
      .host_wren_out     ( host_wren_out    ), // output wire                           
      .host_rden_out     ( host_rden_out    ), // output wire                   
      .host_addr_wr_out  ( host_addr_wr_out ), // output wire  [ADDR_WIDTH-1:0]
      .host_addr_rd_out  ( host_addr_rd_out ), // output wire  [ADDR_WIDTH-1:0]
      .host_data_wr_out  ( host_data_wr_out ), // output wire  [DATA_WIDTH-1:0]   
      .host_data_rd_in   ( host_data_rd_in  )  // input  wire  [DATA_WIDTH-1:0]
   );

`ifdef SIMULATION 
   assign user_clk      = axi_aclk;
   assign user_resetn   = axi_aresetn;
   assign sys_rst_n_c   = PCIE_RST_N;
   
   assign m_axi_wready  = axi_if.wready;
   assign m_axi_wvalid  = axi_if.wvalid;
   assign m_axi_wstrb   = axi_if.wstrb;
   assign m_axi_wdata   = axi_if.wdata;

`endif  
  
endmodule