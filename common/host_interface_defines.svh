`ifndef __HOST_INTERFACE_DEFS_NONE__
   `define __HOST_INTERFACE_DEFS_NONE__
   
   // Generic AXI-Lite
   interface axi4lite_intf #(
      parameter   AXI4L_ADDR_WIDTH = 32,
                  AXI4L_DATA_WIDTH = 32,
                  AXI4L_STRB_WIDTH = AXI4L_DATA_WIDTH/8

      );

      logic                        awvalid;  // write addr request channel
      logic [2                 :0] awprot;
      logic [AXI4L_ADDR_WIDTH-1:0] awaddr;
      logic                        awready;
      logic                        wvalid;   // write data request channel
      logic [AXI4L_STRB_WIDTH-1:0] wstrb;
      logic [AXI4L_DATA_WIDTH-1:0] wdata;
      logic                        wready;
      logic                        bvalid;   // write response channel
      logic [1                 :0] bresp;
      logic                        bready;
      logic                        arvalid;  // read addr request channel
      logic [AXI4L_ADDR_WIDTH-1:0] araddr;
      logic [2                 :0] arprot;
      logic                        arready;
      logic                        rvalid;   // read response channel
      logic [AXI4L_DATA_WIDTH-1:0] rdata;
      logic [1                 :0] rresp;
      logic                        rready;

      modport master (
         output awvalid,
         output awprot,
         output awaddr,
         input  awready,
         output wvalid,
         output wstrb,
         output wdata,
         input  wready,
         input  bvalid,
         input  bresp,
         output bready,
         output arvalid,
         output araddr,
         output arprot,
         input  arready,
         input  rvalid,
         input  rdata,
         input  rresp,
         output rready
      );

      modport slave  (
         input  awvalid,
         input  awprot,
         input  awaddr,
         output awready,
         input  wvalid,
         input  wstrb,
         input  wdata,
         output wready,
         output bvalid,
         output bresp,
         input  bready,
         input  arvalid,
         input  araddr,
         input  arprot,
         output arready,
         output rvalid,
         output rdata,
         output rresp,
         input  rready
      );

   endinterface   
 
   // Generic Full AXI
   interface axi4_intf #(

      parameter   AXI4_ADDR_WIDTH     = 64 ,
                  AXI4_DATA_WIDTH     = 128,
                  AXI4_WR_STRB_WIDTH  = AXI4_DATA_WIDTH/8
      );

      logic                           awvalid; // write addr request channel
      logic [1                    :0] awburst;
      logic [3                    :0] awcache;
      logic [3                    :0] awid;
      logic [7                    :0] awlen;
      logic                           awlock;
      logic [2                    :0] awprot;
      logic [3                    :0] awqos;
      logic [2                    :0] awsize;
      logic [AXI4_ADDR_WIDTH-1    :0] awaddr;
      logic                           awready;
      logic [3                    :0] awregion;
      logic                           wvalid;  // write data request channel
      logic                           wlast;
      logic [AXI4_WR_STRB_WIDTH-1:0]  wstrb;
      logic [AXI4_DATA_WIDTH-1   :0]  wdata;
      logic                           wready;
      logic                           bvalid;  // write response channel
      logic [3                   :0]  bid;
      logic [1                   :0]  bresp;
      logic                           bready;
      logic                           arvalid; // read addr request channel
      logic [1                   :0]  arburst;
      logic [3                   :0]  arcache;
      logic [3                   :0]  arid;
      logic [7                   :0]  arlen;
      logic                           arlock;
      logic [2                   :0]  arprot;
      logic [3                   :0]  arqos;
      logic                           arready;
      logic [2                   :0]  arsize;
      logic [AXI4_ADDR_WIDTH-1   :0]  araddr;
      logic [3                   :0]  arregion;
      logic                           rvalid;  // read response channel
      logic [3                   :0]  rid;
      logic                           rlast;
      logic [AXI4_DATA_WIDTH-1   :0]  rdata;
      logic [1                   :0]  rresp;
      logic                           rready;

      modport master (
         output awvalid,
         output awburst,
         output awcache,
         output awid,
         output awlen,
         output awlock,
         output awprot,
         output awqos,
         output awsize,
         output awaddr,
         output awregion,
         input  awready,
         output wvalid,
         output wlast,
         output wstrb,
         output wdata,
         input  wready,
         input  bvalid,
         input  bid,
         input  bresp,
         output bready,
         output arvalid,
         output arburst,
         output arcache,
         output arlen,
         output arlock,
         output arprot,
         output arqos,
         output arsize,
         output araddr,
         output arid,
         output arregion,
         input  arready,
         input  rvalid,
         input  rid,
         input  rlast,
         input  rdata,
         input  rresp,
         output rready
      );

      modport slave  (
         input  awvalid,
         input  awburst,
         input  awcache,
         input  awid,
         input  awlen,
         input  awlock,
         input  awprot,
         input  awqos,
         input  awsize,
         input  awaddr,
         input  awregion,
         output awready,
         input  wvalid,
         input  wlast,
         input  wstrb,
         input  wdata,
         output wready,
         output bvalid,
         output bid,
         output bresp,
         input  bready,
         input  arvalid,
         input  arburst,
         input  arcache,
         input  arlen,
         input  arlock,
         input  arprot,
         input  arqos,
         input  arsize,
         input  araddr,
         input  arid,
         input  arregion,
         output arready,
         output rvalid,
         output rid,
         output rlast,
         output rdata,
         output rresp,
         input  rready
      );

   endinterface
 
`endif