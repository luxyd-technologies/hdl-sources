`include "host_interface_defines.svh"


module axi4lite_to_native #( parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 32 )
(
   input  wire                   axi_aclk         ,
   input  wire                   axi_aresetn      ,
                                                  
   axi4lite_intf.slave           axi4lite_slave_if,
                                                  
   output wire                   host_wren_out    ,         
   output wire                   host_rden_out    , 
   output wire  [ADDR_WIDTH-1:0] host_addr_wr_out ,
   output wire  [ADDR_WIDTH-1:0] host_addr_rd_out ,
   output wire  [DATA_WIDTH-1:0] host_data_wr_out ,   
   input  wire  [DATA_WIDTH-1:0] host_data_rd_in  
);
//--------------------------------------------------------------------------------------------------
// Signals
//--------------------------------------------------------------------------------------------------
   logic [ADDR_WIDTH-1:0] axi_awaddr_next  , axi_awaddr_reg  ;
   logic                  axi_awready_next , axi_awready_reg ;
   logic                  axi_wready_next  , axi_wready_reg  ;
   logic            [1:0] axi_bresp_next   , axi_bresp_reg   ;
   logic                  axi_bvalid_next  , axi_bvalid_reg  ;
   logic [ADDR_WIDTH-1:0] axi_araddr_next  , axi_araddr_reg  ;
   logic                  axi_arready_next , axi_arready_reg ;
   logic [DATA_WIDTH-1:0] axi_rdata_next   , axi_rdata_reg   ;
   logic            [1:0] axi_rresp_next   , axi_rresp_reg   ;
   logic                  axi_rvalid_next  , axi_rvalid_reg  ;
   logic                  slv_reg_rden_next, slv_reg_rden_reg;
   logic                  slv_reg_wren_next, slv_reg_wren_reg;
   logic                  aw_en_next       , aw_en_reg       ;
	logic                  slv_reg_rden_int ;
	logic                  slv_reg_wren_int ;   
//--------------------------------------------------------------------------------------------------
// Begin
//--------------------------------------------------------------------------------------------------
   assign axi4lite_slave_if.awready  = axi_awready_reg;
   assign axi4lite_slave_if.wready   = axi_wready_reg;
   assign axi4lite_slave_if.bresp    = axi_bresp_reg;
   assign axi4lite_slave_if.bvalid   = axi_bvalid_reg;
   assign axi4lite_slave_if.arready  = axi_arready_reg;
   assign axi4lite_slave_if.rdata    = axi_rdata_reg;
   assign axi4lite_slave_if.rresp    = axi_rresp_reg;
   assign axi4lite_slave_if.rvalid   = axi_rvalid_reg;
   
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.   
   assign slv_reg_wren_int = axi_wready_reg  & axi4lite_slave_if.wvalid  & axi_awready_reg & axi4lite_slave_if.awvalid;
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.   
   assign slv_reg_rden_int = axi_arready_reg & axi4lite_slave_if.arvalid & ~axi_rvalid_reg;
   
   always_comb begin : get_axi_signals
      // axi_awready is asserted for one s_axi_aclk clock cycle when both
      // s_axi_awvalid and s_axi_wvalid are asserted. axi_awready is
      // de-asserted when reset is low.
      aw_en_next = aw_en_reg;
      if (~axi_awready_reg & axi4lite_slave_if.awvalid & axi4lite_slave_if.wvalid & aw_en_reg) begin
         // slave is ready to accept write address when 
         // there is a valid write address and write data
         // on the write address and data bus. this design 
         // expects no outstanding transactions.       
         axi_awready_next = 1'b1;
         aw_en_next       = 1'b0;
      end else if (axi4lite_slave_if.bready & axi_bvalid_reg) begin
         aw_en_next       = 1'b1;
         axi_awready_next = 1'b0;
      end else begin
         axi_awready_next = 1'b0;
      end                 
      
      // this process is used to latch the address when both 
      // s_axi_awvalid and s_axi_wvalid are valid. 
      axi_awaddr_next = axi_awaddr_reg;
      if (~axi_awready_reg & axi4lite_slave_if.awvalid & axi4lite_slave_if.wvalid & aw_en_reg) begin
         // write address latching
         axi_awaddr_next = axi4lite_slave_if.awaddr;
      end
      
      // axi_wready is asserted for one s_axi_aclk clock cycle when both
      // s_axi_awvalid and s_axi_wvalid are asserted. axi_wready is 
      // de-asserted when reset is low. 
      if (~axi_wready_reg & axi4lite_slave_if.wvalid & axi4lite_slave_if.awvalid & aw_en_reg) begin
         // slave is ready to accept write data when 
         // there is a valid write address and write data
         // on the write address and data bus. this design 
         // expects no outstanding transactions.       
         axi_wready_next = 1'b1;
      end else begin
         axi_wready_next = 1'b0;
      end   
   
      // the write response and response valid signals are asserted by the slave 
      // when axi_wready, s_axi_wvalid, axi_wready and s_axi_wvalid are asserted.  
      // this marks the acceptance of address and indicates the status of 
      // write transaction.   
      axi_bvalid_next = axi_bvalid_reg;
      axi_bresp_next  = axi_bresp_reg;
      if (axi_awready_reg & axi4lite_slave_if.awvalid & ~axi_bvalid_reg & axi_wready_reg & axi4lite_slave_if.wvalid) begin
         // indicates a valid write response is available
         axi_bvalid_next = 1'b1;
         axi_bresp_next  = 2'b0; // 'okay' response 
      end else if (axi4lite_slave_if.bready & axi_bvalid_reg) begin 
         //check if bready is asserted while bvalid is high) 
         //(there is a possibility that bready is always asserted high)   
         axi_bvalid_next = 1'b0; 
      end

      // axi_arready is asserted for one s_axi_aclk clock cycle when
      // s_axi_arvalid is asserted. axi_awready is 
      // de-asserted when reset (active low) is asserted. 
      // the read address is also latched when s_axi_arvalid is 
      // asserted. axi_araddr is reset to zero on reset assertion.
      axi_araddr_next = axi_araddr_reg;
      if (~axi_arready_reg & axi4lite_slave_if.arvalid) begin 
         // indicates that the slave has acceped the valid read address
         axi_arready_next = 1'b1;
         // read address latching
         axi_araddr_next  = axi4lite_slave_if.araddr;
      end else begin 
         axi_arready_next = 1'b0;
      end 

      // axi_rvalid is asserted for one s_axi_aclk clock cycle when both 
      // s_axi_arvalid and axi_arready are asserted. the slave registers 
      // data are available on the axi_rdata bus at this instance. the 
      // assertion of axi_rvalid marks the validity of read data on the 
      // bus and axi_rresp indicates the status of read transaction.axi_rvalid 
      // is deasserted on reset (active low). axi_rresp and axi_rdata are 
      // cleared to zero on reset (active low).  
      axi_rvalid_next = axi_rvalid_reg;
      axi_rresp_next  = axi_rresp_reg; 
      if (axi_arready_reg & axi4lite_slave_if.arvalid & ~axi_rvalid_reg) begin
         // valid read data is available at the read data bus
         axi_rvalid_next = 1'b1;
         axi_rresp_next  = 2'b0; // 'okay' response
      end else if (axi_rvalid_reg & axi4lite_slave_if.rready) begin
         // read data is accepted by the master
         axi_rvalid_next = 1'b0;
      end                
      
      // output register or memory read data
      // when there is a valid read address (s_axi_arvalid) with 
      // acceptance of read address by the slave (axi_arready), 
      // output the read dada       
      //axi_rdata_next = slv_reg_rden_int ? host_data_rd_in : axi_rdata_reg;
      axi_rdata_next = host_data_rd_in;
   end
   
   always_ff @(posedge axi_aclk) begin : reg_signals
      if (~axi_aresetn) begin
         aw_en_reg       <= '1;
         axi_awready_reg <= '0;
         axi_awaddr_reg  <= '0;
         axi_wready_reg  <= '0;
         axi_bvalid_reg  <= '0;
         axi_bresp_reg   <= '0;
         axi_araddr_reg  <= '0;
         axi_arready_reg <= '0;
         axi_rvalid_reg  <= '0;
         axi_rresp_reg   <= '0;
         axi_rdata_reg   <= '0;
      end else begin
         aw_en_reg       <= aw_en_next      ;
         axi_awready_reg <= axi_awready_next;
         axi_awaddr_reg  <= axi_awaddr_next ;
         axi_wready_reg  <= axi_wready_next ;
         axi_bvalid_reg  <= axi_bvalid_next ;
         axi_bresp_reg   <= axi_bresp_next  ;
         axi_araddr_reg  <= axi_araddr_next ;
         axi_arready_reg <= axi_arready_next;
         axi_rvalid_reg  <= axi_rvalid_next ;
         axi_rresp_reg   <= axi_rresp_next  ;
         axi_rdata_reg   <= axi_rdata_next  ;
      end
   end

   assign host_addr_wr_out = axi_awaddr_reg;  // write address latched
   assign host_addr_rd_out = axi_araddr_reg;  // read address latched
   assign host_data_wr_out = axi4lite_slave_if.wdata;
                               
   assign host_wren_out    = slv_reg_wren_int;
   assign host_rden_out    = slv_reg_rden_int;

endmodule