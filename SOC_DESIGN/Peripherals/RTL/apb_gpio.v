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
module apb_gpio #(
    parameter APB_ADDR_WIDTH = 8,
    parameter APB_DATA_WIDTH = 32,
    parameter NUM_GPIO = 32
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
    
    // GPIO Interface
    input wire [NUM_GPIO-1:0]      gpio_i,
    output reg [NUM_GPIO-1:0]      gpio_o,
    output reg [NUM_GPIO-1:0]      gpio_oe,
    output wire                    irq
);

// GPIO Register Address Map
localparam GPIO_DATA  = 8'h00; // Data Register
localparam GPIO_DIR   = 8'h04; // Direction Register
localparam GPIO_IMR   = 8'h08; // Interrupt Mask Register
localparam GPIO_ISR   = 8'h0C; // Interrupt Status Register
localparam GPIO_IER   = 8'h10; // Interrupt Edge Register
localparam GPIO_ICR   = 8'h14; // Interrupt Clear Register

// Internal registers
reg [NUM_GPIO-1:0] data_reg;
reg [NUM_GPIO-1:0] dir_reg;
reg [NUM_GPIO-1:0] imr;
reg [NUM_GPIO-1:0] isr;
reg [NUM_GPIO-1:0] ier; // 0: level, 1: edge
reg [NUM_GPIO-1:0] last_gpio;

// Edge detection
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        last_gpio <= {NUM_GPIO{1'b0}};
        isr <= {NUM_GPIO{1'b0}};
    end else begin
        last_gpio <= gpio_i;
        
        // Edge detection
        for (int i = 0; i < NUM_GPIO; i++) begin
            if (ier[i]) begin
                // Edge sensitive
                if ((gpio_i[i] && !last_gpio[i]) || // Rising edge
                    (!gpio_i[i] && last_gpio[i]))   // Falling edge
                begin
                    isr[i] <= 1'b1;
                end
            end else begin
                // Level sensitive
                isr[i] <= gpio_i[i];
            end
        end
    end
end

// GPIO output
always @(*) begin
    for (int i = 0; i < NUM_GPIO; i++) begin
        gpio_o[i] = data_reg[i];
        gpio_oe[i] = dir_reg[i];
    end
end

// APB interface
assign pready = 1'b1;
assign pslverr = 1'b0;

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        prdata <= 32'h0;
        data_reg <= {NUM_GPIO{1'b0}};
        dir_reg <= {NUM_GPIO{1'b0}};
        imr <= {NUM_GPIO{1'b0}};
        ier <= {NUM_GPIO{1'b0}};
    end else if (psel && penable && !pwrite) begin
        case (paddr[7:0])
            GPIO_DATA:  prdata <= gpio_i;
            GPIO_DIR:   prdata <= dir_reg;
            GPIO_IMR:   prdata <= imr;
            GPIO_ISR:   prdata <= isr;
            GPIO_IER:   prdata <= ier;
            default:    prdata <= 32'hDEADBEEF;
        endcase
    end else if (psel && penable && pwrite) begin
        case (paddr[7:0])
            GPIO_DATA:  data_reg <= pwdata[NUM_GPIO-1:0];
            GPIO_DIR:   dir_reg <= pwdata[NUM_GPIO-1:0];
            GPIO_IMR:   imr <= pwdata[NUM_GPIO-1:0];
            GPIO_IER:   ier <= pwdata[NUM_GPIO-1:0];
            GPIO_ICR:   isr <= isr & ~pwdata[NUM_GPIO-1:0];
        endcase
    end
end

// Interrupt generation
assign irq = |(isr & imr);

endmodule

