`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:29:35 02/23/2015 
// Design Name: 
// Module Name:   
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module apb_uart_controller #(
    parameter APB_ADDR_WIDTH = 8,
    parameter APB_DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16
) (
    input wire clk,
    input wire resetn,
    
    // APB Interface
    input wire                     psel,
    input wire                     penable,
    input wire                     pwrite,
    input wire [APB_ADDR_WIDTH-1:0] paddr,
    input wire [APB_DATA_WIDTH-1:0] pwdata,
    output reg [APB_DATA_WIDTH-1:0] prdata,
    output wire                    pready,
    output wire                    pslverr,
    
    // UART Interface
    output wire                    tx,
    input wire                     rx,
    output wire                    irq,
    input wire                     cts,
    output wire                    rts
);

// UART Register Map
localparam UART_CR     = 8'h00; // Control Register
localparam UART_SR     = 8'h04; // Status Register
localparam UART_DR     = 8'h08; // Data Register
localparam UART_BAUD   = 8'h0C; // Baud Rate Register
localparam UART_FCR    = 8'h10; // FIFO Control
localparam UART_FSR    = 8'h14; // FIFO Status
localparam UART_LCR    = 8'h18; // Line Control
localparam UART_MCR    = 8'h1C; // Modem Control
localparam UART_MSR    = 8'h20; // Modem Status
localparam UART_IMR    = 8'h24; // Interrupt Mask
localparam UART_ISR    = 8'h28; // Interrupt Status

// Control Register bits
localparam CR_EN       = 0;     // UART Enable
localparam CR_TXEN     = 1;     // Transmit Enable
localparam CR_RXEN     = 2;     // Receive Enable
localparam CR_LOOP     = 3;     // Loopback mode

// Status Register bits
localparam SR_TXEMPTY  = 0;     // TX FIFO empty
localparam SR_TXFULL   = 1;     // TX FIFO full
localparam SR_RXEMPTY  = 2;     // RX FIFO empty
localparam SR_RXFULL   = 3;     // RX FIFO full
localparam SR_BUSY     = 4;     // UART busy

// Line Control Register bits
localparam LCR_WLS     = 0;     // Word length select [1:0]
localparam LCR_STB     = 2;     // Stop bits
localparam LCR_PEN     = 3;     // Parity enable
localparam LCR_EPS     = 4;     // Even parity select
localparam LCR_SP      = 5;     // Stick parity
localparam LCR_BC      = 6;     // Break control

// Internal registers
reg [APB_DATA_WIDTH-1:0] cr_reg;
reg [APB_DATA_WIDTH-1:0] sr_reg;
reg [APB_DATA_WIDTH-1:0] baud_reg;
reg [APB_DATA_WIDTH-1:0] lcr_reg;
reg [APB_DATA_WIDTH-1:0] mcr_reg;
reg [APB_DATA_WIDTH-1:0] imr_reg;

// FIFO signals
reg [7:0] tx_fifo [0:FIFO_DEPTH-1];
reg [7:0] rx_fifo [0:FIFO_DEPTH-1];
reg [4:0] tx_wptr, tx_rptr;
reg [4:0] rx_wptr, rx_rptr;

// UART signals
reg tx_reg;
reg tx_busy;
reg rx_busy;
reg [7:0] tx_shift;
reg [7:0] rx_shift;
reg [3:0] tx_bit_count;
reg [3:0] rx_bit_count;
reg [15:0] baud_counter;

// Baud rate generation
wire baud_tick = (baud_counter == baud_reg[15:0]);
wire [15:0] baud_divisor = baud_reg[15:0];

assign pready = 1'b1;
assign pslverr = 1'b0;

// Register read
always @(*) begin
    prdata = {APB_DATA_WIDTH{1'b0}};
    if (psel && penable && !pwrite) begin
        case (paddr)
            UART_CR:    prdata = cr_reg;
            UART_SR:    prdata = sr_reg;
            UART_DR:    prdata = {24'h0, rx_fifo[rx_rptr[3:0]]};
            UART_BAUD:  prdata = baud_reg;
            UART_FSR:   prdata = {16'h0, tx_wptr - tx_rptr, rx_wptr - rx_rptr};
            UART_LCR:   prdata = lcr_reg;
            UART_MCR:   prdata = mcr_reg;
            UART_MSR:   prdata = {30'h0, cts, 1'b0}; // Modem status
            UART_IMR:   prdata = imr_reg;
            UART_ISR:   prdata = {31'h0, irq};
            default:    prdata = {APB_DATA_WIDTH{1'b0}};
        endcase
    end
end

// Register write
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        cr_reg <= 0;
        baud_reg <= 16'd325; // 115200 baud @ 50MHz
        lcr_reg <= 8'h03; // 8N1
        mcr_reg <= 0;
        imr_reg <= 0;
        tx_wptr <= 0;
        tx_rptr <= 0;
        rx_wptr <= 0;
        rx_rptr <= 0;
    end else if (psel && penable && pwrite) begin
        case (paddr)
            UART_CR:    cr_reg <= pwdata;
            UART_DR: begin
                if ((tx_wptr - tx_rptr) < FIFO_DEPTH) begin
                    tx_fifo[tx_wptr[3:0]] <= pwdata[7:0];
                    tx_wptr <= tx_wptr + 1;
                end
            end
            UART_BAUD:  baud_reg <= pwdata;
            UART_LCR:   lcr_reg <= pwdata;
            UART_MCR:   mcr_reg <= pwdata;
            UART_IMR:   imr_reg <= pwdata;
        endcase
    end
    
    // Update status
    sr_reg[SR_TXEMPTY] <= (tx_wptr == tx_rptr);
    sr_reg[SR_TXFULL] <= ((tx_wptr - tx_rptr) == FIFO_DEPTH);
    sr_reg[SR_RXEMPTY] <= (rx_wptr == rx_rptr);
    sr_reg[SR_RXFULL] <= ((rx_wptr - rx_rptr) == FIFO_DEPTH);
    sr_reg[SR_BUSY] <= tx_busy || rx_busy;
end

// TX state machine
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        tx_reg <= 1'b1;
        tx_busy <= 1'b0;
        tx_shift <= 0;
        tx_bit_count <= 0;
        baud_counter <= 0;
    end else begin
        baud_counter <= baud_counter + 1;
        
        if (!tx_busy && (tx_wptr != tx_rptr)) begin
            // Start transmission
            tx_busy <= 1'b1;
            tx_shift <= tx_fifo[tx_rptr[3:0]];
            tx_rptr <= tx_rptr + 1;
            tx_bit_count <= 0;
            baud_counter <= 0;
            tx_reg <= 1'b0; // Start bit
        end else if (tx_busy && baud_tick) begin
            baud_counter <= 0;
            
            if (tx_bit_count < 8) begin
                // Data bits
                tx_reg <= tx_shift[0];
                tx_shift <= {1'b0, tx_shift[7:1]};
                tx_bit_count <= tx_bit_count + 1;
            end else if (tx_bit_count == 8) begin
                // Stop bit
                tx_reg <= 1'b1;
                tx_bit_count <= tx_bit_count + 1;
            end else begin
                // Transmission complete
                tx_busy <= 1'b0;
            end
        end
    end
end


// RX state machine
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        rx_busy <= 1'b0;
        rx_shift <= 0;
        rx_bit_count <= 0;
    end else begin
        if (!rx_busy && !rx) begin
            // Start bit detected
            rx_busy <= 1'b1;
            rx_bit_count <= 0;
            baud_counter <= baud_divisor / 2; // Sample in middle of bit
        end else if (rx_busy) begin
            baud_counter <= baud_counter + 1;
            
            if (baud_tick) begin
                baud_counter <= 0;
                
                if (rx_bit_count < 8) begin
                    // Sample data bits
                    rx_shift <= {rx, rx_shift[7:1]};
                    rx_bit_count <= rx_bit_count + 1;
                end else if (rx_bit_count == 8) begin
                    // Stop bit
                    if ((rx_wptr - rx_rptr) < FIFO_DEPTH) begin
                        rx_fifo[rx_wptr[3:0]] <= rx_shift;
                        rx_wptr <= rx_wptr + 1;
                    end
                    rx_busy <= 1'b0;
                end
            end
        end
    end
end

assign tx = tx_reg;
assign rts = (tx_wptr - tx_rptr) < (FIFO_DEPTH / 2); // Flow control

// Interrupt generation
assign irq = (imr_reg[0] && (tx_wptr == tx_rptr)) ||        // TX empty
             (imr_reg[1] && ((rx_wptr - rx_rptr) > 0)) ||   // RX available
             (imr_reg[2] && ((tx_wptr - tx_rptr) == 0)) ||  // TX underflow
             (imr_reg[3] && ((rx_wptr - rx_rptr) == FIFO_DEPTH)); // RX overflow

endmodule
