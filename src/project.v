/*
 * Copyright (c) 2024 Mani Rani
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_fifo (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // FIFO interface
    wire write_enable = ui_in[0];  // Write enable (use LSB of ui_in)
    wire read_enable  = ui_in[1];  // Read enable (use next bit of ui_in)
    wire [7:0] data_in = ui_in;    // Data to be written into the FIFO
    wire [7:0] data_out;           // Data read from the FIFO

    fifo #(
        .DEPTH(256)               // FIFO depth (number of locations)
    ) fifo_inst (
        .clk(clk),
        .rst(!rst_n),             // Reset (active high in the FIFO)
        .write_enable(write_enable),
        .read_enable(read_enable),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Assign outputs
    assign uo_out  = data_out;   // Drive output with FIFO read data
    assign uio_out = 8'b0;       // Unused in this example
    assign uio_oe  = 8'b0;       // All IOs in input mode (not used)

    // Prevent warnings for unused inputs
    wire _unused = &{uio_in, 1'b0};

endmodule

module fifo #(
    parameter DEPTH = 256       // FIFO depth
) (
    input wire        clk,
    input wire        rst,
    input wire        write_enable,
    input wire        read_enable,
    input wire [7:0]  data_in,
    output reg [7:0]  data_out
);

    reg [7:0] mem [0:DEPTH-1];   // Memory buffer
    reg [$clog2(DEPTH)-1:0] write_ptr; // Write pointer
    reg [$clog2(DEPTH)-1:0] read_ptr;  // Read pointer
    reg [$clog2(DEPTH):0] fifo_count;  // Number of elements in FIFO

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all pointers and counters
            write_ptr <= 0;
            read_ptr <= 0;
            fifo_count <= 0;
        end else begin
            // Write logic
            if (write_enable && fifo_count < DEPTH) begin
                mem[write_ptr] <= data_in;
                write_ptr <= write_ptr + 1;
                fifo_count <= fifo_count + 1;
            end

            // Read logic
            if (read_enable && fifo_count > 0) begin
                data_out <= mem[read_ptr];
                read_ptr <= read_ptr + 1;
                fifo_count <= fifo_count - 1;
            end
        end
    end
endmodule
