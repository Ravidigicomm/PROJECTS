module soc_top (/*AUTOARG*/
   // Outputs
   tx, sda_oe, sda_o, scl_oe, scl_o, rts, irq, gpio_oe, gpio_o,
   axi_wready, axi_rvalid, axi_rresp, axi_rid, axi_rdata, axi_bvalid,
   axi_bresp, axi_bid, axi_awready, axi_arready, ahb_hwrite,
   ahb_hwdata, ahb_htrans, ahb_hsize, ahb_hsel, ahb_haddr,
   // Inputs
   sda_i, scl_i, rx, resetn, gpio_i, cts, clk, axi_wvalid, axi_wstrb,
   axi_wdata, axi_rready, axi_bready, axi_awvalid, axi_awsize,
   axi_awprot, axi_awlen, axi_awid, axi_awburst, axi_awaddr,
   axi_arvalid, axi_arprot, axi_arid, axi_araddr, ahb_hresp,
   ahb_hready, ahb_hrdata
   );
   /*autowire*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [ADDR_WIDTH-1:0] apb_paddr;		// From axi_to_apb_bridge of axi_to_apb_bridge.v
   wire			apb_penable;		// From axi_to_apb_bridge of axi_to_apb_bridge.v
   wire			apb_prdata;		// From apb_spi_controller of apb_spi_controller.v, ...
   wire			apb_pready;		// From apb_spi_controller of apb_spi_controller.v, ...
   wire			apb_psel;		// From axi_to_apb_bridge of axi_to_apb_bridge.v
   wire			apb_pslverr;		// From apb_spi_controller of apb_spi_controller.v, ...
   wire [DATA_WIDTH-1:0] apb_pwdata;		// From axi_to_apb_bridge of axi_to_apb_bridge.v
   wire			apb_pwrite;		// From axi_to_apb_bridge of axi_to_apb_bridge.v
   wire [3:0]		cs_n;			// From apb_spi_controller of apb_spi_controller.v
   wire			miso;			// From SPI_FLASH_READ_ONLY_ASYNC_NO_LATENCY of SPI_FLASH_READ_ONLY_ASYNC_NO_LATENCY.v
   wire			mosi;			// From apb_spi_controller of apb_spi_controller.v
   wire			sck;			// From apb_spi_controller of apb_spi_controller.v
   // End of automatics
   /*autoinput*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input [DATA_WIDTH-1:0] ahb_hrdata;		// To axi_to_ahb_bridge of axi_to_ahb_bridge.v
   input		ahb_hready;		// To axi_to_ahb_bridge of axi_to_ahb_bridge.v
   input		ahb_hresp;		// To axi_to_ahb_bridge of axi_to_ahb_bridge.v
   input [ADDR_WIDTH-1:0] axi_araddr;		// To axi_to_apb_bridge of axi_to_apb_bridge.v
   input [ID_WIDTH-1:0]	axi_arid;		// To axi_to_apb_bridge of axi_to_apb_bridge.v
   input [2:0]		axi_arprot;		// To axi_to_apb_bridge of axi_to_apb_bridge.v
   input		axi_arvalid;		// To axi_to_apb_bridge of axi_to_apb_bridge.v
   input [ADDR_WIDTH-1:0] axi_awaddr;		// To axi_to_apb_bridge of axi_to_apb_bridge.v, ...
   input [1:0]		axi_awburst;		// To axi_to_ahb_bridge of axi_to_ahb_bridge.v
   input [ID_WIDTH-1:0]	axi_awid;		// To axi_to_apb_bridge of axi_to_apb_bridge.v, ...
   input [7:0]		axi_awlen;		// To axi_to_ahb_bridge of axi_to_ahb_bridge.v
   input [2:0]		axi_awprot;		// To axi_to_apb_bridge of axi_to_apb_bridge.v
   input [2:0]		axi_awsize;		// To axi_to_ahb_bridge of axi_to_ahb_bridge.v
   input		axi_awvalid;		// To axi_to_apb_bridge of axi_to_apb_bridge.v, ...
   input		axi_bready;		// To axi_to_apb_bridge of axi_to_apb_bridge.v
   input		axi_rready;		// To axi_to_apb_bridge of axi_to_apb_bridge.v
   input [DATA_WIDTH-1:0] axi_wdata;		// To axi_to_apb_bridge of axi_to_apb_bridge.v
   input [(DATA_WIDTH/8)-1:0] axi_wstrb;	// To axi_to_apb_bridge of axi_to_apb_bridge.v
   input		axi_wvalid;		// To axi_to_apb_bridge of axi_to_apb_bridge.v
   input		clk;			// To axi_to_apb_bridge of axi_to_apb_bridge.v, ...
   input		cts;			// To apb_uart_controller of apb_uart_controller.v
   input [NUM_GPIO-1:0]	gpio_i;			// To apb_gpio of apb_gpio.v
   input		resetn;			// To axi_to_apb_bridge of axi_to_apb_bridge.v, ...
   input		rx;			// To apb_uart_controller of apb_uart_controller.v
   input		scl_i;			// To apb_i2c_controller of apb_i2c_controller.v
   input		sda_i;			// To apb_i2c_controller of apb_i2c_controller.v
   // End of automatics
   
   /*autooutput*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [ADDR_WIDTH-1:0] ahb_haddr;		// From axi_to_ahb_bridge of axi_to_ahb_bridge.v
   output		ahb_hsel;		// From axi_to_ahb_bridge of axi_to_ahb_bridge.v
   output [2:0]		ahb_hsize;		// From axi_to_ahb_bridge of axi_to_ahb_bridge.v
   output [1:0]		ahb_htrans;		// From axi_to_ahb_bridge of axi_to_ahb_bridge.v
   output [DATA_WIDTH-1:0] ahb_hwdata;		// From axi_to_ahb_bridge of axi_to_ahb_bridge.v
   output		ahb_hwrite;		// From axi_to_ahb_bridge of axi_to_ahb_bridge.v
   output		axi_arready;		// From axi_to_apb_bridge of axi_to_apb_bridge.v
   output		axi_awready;		// From axi_to_apb_bridge of axi_to_apb_bridge.v, ...
   output [ID_WIDTH-1:0] axi_bid;		// From axi_to_apb_bridge of axi_to_apb_bridge.v
   output [1:0]		axi_bresp;		// From axi_to_apb_bridge of axi_to_apb_bridge.v
   output		axi_bvalid;		// From axi_to_apb_bridge of axi_to_apb_bridge.v
   output [DATA_WIDTH-1:0] axi_rdata;		// From axi_to_apb_bridge of axi_to_apb_bridge.v
   output [ID_WIDTH-1:0] axi_rid;		// From axi_to_apb_bridge of axi_to_apb_bridge.v
   output [1:0]		axi_rresp;		// From axi_to_apb_bridge of axi_to_apb_bridge.v
   output		axi_rvalid;		// From axi_to_apb_bridge of axi_to_apb_bridge.v
   output		axi_wready;		// From axi_to_apb_bridge of axi_to_apb_bridge.v
   output [NUM_GPIO-1:0] gpio_o;		// From apb_gpio of apb_gpio.v
   output [NUM_GPIO-1:0] gpio_oe;		// From apb_gpio of apb_gpio.v
   output		irq;			// From apb_spi_controller of apb_spi_controller.v, ...
   output		rts;			// From apb_uart_controller of apb_uart_controller.v
   output		scl_o;			// From apb_i2c_controller of apb_i2c_controller.v
   output		scl_oe;			// From apb_i2c_controller of apb_i2c_controller.v
   output		sda_o;			// From apb_i2c_controller of apb_i2c_controller.v
   output		sda_oe;			// From apb_i2c_controller of apb_i2c_controller.v
   output		tx;			// From apb_uart_controller of apb_uart_controller.v
   // End of automatics
  
/*axi_to_apb_bridge AUTO_TEMPLATE (
              

                );
        */
axi_to_apb_bridge axi_to_apb_bridge(/*AUTOINST*/
				    // Outputs
				    .axi_awready	(axi_awready),
				    .axi_wready		(axi_wready),
				    .axi_bvalid		(axi_bvalid),
				    .axi_bresp		(axi_bresp[1:0]),
				    .axi_bid		(axi_bid[ID_WIDTH-1:0]),
				    .axi_arready	(axi_arready),
				    .axi_rvalid		(axi_rvalid),
				    .axi_rdata		(axi_rdata[DATA_WIDTH-1:0]),
				    .axi_rresp		(axi_rresp[1:0]),
				    .axi_rid		(axi_rid[ID_WIDTH-1:0]),
				    .apb_psel		(apb_psel),
				    .apb_penable	(apb_penable),
				    .apb_pwrite		(apb_pwrite),
				    .apb_paddr		(apb_paddr[ADDR_WIDTH-1:0]),
				    .apb_pwdata		(apb_pwdata[DATA_WIDTH-1:0]),
				    // Inputs
				    .clk		(clk),
				    .resetn		(resetn),
				    .axi_awvalid	(axi_awvalid),
				    .axi_awaddr		(axi_awaddr[ADDR_WIDTH-1:0]),
				    .axi_awprot		(axi_awprot[2:0]),
				    .axi_awid		(axi_awid[ID_WIDTH-1:0]),
				    .axi_wvalid		(axi_wvalid),
				    .axi_wdata		(axi_wdata[DATA_WIDTH-1:0]),
				    .axi_wstrb		(axi_wstrb[(DATA_WIDTH/8)-1:0]),
				    .axi_bready		(axi_bready),
				    .axi_arvalid	(axi_arvalid),
				    .axi_araddr		(axi_araddr[ADDR_WIDTH-1:0]),
				    .axi_arprot		(axi_arprot[2:0]),
				    .axi_arid		(axi_arid[ID_WIDTH-1:0]),
				    .axi_rready		(axi_rready),
				    .apb_prdata		(apb_prdata[DATA_WIDTH-1:0]),
				    .apb_pready		(apb_pready),
				    .apb_pslverr	(apb_pslverr));
   
/*apb_spi_controller AUTO_TEMPLATE (
              
    // Connect APB slave inputs by name
    .\(p\(addr\|wdata\|write\|sel\|enable\)\) (apb_\1[]),

    // Connect APB slave outputs by name
    .\(p\(rdata\|ready\|slverr\)\) (apb_\1),
                );
        */   
apb_spi_controller apb_spi_controller(/*AUTOINST*/
				      // Outputs
				      .prdata		(apb_prdata),	 // Templated
				      .pready		(apb_pready),	 // Templated
				      .pslverr		(apb_pslverr),	 // Templated
				      .sck		(sck),
				      .mosi		(mosi),
				      .cs_n		(cs_n[3:0]),
				      .irq		(irq),
				      // Inputs
				      .clk		(clk),
				      .resetn		(resetn),
				      .psel		(apb_psel),	 // Templated
				      .penable		(apb_penable),	 // Templated
				      .pwrite		(apb_pwrite),	 // Templated
				      .paddr		(apb_paddr[APB_ADDR_WIDTH-1:0]), // Templated
				      .pwdata		(apb_pwdata[APB_DATA_WIDTH-1:0]), // Templated
				      .miso		(miso));

/*
 SPI_FLASH_READ_ONLY_ASYNC_NO_LATENCY AUTO_TEMPLATE (
                                                    .DO (miso),
                                                    .DI (mosi),
                                                    .sclk(sck),
                                                    .cs_n(cs_n),
                                                     );
 */
   
   SPI_FLASH_READ_ONLY_ASYNC_NO_LATENCY SPI_FLASH_READ_ONLY_ASYNC_NO_LATENCY(/*AUTOINST*/
									     // Outputs
									     .DO		(miso),		 // Templated
									     // Inputs
									     .cs_n		(cs_n),		 // Templated
									     .sclk		(sck),		 // Templated
									     .DI		(mosi));		 // Templated
/*
 apb_uart_controller AUTO_TEMPLATE(
                        // Connect APB slave inputs by name
                       .\(p\(addr\|wdata\|write\|sel\|enable\)\) (apb_\1[]),

                        // Connect APB slave outputs by name
                       .\(p\(rdata\|ready\|slverr\)\) (apb_\1),
                                  );
*/
   apb_uart_controller apb_uart_controller(/*AUTOINST*/
					   // Outputs
					   .prdata		(apb_prdata),	 // Templated
					   .pready		(apb_pready),	 // Templated
					   .pslverr		(apb_pslverr),	 // Templated
					   .tx			(tx),
					   .irq			(irq),
					   .rts			(rts),
					   // Inputs
					   .clk			(clk),
					   .resetn		(resetn),
					   .psel		(apb_psel),	 // Templated
					   .penable		(apb_penable),	 // Templated
					   .pwrite		(apb_pwrite),	 // Templated
					   .paddr		(apb_paddr[APB_ADDR_WIDTH-1:0]), // Templated
					   .pwdata		(apb_pwdata[APB_DATA_WIDTH-1:0]), // Templated
					   .rx			(rx),
					   .cts			(cts));
   /*
 apb_i2c_controller AUTO_TEMPLATE(
                        // Connect APB slave inputs by name
                       .\(p\(addr\|wdata\|write\|sel\|enable\)\) (apb_\1[]),

                        // Connect APB slave outputs by name
                       .\(p\(rdata\|ready\|slverr\)\) (apb_\1),
                                  );
*/
   apb_i2c_controller apb_i2c_controller(/*AUTOINST*/
					 // Outputs
					 .prdata		(apb_prdata),	 // Templated
					 .pready		(apb_pready),	 // Templated
					 .pslverr		(apb_pslverr),	 // Templated
					 .scl_o			(scl_o),
					 .scl_oe		(scl_oe),
					 .sda_o			(sda_o),
					 .sda_oe		(sda_oe),
					 .irq			(irq),
					 // Inputs
					 .clk			(clk),
					 .resetn		(resetn),
					 .psel			(apb_psel),	 // Templated
					 .penable		(apb_penable),	 // Templated
					 .pwrite		(apb_pwrite),	 // Templated
					 .paddr			(apb_paddr[APB_ADDR_WIDTH-1:0]), // Templated
					 .pwdata		(apb_pwdata[APB_DATA_WIDTH-1:0]), // Templated
					 .scl_i			(scl_i),
					 .sda_i			(sda_i));
   
  /*
 apb_gpio AUTO_TEMPLATE(
                        // Connect APB slave inputs by name
                       .\(p\(addr\|wdata\|write\|sel\|enable\)\) (apb_\1[]),

                        // Connect APB slave outputs by name
                       .\(p\(rdata\|ready\|slverr\)\) (apb_\1),
                                  );
*/  
apb_gpio apb_gpio(/*AUTOINST*/
		  // Outputs
		  .prdata		(apb_prdata),		 // Templated
		  .pready		(apb_pready),		 // Templated
		  .pslverr		(apb_pslverr),		 // Templated
		  .gpio_o		(gpio_o[NUM_GPIO-1:0]),
		  .gpio_oe		(gpio_oe[NUM_GPIO-1:0]),
		  .irq			(irq),
		  // Inputs
		  .clk			(clk),
		  .resetn		(resetn),
		  .psel			(apb_psel),		 // Templated
		  .penable		(apb_penable),		 // Templated
		  .pwrite		(apb_pwrite),		 // Templated
		  .paddr		(apb_paddr[APB_ADDR_WIDTH-1:0]), // Templated
		  .pwdata		(apb_pwdata[APB_DATA_WIDTH-1:0]), // Templated
		  .gpio_i		(gpio_i[NUM_GPIO-1:0]));
   
axi_to_ahb_bridge axi_to_ahb_bridge(/*AUTOINST*/
				    // Outputs
				    .axi_awready	(axi_awready),
				    .ahb_hsel		(ahb_hsel),
				    .ahb_haddr		(ahb_haddr[ADDR_WIDTH-1:0]),
				    .ahb_hwrite		(ahb_hwrite),
				    .ahb_hsize		(ahb_hsize[2:0]),
				    .ahb_htrans		(ahb_htrans[1:0]),
				    .ahb_hwdata		(ahb_hwdata[DATA_WIDTH-1:0]),
				    // Inputs
				    .clk		(clk),
				    .resetn		(resetn),
				    .axi_awvalid	(axi_awvalid),
				    .axi_awaddr		(axi_awaddr[ADDR_WIDTH-1:0]),
				    .axi_awlen		(axi_awlen[7:0]),
				    .axi_awsize		(axi_awsize[2:0]),
				    .axi_awburst	(axi_awburst[1:0]),
				    .axi_awid		(axi_awid[ID_WIDTH-1:0]),
				    .ahb_hrdata		(ahb_hrdata[DATA_WIDTH-1:0]),
				    .ahb_hready		(ahb_hready),
				    .ahb_hresp		(ahb_hresp));
   
 
endmodule
// Local Variables:
// verilog-library-files:("." "/home/ravi_mishra/PROJECTS/SOC_DESIGN/Bridges/axi_to_apb_bridge.v"  "/home/ravi_mishra/PROJECTS/SOC_DESIGN/Bridges/apb_spi_controller.v" "/home/ravi_mishra/PROJECTS/SOC_DESIGN/Peripherals/RTL/SPI_FLASH_READ_ONLY_ASYNC_NO_LATENCY.v" "/home/ravi_mishra/PROJECTS/SOC_DESIGN/Bridges/apb_uart_controller.sv" "/home/ravi_mishra/PROJECTS/SOC_DESIGN/Bridges/apb_i2c_controller.sv" "/home/ravi_mishra/PROJECTS/SOC_DESIGN/Peripherals/RTL/apb_gpio.v" "/home/ravi_mishra/PROJECTS/SOC_DESIGN/Bridges/axi_to_ahb_bridge.sv")
// End:

