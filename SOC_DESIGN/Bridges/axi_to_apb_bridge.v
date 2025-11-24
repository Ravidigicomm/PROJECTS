`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.08.2023 23:41:33
// Design Name: 
// Module Name: bridge
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module axi_to_apb_bridge #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH = 4
) (
    input wire clk,
    input wire resetn,
    
    // AXI4-Lite Interface (simplified)
    input wire axi_awvalid,
    output wire axi_awready,
    input wire [ADDR_WIDTH-1:0] axi_awaddr,
    input wire [2:0] axi_awprot,
    input wire [ID_WIDTH-1:0] axi_awid,
    
    input wire axi_wvalid,
    output wire axi_wready,
    input wire [DATA_WIDTH-1:0] axi_wdata,
    input wire [(DATA_WIDTH/8)-1:0] axi_wstrb,
    
    output wire axi_bvalid,
    input wire axi_bready,
    output wire [1:0] axi_bresp,
    output wire [ID_WIDTH-1:0] axi_bid,
    
    input wire axi_arvalid,
    output wire axi_arready,
    input wire [ADDR_WIDTH-1:0] axi_araddr,
    input wire [2:0] axi_arprot,
    input wire [ID_WIDTH-1:0] axi_arid,
    
    output wire axi_rvalid,
    input wire axi_rready,
    output wire [DATA_WIDTH-1:0] axi_rdata,
    output wire [1:0] axi_rresp,
    output wire [ID_WIDTH-1:0] axi_rid,
    
    // APB4 Interface
    output wire apb_psel,
    output wire apb_penable,
    output wire apb_pwrite,
    output wire [ADDR_WIDTH-1:0] apb_paddr,
    output wire [DATA_WIDTH-1:0] apb_pwdata,
    input wire [DATA_WIDTH-1:0] apb_prdata,
    input wire apb_pready,
    input wire apb_pslverr
);

// State machine states
typedef enum logic [2:0] {
    IDLE,
    SETUP,
    ACCESS,
    WAIT_RESP,
    ERROR
} state_t;

state_t current_state, next_state;

// Internal registers
reg [ADDR_WIDTH-1:0] addr_reg;
reg [DATA_WIDTH-1:0] wdata_reg;
reg [DATA_WIDTH-1:0] rdata_reg;
reg [ID_WIDTH-1:0] id_reg;
reg write_op;
reg error_flag;

// State machine
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

// Next state logic
always @(*) begin
    case (current_state)
        IDLE: begin
            if (axi_awvalid || axi_arvalid) begin
                next_state = SETUP;
            end else begin
                next_state = IDLE;
            end
        end
        SETUP: next_state = ACCESS;
        ACCESS: begin
            if (apb_pready) begin
                if (apb_pslverr) begin
                    next_state = ERROR;
                end else begin
                    next_state = WAIT_RESP;
                end
            end else begin
                next_state = ACCESS;
            end
        end
        WAIT_RESP: next_state = IDLE;
        ERROR: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

// Control signals
assign axi_awready = (current_state == IDLE) && axi_awvalid;
assign axi_arready = (current_state == IDLE) && axi_arvalid && !axi_awvalid;
assign axi_wready = (current_state == SETUP) && write_op;
assign axi_bvalid = (current_state == WAIT_RESP) && write_op;
assign axi_rvalid = (current_state == WAIT_RESP) && !write_op;

assign apb_psel = (current_state == SETUP) || (current_state == ACCESS);
assign apb_penable = (current_state == ACCESS);
assign apb_pwrite = write_op;
assign apb_paddr = addr_reg;
assign apb_pwdata = wdata_reg;

// Response generation
assign axi_bresp = error_flag ? 2'b10 : 2'b00;
assign axi_rresp = error_flag ? 2'b10 : 2'b00;
assign axi_bid = id_reg;
assign axi_rid = id_reg;
assign axi_rdata = rdata_reg;

// Register updates
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        addr_reg <= 0;
        wdata_reg <= 0;
        rdata_reg <= 0;
        id_reg <= 0;
        write_op <= 0;
        error_flag <= 0;
    end else begin
        case (current_state)
            IDLE: begin
                if (axi_awvalid) begin
                    addr_reg <= axi_awaddr;
                    id_reg <= axi_awid;
                    write_op <= 1'b1;
                end else if (axi_arvalid) begin
                    addr_reg <= axi_araddr;
                    id_reg <= axi_arid;
                    write_op <= 1'b0;
                end
            end
            SETUP: begin
                if (write_op) begin
                    wdata_reg <= axi_wdata;
                end
            end
            ACCESS: begin
                if (apb_pready) begin
                    rdata_reg <= apb_prdata;
                    error_flag <= apb_pslverr;
                end
            end
        endcase
    end
end

endmodule
