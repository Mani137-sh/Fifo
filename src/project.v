/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [15:0] ui_in,    // Dedicated inputs
    output wire [15:0] uo_out,   // Dedicated outputs
    input  wire [15:0] uio_in,   // IOs: Input path
    output wire [15:0] uio_out,  // IOs: Output path
    output wire [15:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       wr_en,
    input  wire       rd_en,
    input  wire       clk,      // clock
    input  wire       rst_n,     // reset_n - low to reset
    output wire       f_full,
    output wire       f_empty,
    output wire       f_almostfull,
    output wire       f_almostempty,
    output wire       f_underrun,
    output wire       f_overrun
);

  // All output pins must be assigned. If not used, assign to 0.
  //assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
    wire _unused = &{ena, uio_in, 1'b0};
    fifo f1(.clk(clk),.resetn(rst_n),.wr_enb(wr_en),.rd_enb(rd_en),.wr_data(ui_in),.rd_data(uo_out),.f_full(f_full),.f_empty(f_empty),.f_almostfull(f_almostfull),.f_almostempty(f_almostempty),.f_underrun(f_underrun),.f_overrun(f_overrun));
endmodule


//8*16 FIFO module
module fifo(clk,resetn,wr_enb,rd_enb,wr_data,rd_data,f_full,f_empty,f_almostfull,f_almostempty,f_underrun,f_overrun);
  input              clk;
  input              resetn;
  input              wr_enb;
  input              rd_enb;
  input      [15:0]  wr_data;
  output reg [15:0]  rd_data;
  output             f_full;
  output             f_empty;
  output             f_almostfull;
  output             f_almostempty;
  output             f_underrun;
  output             f_overrun;
 
  //FIFO size declaration
  reg [15:0]fif[0:7];
 
  //intermediate signal
  reg        [3:0]   occupancy;
  reg        [2:0]   wr_pntr;
  reg        [2:0]   rd_pntr;
  wire               eff_write;
  wire               eff_read;
 
 //flag status signal
  assign f_full=((occupancy==4'd8)?1'b1:1'b0);
  assign f_empty=((occupancy==4'd0)?1'b1:1'b0);
  assign f_almostfull=((occupancy==4'd6)?1'b1:1'b0);
  assign f_almostempty=((occupancy==4'd2)?1'b1:1'b0);
  assign f_underrun=(((rd_enb==1'b1)&&(f_empty==1'b1))?1'b1:1'b0);
  assign f_overrun=(((wr_enb==1'b1)&&(f_full==1'b1))?1'b1:1'b0);
 
 //effective write & read
  assign eff_write=((wr_enb==1'b1)&&(f_full==1'b0))?1'b1:1'b0;
  assign eff_read=((rd_enb==1'b1)&&(f_empty==1'b0))?1'b1:1'b0;
 
 //occupancy
  always@(posedge clk or negedge resetn)
    begin
      if(!resetn)
        occupancy<=4'b0;
      else
        begin
          case({eff_write,eff_read})
            2'b00:occupancy<=occupancy;
            2'b01:occupancy<=occupancy-1'b1;
            2'b10:occupancy<=occupancy+1'b1;
            2'b11:occupancy<=occupancy;
          endcase
        end
    end
 
//updation of write pointer
  always@(posedge clk or negedge resetn)
    begin
      if(!resetn)
        wr_pntr<=3'b0;
      else
        begin
          if(eff_write==1'b1)
            wr_pntr<=wr_pntr+1;
          else
            wr_pntr<=wr_pntr;
        end
    end
 
//updation of read pointer
  always@(posedge clk or negedge resetn)
    begin
      if(!resetn)
        rd_pntr<=3'b0;
      else
        begin
          if(eff_read==1'b1)
            rd_pntr<=rd_pntr+1;
          else
            rd_pntr<=rd_pntr;
        end
    end
 
//write operation
 always@(posedge clk)
    begin
      if(eff_write==1'b1)
        fif[wr_pntr]<=wr_data;
    end
 
//read operation
 always@(posedge clk)
    begin
      if(eff_read==1'b1)
        rd_data<=fif[rd_pntr];
    end
endmodule





