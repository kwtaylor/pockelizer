// encapsulates all the buttons in the gui
module gui
(
    input clk,
    input arstn,
    
    // touch input
    input touch,
    input [15:0] touchx, // these need to be in screen coordinates
    input [15:0] touchy,
    
    // drawing interface
    output update, // needs drawing update
    input draw,
    output reg tft_draw,
    input cnext,
    input tft_done,
    output reg drawdone,
    
    output [15:0] xstart,
    output [15:0] xend,
    output [15:0] ystart,
    output [15:0] yend,
    output [15:0] color,
    
    // button states
    output start_state, // 0=pause, 1=go
    input start_rst,
    output left_touched,
    output right_touched,
    output [2:0] clock_state
);
    localparam BMPWIDTH = 20;
    localparam BMPHEIGHT = 20;
    localparam BMPBITS = 1;
    
    wire [BMPBITS-1:0] bmpregin;

    wire [15:0] start_xstart;
    wire [15:0] start_xend;
    wire [15:0] start_ystart;
    wire [15:0] start_yend;
    wire [15:0] start_color;
    
    reg start_draw;
    wire start_update;
    wire [0:BMPWIDTH*BMPHEIGHT*BMPBITS-1] start_bmpout;
    wire start_load;
    wire start_shift;
    
    button #(
        .XSTART(10),
        .YSTART(110),
        .WIDTH(40),
        .HEIGHT(40),
        
        .XBMP(10),
        .YBMP(10),
        .BMPWIDTH(BMPWIDTH),
        .BMPHEIGHT(BMPHEIGHT),
        .BMPBITS(BMPBITS),
        
        .NUMSTATES(2),
        .STATEBITS(1)
    ) start (
        .clk(clk),
        .arstn(arstn),
        
        // touch input
        .touch(touch),
        .touchx(touchx),// screen coordinates
        .touchy(touchy),
        
        .touched(),
        .state(start_state),
        .rst_state(start_rst),
        
        // drawing interface
        .update(start_update), // needs drawing update
        .draw(start_draw),
        .cnext(cnext),
        .drawdone(),
        
        .xstart(start_xstart),
        .xend  (start_xend),
        .ystart(start_ystart),
        .yend  (start_yend),
        .color (start_color),
        
        .bmpregout(start_bmpout),
        .bmpregin(bmpregin),
        .bmpreg_load(start_load),
        .bmpreg_shift(start_shift),
        
        // bitmap (columns are x (width), rows are y (height) then state 0, 1, 2, etc
        .bmp({20'b00000000000000000000,
              20'b11111111111111111110,
              20'b10000000000000000010,
              20'b01000000000000000100,
              20'b01000000000000000100,
              20'b00100000000000001000,
              20'b00100000000000001000,
              20'b00010000000000010000,
              20'b00010000000000010000,
              20'b00001000000000100000,
              20'b00001000000000100000,
              20'b00000100000001000000,
              20'b00000100000001000000,
              20'b00000010000010000000,
              20'b00000010000010000000,
              20'b00000001000100000000,
              20'b00000001000100000000,
              20'b00000000101000000000,
              20'b00000000101000000000,
              20'b00000000010000000000,
              
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00111111111111110000,
              20'b00111111111111110000,
              20'b00111111111111110000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00111111111111110000,
              20'b00111111111111110000,
              20'b00111111111111110000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000})
    );
    

    wire [15:0] left_xstart;
    wire [15:0] left_xend;
    wire [15:0] left_ystart;
    wire [15:0] left_yend;
    wire [15:0] left_color;
    
    reg  left_draw;
    wire left_update;
    wire [0:BMPWIDTH*BMPHEIGHT*BMPBITS-1] left_bmpout;
    wire left_load;
    wire left_shift;
    
    button #(
        .XSTART(10),
        .YSTART(60),
        .WIDTH(40),
        .HEIGHT(40),
        
        .XBMP(10),
        .YBMP(10),
        .BMPWIDTH(BMPWIDTH),
        .BMPHEIGHT(BMPHEIGHT),
        .BMPBITS(BMPBITS),
        
        .NUMSTATES(1),
        .STATEBITS(1)
    ) left (
        .clk(clk),
        .arstn(arstn),
        
        // touch input
        .touch(touch),
        .touchx(touchx),// screen coordinates
        .touchy(touchy),
        
        .touched(left_touched),
        .state(),
        .rst_state(1'b0),
        
        // drawing interface
        .update(left_update), // needs drawing update
        .draw(left_draw),
        .cnext(cnext),
        .drawdone(),
        
        .xstart(left_xstart),
        .xend  (left_xend),
        .ystart(left_ystart),
        .yend  (left_yend),
        .color (left_color),
        
        .bmpregout(left_bmpout),
        .bmpregin(bmpregin),
        .bmpreg_load(left_load),
        .bmpreg_shift(left_shift),
        
        // bitmap (columns are x (width), rows are y (height) then state 0, 1, 2, etc
        .bmp({20'b00000000010000000000,
              20'b00000000101000000000,
              20'b00000001000100000000,
              20'b00000010000010000000,
              20'b00000100000001000000,
              20'b00001000000000100000,
              20'b00010000000000010000,
              20'b00100000000000001000,
              20'b01000000000000000100,
              20'b10000000000000000010,
              20'b00000000010000000000,
              20'b00000000101000000000,
              20'b00000001000100000000,
              20'b00000010000010000000,
              20'b00000100000001000000,
              20'b00001000000000100000,
              20'b00010000000000010000,
              20'b00100000000000001000,
              20'b01000000000000000100,
              20'b10000000000000000010})
    );
    
    wire [15:0] right_xstart;
    wire [15:0] right_xend;
    wire [15:0] right_ystart;
    wire [15:0] right_yend;
    wire [15:0] right_color;
    
    reg  right_draw;
    wire right_update;
    wire [0:BMPWIDTH*BMPHEIGHT*BMPBITS-1] right_bmpout;
    wire right_load;
    wire right_shift;
    
    button #(
        .XSTART(10),
        .YSTART(260),
        .WIDTH(40),
        .HEIGHT(40),
        
        .XBMP(10),
        .YBMP(10),
        .BMPWIDTH(BMPWIDTH),
        .BMPHEIGHT(BMPHEIGHT),
        .BMPBITS(BMPBITS),
        
        .NUMSTATES(1),
        .STATEBITS(1)
    ) right (
        .clk(clk),
        .arstn(arstn),
        
        // touch input
        .touch(touch),
        .touchx(touchx),// screen coordinates
        .touchy(touchy),
        
        .touched(right_touched),
        .state(),
        .rst_state(1'b0),
        
        // drawing interface
        .update(right_update), // needs drawing update
        .draw(right_draw),
        .cnext(cnext),
        .drawdone(),
        
        .xstart(right_xstart),
        .xend  (right_xend),
        .ystart(right_ystart),
        .yend  (right_yend),
        .color (right_color),
        
        .bmpregout(right_bmpout),
        .bmpregin(bmpregin),
        .bmpreg_load(right_load),
        .bmpreg_shift(right_shift),
        
        // bitmap (columns are x (width), rows are y (height) then state 0, 1, 2, etc
        .bmp({20'b10000000000000000010,
              20'b01000000000000000100,
              20'b00100000000000001000,
              20'b00010000000000010000,
              20'b00001000000000100000,
              20'b00000100000001000000,
              20'b00000010000010000000,
              20'b00000001000100000000,
              20'b00000000101000000000,
              20'b00000000010000000000,
              20'b10000000000000000010,
              20'b01000000000000000100,
              20'b00100000000000001000,
              20'b00010000000000010000,
              20'b00001000000000100000,
              20'b00000100000001000000,
              20'b00000010000010000000,
              20'b00000001000100000000,
              20'b00000000101000000000,
              20'b00000000010000000000})
    );
    
    wire [15:0] clock_xstart;
    wire [15:0] clock_xend;
    wire [15:0] clock_ystart;
    wire [15:0] clock_yend;
    wire [15:0] clock_color;
    
    reg  clock_draw;
    wire clock_update;
    wire [0:BMPWIDTH*BMPHEIGHT*BMPBITS-1] clock_bmpout;
    wire clock_load;
    wire clock_shift;
    
    button #(
        .XSTART(10),
        .YSTART(10),
        .WIDTH(40),
        .HEIGHT(40),
        
        .XBMP(10),
        .YBMP(10),
        .BMPWIDTH(BMPWIDTH),
        .BMPHEIGHT(BMPHEIGHT),
        .BMPBITS(BMPBITS),
        
        .NUMSTATES(8),
        .STATEBITS(3)
    ) clock (
        .clk(clk),
        .arstn(arstn),
        
        // touch input
        .touch(touch),
        .touchx(touchx),// screen coordinates
        .touchy(touchy),
        
        .touched(),
        .state(clock_state),
        .rst_state(1'b0),
        
        // drawing interface
        .update(clock_update), // needs drawing update
        .draw(clock_draw),
        .cnext(cnext),
        .drawdone(),
        
        .xstart(clock_xstart),
        .xend  (clock_xend),
        .ystart(clock_ystart),
        .yend  (clock_yend),
        .color (clock_color),
        
        .bmpregout(clock_bmpout),
        .bmpregin(bmpregin),
        .bmpreg_load(clock_load),
        .bmpreg_shift(clock_shift),
        
        // bitmap (columns are x (width), rows are y (height) then state 0, 1, 2, etc
        .bmp({20'b00000000000000000000,
              20'b01000000000000000000,
              20'b01000000000000000000,
              20'b01000000000000000000,
              20'b01000000000000000000,
              20'b01111111111111111000,
              20'b00000000000000001000,
              20'b00000000000000001000,
              20'b00000000000000001000,
              20'b00000000000000001000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000010000000000,
              20'b00000000111000000000,
              20'b00000001010100000000,
              20'b00000000010000000000,
              20'b00000000010000000000,
              20'b00000000010000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              
              20'b00000000000000000000,
              20'b00000000000000001000,
              20'b00000000000000001000,
              20'b00000000000000001000,
              20'b00000000000000001000,
              20'b01111111111111111000,
              20'b01000000000000000000,
              20'b01000000000000000000,
              20'b01000000000000000000,
              20'b01000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000010000000000,
              20'b00000000111000000000,
              20'b00000001010100000000,
              20'b00000000010000000000,
              20'b00000000010000000000,
              20'b00000000010000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,


              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00011111111111111000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00011000000000000000,
              20'b00011000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00010000000111111000,
              20'b00010000000100001000,
              20'b00001000001000001000,
              20'b00000111110000001000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00011111111111111000,
              20'b00000000011000000000,
              20'b00000011100111000000,
              20'b00011100000000111000,
              
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00001111111111110000,
              20'b00010000001000001000,
              20'b00010000001000001000,
              20'b00001111110000110000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00011111111111111000,
              20'b00000000011000000000,
              20'b00000011100111000000,
              20'b00011100000000111000,
              
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00010000000111111000,
              20'b00010000000100001000,
              20'b00001000001000001000,
              20'b00000111110000001000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00001111111111110000,
              20'b00010000000000001000,
              20'b00010000000000001000,
              20'b00001111111111110000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00011111111111111000,
              20'b00000000011000000000,
              20'b00000011100111000000,
              20'b00011100000000111000,
              
              20'b00000000000000000000,
              20'b00001000000000010000,
              20'b00010000001000001000,
              20'b00010000001000001000,
              20'b00001111110111110000,
              20'b00000000000000000000,
              20'b00001100000111110000,
              20'b00010000001000001000,
              20'b00010000001000001000,
              20'b00001111111111110000,
              20'b00000000000000000000,
              20'b00001111111111110000,
              20'b00010000000000001000,
              20'b00010000000000001000,
              20'b00001111111111110000,
              20'b00000000000000000000,
              20'b00011111111111111000,
              20'b00000000011000000000,
              20'b00000011100111000000,
              20'b00011100000000111000,
              
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00011111111111111000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00011000000000000000,
              20'b00011000000000000000,
              20'b00000000000000000000,
              20'b00000000000000000000,
              20'b00010000000111111000,
              20'b00010000000100001000,
              20'b00001000001000001000,
              20'b00000111110000001000,
              20'b00000000000000000000,
              20'b00011111111111111000,
              20'b00000000000111000000,
              20'b00000000011000000000,
              20'b00000000000111000000,
              20'b00011111111111111000,
              
              20'b00001111111111110000,
              20'b00010000001000001000,
              20'b00010000001000001000,
              20'b00001111110000110000,
              20'b00000000000000000000,
              20'b00011000000000000000,
              20'b00000000000000000000,
              20'b00001111110000010000,
              20'b00010000001000010000,
              20'b00010000000111110000,
              20'b00000000000000000000,
              20'b00010000000111111000,
              20'b00010000000100001000,
              20'b00000111110000001000,
              20'b00000000000000000000,
              20'b00011111111111111000,
              20'b00000000000111000000,
              20'b00000000011000000000,
              20'b00000000000111000000,
              20'b00011111111111111000
              
              })
    );
    
    
    // gui draw states
    localparam INIT  = 4'd0;
    localparam START = 4'd1;
    localparam LEFT  = 4'd2;
    localparam RIGHT = 4'd3;
    localparam CLOCK = 4'd4;
    
    reg [3:0] state;
    
    always @(posedge clk or negedge arstn) begin
        if(~arstn) begin
            state <= 0;
            tft_draw <= 1'b0;
            drawdone <= 1'b1;
            start_draw <= 1'b0;
            left_draw <= 1'b0;
            right_draw <= 1'b0;
            clock_draw <= 1'b0;
        end else begin
            drawdone <= 1'b0;
            tft_draw <= 1'b0;
            start_draw <= 1'b0;
            left_draw <= 1'b0;
            right_draw <= 1'b0;
            clock_draw <= 1'b0;
            
            case(state)
                INIT: begin
                    drawdone <= 1'b1;
                    if(draw) begin
                        state <= START;
                        drawdone <= 1'b0;
                    end
                end
                
                START: begin
                    if(!start_update && !tft_draw || tft_done) state <= LEFT;
                    else begin
                        if(start_update) start_draw <= 1'b1;
                        tft_draw <= 1'b1;
                    end
                end     
                
                LEFT: begin
                    if(!left_update && !tft_draw || tft_done) state <= RIGHT;
                    else begin
                        if(left_update) left_draw <= 1'b1;
                        tft_draw <= 1'b1;
                    end
                end                
                
                RIGHT: begin
                    if(!right_update && !tft_draw || tft_done) state <= CLOCK;
                    else begin
                        if(right_update) right_draw <= 1'b1;
                        tft_draw <= 1'b1;
                    end
                end
                
                CLOCK: begin
                    if(!clock_update && !tft_draw || tft_done) state <= INIT;
                    else begin
                        if(clock_update) clock_draw <= 1'b1;
                        tft_draw <= 1'b1;
                    end
                end
                
                default: state <= INIT;
            endcase
            
        end
    end
    
    assign update = start_update | left_update | right_update | clock_update;
    
    assign xstart = (state == START) ? start_xstart : 
                    (state == LEFT)  ? left_xstart  :
                    (state == RIGHT) ? right_xstart : 
                    (state == CLOCK) ? clock_xstart : 
                    16'b0;
    assign xend =   (state == START) ? start_xend :
                    (state == LEFT)  ? left_xend :
                    (state == RIGHT) ? right_xend :
                    (state == CLOCK) ? clock_xend :
                    16'b0;
    assign ystart = (state == START) ? start_ystart :
                    (state == LEFT)  ? left_ystart :
                    (state == RIGHT) ? right_ystart :
                    (state == CLOCK) ? clock_ystart :
                    16'b0;
    assign yend =   (state == START) ? start_yend :
                    (state == LEFT)  ? left_yend :
                    (state == RIGHT) ? right_yend :
                    (state == CLOCK) ? clock_yend :
                    16'b0;
    assign color =  (state == START) ? start_color :
                    (state == LEFT)  ? left_color :
                    (state == RIGHT) ? right_color :
                    (state == CLOCK) ? clock_color :
                    16'b0;

    
    // shared shift register for the button bitmaps, to save resources
    reg [0:BMPWIDTH*BMPHEIGHT*BMPBITS-1] bmpreg; // MSB to the right so we start from upper left
    
    wire bmpreg_load =  (state == START) ? start_load :
                        (state == LEFT)  ? left_load :
                        (state == RIGHT) ? right_load :
                        (state == CLOCK) ? clock_load :
                        1'b0;
                        
    wire bmpreg_shift = start_shift | left_shift | right_shift | clock_shift;
    
    always @(posedge clk) begin
        if(bmpreg_load)
            bmpreg <= (state == START) ? start_bmpout :
                      (state == LEFT)  ? left_bmpout :
                      (state == RIGHT) ? right_bmpout:
                                         clock_bmpout;
        else if(bmpreg_shift)
            bmpreg <= bmpreg << BMPBITS;
    end
    
    assign bmpregin = bmpreg[BMPBITS-1:0];

endmodule
