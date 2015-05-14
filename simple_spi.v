//Copyright (c) 2015 Ken Taylor
// File simple_spi.v originally from https://github.com/kwtaylor/pockelizer
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in
//all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//THE SOFTWARE.

// Simple SPI-based control for the Adafruit ILI9341 Breakout and Shield display

module simple_spi #(
    parameter CLK_DIV = 2, // if clk is 50Mhz, 2 will produce ~8.3Mhz
    parameter CLK_DIV_BITS = 2
) (
    input clk,
    input arstn,
    
    // chip select is controlled externally
    // no read right now, only write
    output reg sclk,
    output mosi,
    
    input go,
    output reg done = 1'b1,
    input [7:0] data_in
);

reg [2:0] dbit = 2'b0;
reg [7:0] shift_reg;
reg [CLK_DIV_BITS-1:0] cnt;

assign mosi = shift_reg[7];

always @(posedge clk or negedge arstn) begin
    if(~arstn) begin
        done <= 1'b1;
        dbit <= 2'b0;
        shift_reg <= 8'b0;
    end else if(!done) begin
        if(cnt == CLK_DIV) begin
            cnt <= 0;
            sclk <= ~sclk;
            if(sclk) begin // falling edge, update data bit
                shift_reg <= {shift_reg[6:0], 1'b0};
                dbit <= dbit-1;
                if(dbit == 0) done <= 1'b1;
            end
        end else
            cnt <= cnt+1;
    end else if(go) begin
        dbit <= 3'd7;
        shift_reg <= data_in;
        done <= 1'b0;
        cnt <= 0;
        sclk <= 1'b0;
    end
end

endmodule
