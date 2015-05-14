//Copyright (c) 2015 Ken Taylor
// File tft_ctrl.v originally from https://github.com/kwtaylor/pockelizer
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

module tft_ctrl #( parameter DLY_WIDTH = 23 )(
    input clk,
    input arstn,
    
    //spi interface
    output sclk,
    output mosi,
    output reg csn,
    output reg dcn,
    
    input init,
    input draw,
    
    output reg busy,
    output reg done,
    
    // draw command parameters
    input [15:0] color, // rrrr rggg gggb bbbb
    input [15:0] xstart,
    input [15:0] xend,
    input [15:0] ystart,
    input [15:0] yend,
    
    // optional interface for blitting
    // (change color input based on curx,cury)
    output reg [15:0] curx,
    output reg [15:0] cury,
    output reg cnext // latch next color
    
);

    reg [15:0] color_r;
    reg [15:0] xstart_r;
    reg [15:0] xend_r;
    reg [15:0] ystart_r;
    reg [15:0] yend_r;

    reg spi_go = 0;
    wire spi_done;
    wire [7:0] spi_data;
    
    simple_spi spi (
        .clk(clk),
        .arstn(arstn),
        .sclk(sclk),
        .mosi(mosi),
        .go(spi_go),
        .done(spi_done),
        .data_in(spi_data)
    );
    
    //////////////////////////////////
    // command data
    //////////////////////////////////

    // tftdef.vi fills wire [9:0] screen_init [99:0] with initialize sequence
`include "tftdef.vi"

    reg [7:0] step;
    
    reg colordone;
    reg [8:0] color_cmds;
    wire initdone = screen_init[step] == 0;
    wire dly = screen_init[step][9];

    //////////////////////////////////
    // color command writer
    //////////////////////////////////
    
    always @(*) begin
        colordone = 1'b0;
        color_cmds = 0;
        case(step)
            0:  color_cmds = {1'b0, `ILI9341_CASET};
            1:  color_cmds = {1'b1, xstart_r[15:8]}; 
            2:  color_cmds = {1'b1, xstart_r[7:0]}; 
            3:  color_cmds = {1'b1, xend_r[15:8]}; 
            4:  color_cmds = {1'b1, xend_r[7:0]}; 
            5:  color_cmds = {1'b0, `ILI9341_PASET};
            6:  color_cmds = {1'b1, ystart_r[15:8]}; 
            7:  color_cmds = {1'b1, ystart_r[7:0]}; 
            8:  color_cmds = {1'b1, yend_r[15:8]}; 
            9:  color_cmds = {1'b1, yend_r[7:0]}; 
            10: color_cmds = {1'b0, `ILI9341_RAMWR}; 
            11: colordone = 1'b1;
            default: ;
        endcase
    end
    
    //////////////////////////////////
    // main state machine
    //////////////////////////////////
    
    localparam IDLE      = 3'd0;
    localparam INIT      = 3'd1;
    localparam INITDLY   = 3'd2;
    localparam COLORCMD  = 3'd3;
    localparam COLORDAT  = 3'd4;
    localparam DONEDLY   = 3'd5;
    
    reg [2:0] state = IDLE;
    
    reg cnt_clr;
    reg [DLY_WIDTH-1:0] dly_cnt;
    
    always @(posedge clk)
        if(cnt_clr) dly_cnt <= 0;
        else dly_cnt <= dly_cnt + 1;
        
    wire max_cnt = &dly_cnt;
    
    always @(posedge clk or negedge arstn) begin
        if(~arstn) begin
            csn <= 1'b1;
            busy <= 1'b0;
            done <= 1'b0;
            cnt_clr <= 1'b1;
            cnext <= 1'b0;
            state <= IDLE;
            step <= 0;
            curx <= 0;
            cury <= 0;
            spi_go <= 1'b0;
        end else begin
            //defaults
            csn <= 1'b1;
            busy <= 1'b0;
            done <= 1'b0;
            cnt_clr <= 1'b1;
            cnext <= 1'b0;
            
            case(state)
                IDLE: begin
                    step <= 0;
                    curx <= 0;
                    cury <= 0;
                    spi_go <= 1'b0;
                    
                    if(init) begin
                        state <= INIT;
                        spi_go <= 1'b1;
                        busy <= 1'b1;
                    end else if(draw) begin
                        state <= COLORCMD;
                        spi_go <= 1'b1;
                        busy <= 1'b1;
                        xstart_r <= xstart;
                        ystart_r <= ystart;
                        xend_r <= xend;
                        yend_r <= yend;
                    end
                end
                
                INIT: begin
                    csn <= 1'b0;
                    busy <= 1'b1;
                    
                    if(initdone) begin
                        if(spi_done) begin
                            state <= DONEDLY;
                            done <= 1'b1;
                        end
                    end else begin // handshake and increment
                        if(spi_done && !spi_go) begin
                            spi_go <= 1'b1;
                        end else if(spi_go && !spi_done) begin 
                            step <= step + 1;
                            spi_go <= 1'b0;
                            if(dly) state <= INITDLY;
                        end
                    end
                end
                
                INITDLY: begin
                    csn <= 1'b0;
                    busy <= 1'b1;
                    spi_go <= 1'b0;
                    
                    if(spi_done) cnt_clr <= 1'b0;
                    
                    if(max_cnt) begin
                        state <= INIT;
                        spi_go <= 1'b1;
                    end
                
                end
                
                COLORCMD: begin
                    csn <= 1'b0;
                    busy <= 1'b1;
                    
                    curx <= xstart_r;
                    cury <= ystart_r;
                    
                    if(colordone) begin
                        if(spi_done) begin
                            state <= COLORDAT;
                            spi_go <= 1'b1;
                            color_r <= color;
                            cnext <= 1'b1;
                            step <= 0;
                        end
                    end else begin // handshake and increment
                        if(spi_done && !spi_go) begin
                            spi_go <= 1'b1;
                        end else if(spi_go && !spi_done) begin 
                            step <= step + 1;
                            spi_go <= 1'b0;
                        end
                    end
                end
                
                COLORDAT: begin
                    csn <= 1'b0;
                    busy <= 1'b1;
                    
                    if(cury > yend_r) begin
                        if(spi_done) begin
                            state <= DONEDLY;
                            done <= 1'b1;
                        end
                    end else begin // handshake and increment
                        if(spi_done && !spi_go) begin
                            spi_go <= 1'b1;
                        end else if(spi_go && !spi_done) begin 
                            if(step == 1) begin
                                curx <= curx + 1;
                                if(curx == xend_r) begin
                                    curx <= xstart_r;
                                    cury <= cury + 1;
                                end
                                color_r <= color;
                                cnext <= 1'b1;
                                step <= 0;
                            end else step <= step + 1;
                            spi_go <= 1'b0;
                        end
                    end
                end
                
                DONEDLY: begin
                    spi_go <= 1'b0;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    //////////////////////////////////
    // command selector
    //////////////////////////////////
    
    always @(posedge clk)
        if(spi_done && spi_go) // latch new DCn
            dcn <= (state == INIT) ? screen_init[step][8] :
                   (state == COLORCMD) ? color_cmds[8] : 
                   1'b1;
    
    assign spi_data = (state == INIT) ? screen_init[step][7:0] :
                      (state == COLORCMD) ? color_cmds[7:0] : 
                      (step == 0) ? color_r[15:8] : color_r[7:0];


endmodule
