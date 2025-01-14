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
     // All output pins must be assigned. If not used, assign to 0.
  //assign uo_out  = 0;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
    wire _unused = &{uio_in[7:1], 1'b0};

 
    fifo fifo_inst (
        .clk(clk),
        .rst(!rst_n),             // Reset (active high in the FIFO)
        .write_enable(ena),
        .read_enable(uio_in[0]),
        .data_in(ui_in),
        .data_out(uo_out)
    );

  

endmodule

module fifo  (
    input wire        clk,
    input wire        rst,
    input wire        write_enable,
    input wire        read_enable,
    input wire [7:0]  data_in,
    output reg [7:0]  data_out
);

    reg [7:0] mem [0:3];   // Memory buffer
    reg [1:0] write_ptr; // Write pointer
    reg [1:0] read_ptr;  // Read pointer
    reg [2:0] fifo_count;  // Number of elements in FIFO

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all pointers and counters
            write_ptr <= 0;
            read_ptr <= 0;
            fifo_count <= 0;
        end else begin
            // Write logic
            if (write_enable && fifo_count < 4) begin
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
