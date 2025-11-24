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
module axi_to_ahb_bridge #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH = 4
) (
    input wire clk,
    input wire resetn,
    
    // AXI4 Interface
    input wire axi_awvalid,
    output wire axi_awready,
    input wire [ADDR_WIDTH-1:0] axi_awaddr,
    input wire [7:0] axi_awlen,
    input wire [2:0] axi_awsize,
    input wire [1:0] axi_awburst,
    input wire [ID_WIDTH-1:0] axi_awid,
    
    // ... Other AXI signals
    
    // AHB3 Interface
    output wire ahb_hsel,
    output wire [ADDR_WIDTH-1:0] ahb_haddr,
    output wire ahb_hwrite,
    output wire [2:0] ahb_hsize,
    output wire [1:0] ahb_htrans,
    output wire [DATA_WIDTH-1:0] ahb_hwdata,
    input wire [DATA_WIDTH-1:0] ahb_hrdata,
    input wire ahb_hready,
    input wire ahb_hresp
);

// State machine and control logic
typedef enum logic [2:0] {
    IDLE,
    ADDR_PHASE,
    DATA_PHASE,
    RESP_PHASE,
    ERROR
} ahb_state_t;

ahb_state_t current_state, next_state;

// Burst support registers
reg [7:0] burst_count;
reg [ADDR_WIDTH-1:0] base_addr;
reg [1:0] burst_type;

// Control logic
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        current_state <= IDLE;
        burst_count <= 0;
        base_addr <= 0;
        burst_type <= 0;
    end else begin
        current_state <= next_state;
        
        if (axi_awvalid && axi_awready) begin
            burst_count <= axi_awlen;
            base_addr <= axi_awaddr;
            burst_type <= axi_awburst;
        end
    end
end

// Next state logic
always @(*) begin
    case (current_state)
        IDLE: next_state = (axi_awvalid) ? ADDR_PHASE : IDLE;
        ADDR_PHASE: next_state = DATA_PHASE;
        DATA_PHASE: next_state = (ahb_hready && (burst_count == 0)) ? RESP_PHASE : DATA_PHASE;
        RESP_PHASE: next_state = IDLE;
        ERROR: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

// AHB control signals
assign ahb_hsel = (current_state == ADDR_PHASE) || (current_state == DATA_PHASE);
assign ahb_htrans = (current_state == ADDR_PHASE) ? 2'b10 : 
                   ((current_state == DATA_PHASE) ? 2'b11 : 2'b00);
assign ahb_hwrite = (current_state != IDLE); // Simplified
assign ahb_haddr = calculate_next_addr(base_addr, burst_count, burst_type);
assign ahb_hsize = axi_awsize; // Pass through

// Address calculation for bursts
function [ADDR_WIDTH-1:0] calculate_next_addr;
    input [ADDR_WIDTH-1:0] base;
    input [7:0] count;
    input [1:0] burst;
    begin
        case (burst)
            2'b00: calculate_next_addr = base; // FIXED
            2'b01: calculate_next_addr = base + (count << axi_awsize); // INCR
            2'b10: calculate_next_addr = wrap_address(base, count, axi_awsize, axi_awlen); // WRAP
            default: calculate_next_addr = base;
        endcase
    end
endfunction

endmodule
