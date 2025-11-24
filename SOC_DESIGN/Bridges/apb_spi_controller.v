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
module apb_spi_controller #(
    parameter APB_ADDR_WIDTH = 8,
    parameter APB_DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 8
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
    
    // SPI Interface
    output wire                    sck,
    output wire                    mosi,
    input wire                     miso,
    output wire [3:0]              cs_n,
    output wire                    irq
);

// SPI Register Map
localparam SPI_CR     = 8'h00; // Control Register
localparam SPI_SR     = 8'h04; // Status Register
localparam SPI_DR     = 8'h08; // Data Register
localparam SPI_BAUD   = 8'h0C; // Baud Rate Register
localparam SPI_CSR    = 8'h10; // Chip Select Register
localparam SPI_FCR    = 8'h14; // FIFO Control
localparam SPI_FSR    = 8'h18; // FIFO Status
localparam SPI_IMR    = 8'h1C; // Interrupt Mask
localparam SPI_ISR    = 8'h20; // Interrupt Status

// Control Register bits
localparam CR_EN      = 0;     // SPI Enable
localparam CR_MS      = 1;     // Master/Slave mode
localparam CR_CPOL    = 2;     // Clock polarity
localparam CR_CPHA    = 3;     // Clock phase
localparam CR_LSBF    = 4;     // LSB first
localparam CR_TXIE    = 5;     // TX interrupt enable
localparam CR_RXIE    = 6;     // RX interrupt enable

// Status Register bits
localparam SR_TXE     = 0;     // TX empty
localparam SR_RXF     = 1;     // RX full
localparam SR_BSY     = 2;     // Busy

// Internal registers
reg [APB_DATA_WIDTH-1:0] cr_reg;
reg [APB_DATA_WIDTH-1:0] sr_reg;
reg [APB_DATA_WIDTH-1:0] baud_reg;
reg [APB_DATA_WIDTH-1:0] csr_reg;
reg [APB_DATA_WIDTH-1:0] imr_reg;

// FIFO signals
reg [7:0] tx_fifo [0:FIFO_DEPTH-1];
reg [7:0] rx_fifo [0:FIFO_DEPTH-1];
reg [3:0] tx_wptr, tx_rptr;
reg [3:0] rx_wptr, rx_rptr;

// SPI signals
reg sck_reg;
reg mosi_reg;
reg [3:0] cs_n_reg;
reg [7:0] shift_reg;
reg [3:0] bit_count;
reg [15:0] baud_counter;

// SPI state machine
typedef enum logic [1:0] {
    SPI_IDLE,
    SPI_ACTIVE,
    SPI_COMPLETE
} spi_state_t;

spi_state_t current_state;

assign pready = 1'b1;
assign pslverr = 1'b0;

// Register read
always @(*) begin
    prdata = {APB_DATA_WIDTH{1'b0}};
    if (psel && penable && !pwrite) begin
        case (paddr)
            SPI_CR:    prdata = cr_reg;
            SPI_SR:    prdata = sr_reg;
            SPI_DR:    prdata = {24'h0, rx_fifo[rx_rptr[2:0]]};
            SPI_BAUD:  prdata = baud_reg;
            SPI_CSR:   prdata = csr_reg;
            SPI_FSR:   prdata = {24'h0, tx_wptr - tx_rptr, rx_wptr - rx_rptr};
            SPI_IMR:   prdata = imr_reg;
            SPI_ISR:   prdata = {31'h0, irq};
            default:   prdata = {APB_DATA_WIDTH{1'b0}};
        endcase
    end
end

// Register write
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        cr_reg <= 0;
        baud_reg <= 16'd100;
        csr_reg <= 4'hF; // All CS high initially
        imr_reg <= 0;
        tx_wptr <= 0;
        tx_rptr <= 0;
        rx_wptr <= 0;
        rx_rptr <= 0;
        current_state <= SPI_IDLE;
    end else if (psel && penable && pwrite) begin
        case (paddr)
            SPI_CR:    cr_reg <= pwdata;
            SPI_DR: begin
                if ((tx_wptr - tx_rptr) < FIFO_DEPTH) begin
                    tx_fifo[tx_wptr[2:0]] <= pwdata[7:0];
                    tx_wptr <= tx_wptr + 1;
                end
            end
            SPI_BAUD:  baud_reg <= pwdata;
            SPI_CSR:   csr_reg <= pwdata;
            SPI_IMR:   imr_reg <= pwdata;
        endcase
    end
    
    // Update status
    sr_reg[SR_TXE] <= (tx_wptr == tx_rptr);
    sr_reg[SR_RXF] <= ((rx_wptr - rx_rptr) > 0);
    sr_reg[SR_BSY] <= (current_state != SPI_IDLE);
end

// SPI clock generation and data transfer
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        sck_reg <= cr_reg[CR_CPOL];
        mosi_reg <= 1'b0;
        cs_n_reg <= 4'hF;
        shift_reg <= 0;
        bit_count <= 0;
        baud_counter <= 0;
    end else begin
        baud_counter <= baud_counter + 1;
        
        case (current_state)
            SPI_IDLE: begin
                sck_reg <= cr_reg[CR_CPOL];
                cs_n_reg <= 4'hF;
                if (tx_wptr != tx_rptr) begin
                    current_state <= SPI_ACTIVE;
                    cs_n_reg <= ~csr_reg[3:0]; // Activate CS
                    shift_reg <= tx_fifo[tx_rptr[2:0]];
                    tx_rptr <= tx_rptr + 1;
                    bit_count <= 0;
                    baud_counter <= 0;
                end
            end
            
            SPI_ACTIVE: begin
                if (baud_counter == baud_reg) begin
                    baud_counter <= 0;
                    sck_reg <= ~sck_reg;
                    
                    if (sck_reg != cr_reg[CR_CPHA]) begin
                        // Sample MISO on appropriate clock edge
                        if (bit_count < 8) begin
                            shift_reg <= {shift_reg[6:0], miso};
                            mosi_reg <= shift_reg[7];
                            bit_count <= bit_count + 1;
                        end else begin
                            // Store received data
                            if ((rx_wptr - rx_rptr) < FIFO_DEPTH) begin
                                rx_fifo[rx_wptr[2:0]] <= shift_reg;
                                rx_wptr <= rx_wptr + 1;
                            end
                            current_state <= SPI_COMPLETE;
                        end
                    end
                end
            end
            
            SPI_COMPLETE: begin
                cs_n_reg <= 4'hF;
                current_state <= SPI_IDLE;
            end
        endcase
    end
end

assign sck = sck_reg;
assign mosi = mosi_reg;
assign cs_n = cs_n_reg;

// Interrupt generation
assign irq = (imr_reg[0] && (tx_wptr == tx_rptr)) || // TX empty
             (imr_reg[1] && ((rx_wptr - rx_rptr) > 0)); // RX available

endmodule

