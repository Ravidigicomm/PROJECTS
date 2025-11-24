                                                                                                                         


module SPI_FLASH_READ_ONLY_ASYNC_NO_LATENCY (
    input  wire       cs_n,         // SPI chip select (active low)
    input  wire       sclk,         // SPI clock from master
    input  wire       DI,           // Data input from master (MOSI)
    output reg        DO            // Data output to master (MISO)
);

    // ------------------------------------------------
    // Parameters and FSM State Definitions
    // ------------------------------------------------
    parameter [7:0] READ_CMD = 8'h03;  // Read command

    localparam IDLE         = 3'd0,
               INSTR_SAMPLE = 3'd1,
               ADDR_SAMPLE  = 3'd2,
               DATA_READ    = 3'd3,
               LOAD_NEXT    = 3'd4;

    reg [2:0] state;

    // ------------------------------------------------
    // Registers for rising?edge (FSM & sampling)
    // ------------------------------------------------
    reg [5:0]  bit_count;         // Counter for bits sampled (command or address)
    reg [7:0]  instruction_reg;   // 8-bit instruction register
    reg [23:0] addr_reg;          // 24-bit address register (serially captured)
    reg [23:0] rom_addr;          // ROM address for reading

    // This register is loaded from ROM once the address has been captured.
    // It is then used by the falling?edge block for shifting out bits.
    //reg [7:0] shift_reg;

    // ------------------------------------------------
    // ROM Instance (using a block RAM style attribute)
    // ------------------------------------------------
    reg [7:0] mem [0:1048703];
    initial begin
        $readmemh("mem.mif", mem);
    end
    wire [7:0] rom_data = mem[rom_addr];

    // ------------------------------------------------
    // Flags and counters used by the falling?edge (shift) domain
    // ------------------------------------------------
    reg [2:0] fall_shift_count;  // Counts from 0 to 7 (which bit of shift_reg to output)
    reg       shift_done;        // Flag asserted when a full byte has been shifted out

    // ------------------------------------------------
    // FSM: Rising Edge Domain (sclk)
    // ------------------------------------------------
    // This block samples DI and controls the overall FSM.
    always @(posedge sclk) begin
        if (cs_n) begin
            // Synchronous reset when CS is high
            state           <= IDLE;
            bit_count       <= 6'd0;
            instruction_reg <= 8'd0;
            addr_reg        <= 24'd0;
            rom_addr        <= 24'd0;
            //shift_reg       <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    // Begin a new transaction on falling CS.
                    state           <= INSTR_SAMPLE;
                    bit_count       <= 6'd0;
                    instruction_reg <= 8'd0;
                end

                INSTR_SAMPLE: begin
                    // Sample the 8?bit command (MSB first)
                    instruction_reg <= {instruction_reg[6:0], DI};
                    bit_count       <= bit_count + 1;
                    if (bit_count == 6'd7) begin
                        if (instruction_reg[7:0] == READ_CMD)
                            state <= ADDR_SAMPLE;
                        else
                            state <= IDLE;  // Unknown command, reset FSM.
                        bit_count <= 6'd0;
                    end
                end

                ADDR_SAMPLE: begin
                    // Sample the 24?bit address (MSB first)
                    addr_reg  <= {addr_reg[22:0], DI};
                    bit_count <= bit_count + 1;
                    if (bit_count == 6'd23) begin
                        // Latch full address into ROM address and load ROM data into shift_reg.
                        rom_addr  <= {addr_reg[22:0], DI};
                        //shift_reg <= rom_data;
                        state     <= DATA_READ;
                        bit_count <= 6'd0;
                    end
                end

                DATA_READ: begin
                    // Remain in DATA_READ until falling?edge domain signals the byte is done.
                    if (shift_done)
                        //state <= LOAD_NEXT;
                        rom_addr  <= rom_addr + 24'd1;
                        state     <= DATA_READ;
                end

                /*LOAD_NEXT: begin
                    // Increment ROM address to load next byte.
                    rom_addr  <= rom_addr + 24'd1;
                    //shift_reg <= rom_data;
                    state     <= DATA_READ;
                end*/

                default: state <= IDLE;
            endcase
        end
    end

    // ------------------------------------------------
    // Falling Edge Domain: Data Shifting (using inverted sclk)
    // ------------------------------------------------
    // Generate an inverted clock from sclk. This block runs on the rising edge of sclk_inv,
    // which is equivalent to the falling edge of sclk.
    wire sclk_inv = ~sclk;
    always @(posedge sclk_inv) begin
        if (!cs_n && (state == DATA_READ)) begin
            // Drive DO from the bit selected by the falling?edge counter.
            DO <= rom_data[7 - fall_shift_count];
            fall_shift_count <= fall_shift_count + 1;
            // Once all 8 bits have been output, assert shift_done.
            if (fall_shift_count == 3'd7) begin
                shift_done      <= 1'b1;
                fall_shift_count <= 3'd0;
            end else begin
                shift_done <= 1'b0;
            end
        end else begin
            // When not shifting, drive DO low and clear the falling edge counter.
            DO <= 1'b0;
            fall_shift_count <= 3'd0;
            shift_done <= 1'b0;
        end
    end

endmodule
