// encapsulates all the buttons in the gui
module gui #(
    parameter WAVES = 5,
    parameter TOPOFS = 4,
    parameter WVSTEP = 38
) (
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
    output start_state, // 0=pause, 1=go (one shot)
    input start_rst,
    output cont_state, // 0=pause, 1=go (continuous)
    input cont_rst,
    output left_touched,
    output right_touched,
    output [2:0] clock_state,
    output [WAVES*3-1:0] cap_state
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
    
    wire [15:0] cont_xstart;
    wire [15:0] cont_xend;
    wire [15:0] cont_ystart;
    wire [15:0] cont_yend;
    wire [15:0] cont_color;
    
    reg cont_draw;
    wire cont_update;
    wire [0:BMPWIDTH*BMPHEIGHT*BMPBITS-1] cont_bmpout;
    wire cont_load;
    wire cont_shift;
    
    button #(
        .XSTART(10),
        .YSTART(160),
        .WIDTH(40),
        .HEIGHT(40),
        
        .XBMP(10),
        .YBMP(10),
        .BMPWIDTH(BMPWIDTH),
        .BMPHEIGHT(BMPHEIGHT),
        .BMPBITS(BMPBITS),
        
        .NUMSTATES(2),
        .STATEBITS(1)
    ) cont (
        .clk(clk),
        .arstn(arstn),
        
        // touch input
        .touch(touch),
        .touchx(touchx),// screen coordinates
        .touchy(touchy),
        
        .touched(),
        .state(cont_state),
        .rst_state(cont_rst),
        
        // drawing interface
        .update(cont_update), // needs drawing update
        .draw(cont_draw),
        .cnext(cnext),
        .drawdone(),
        
        .xstart(cont_xstart),
        .xend  (cont_xend),
        .ystart(cont_ystart),
        .yend  (cont_yend),
        .color (cont_color),
        
        .bmpregout(cont_bmpout),
        .bmpregin(bmpregin),
        .bmpreg_load(cont_load),
        .bmpreg_shift(cont_shift),
        
        // bitmap (columns are x (width), rows are y (height) then state 0, 1, 2, etc
        .bmp({20'b00000000000000000000,
              20'b11111111111111111110,
              20'b10000000000000000010,
              20'b01000011100000000100,
              20'b01000001100100000100,
              20'b00100010100010001000,
              20'b00100010000010001000,
              20'b00010010000010010000,
              20'b00010001000100010000,
              20'b00001000111000100000,
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
              20'b00001111110000001000,
              20'b00010000001000001000,
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
    
    wire [0:BMPWIDTH*BMPHEIGHT*BMPBITS*6-1] cap_bmp = 
        {20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00100000000000001000,
         20'b00010000000000010000,
         20'b00001000000000100000,
         20'b00000100000001000000,
         20'b00000010000010000000,
         20'b00000001000100000000,
         20'b00000000101000000000,
         20'b00000000010000000000,
         20'b00000000101000000000,
         20'b00000001000100000000,
         20'b00000010000010000000,
         20'b00000100000001000000,
         20'b00001000000000100000,
         20'b00010000000000010000,
         20'b00100000000000001000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00100000000000000000,
         20'b00100000000000000000,
         20'b00100000000000000000,
         20'b00100000000000000000,
         20'b00100000000000000000,
         20'b00100000000000000000,
         20'b00100000000000000000,
         20'b00111111111111111000,
         20'b00000000000000001000,
         20'b00000000000000001000,
         20'b00000000000000001000,
         20'b00000000000000001000,
         20'b00000000000000001000,
         20'b00000000000000001000,
         20'b00000000000000001000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
        
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000001000,
         20'b00000000000000001000,
         20'b00000000000000001000,
         20'b00000000000000001000,
         20'b00000000000000001000,
         20'b00000000000000001000,
         20'b00000000000000001000,
         20'b00111111111111111000,
         20'b00100000000000000000,
         20'b00100000000000000000,
         20'b00100000000000000000,
         20'b00100000000000000000,
         20'b00100000000000000000,
         20'b00100000000000000000,
         20'b00100000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
        
        
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00100000000000001000,
         20'b00100000000000001000,
         20'b00100000000000001000,
         20'b00100000000000001000,
         20'b00100000000000001000,
         20'b00100000000000001000,
         20'b00011110000011110000,
         20'b00000001111100000000,
         20'b00011110000011110000,
         20'b00100000000000001000,
         20'b00100000000000001000,
         20'b00100000000000001000,
         20'b00100000000000001000,
         20'b00100000000000001000,
         20'b00100000000000001000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
        
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000111111111100000,
         20'b00001000000000010000,
         20'b00010000000000001000,
         20'b00010000000000001000,
         20'b00001000000000010000,
         20'b00000111111111100000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
        
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00010000000000100000,
         20'b00010000000000010000,
         20'b00011111111111111000,
         20'b00010000000000000000,
         20'b00010000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000,
         20'b00000000000000000000
        };
        
    wire [15:0] cap_xstart [WAVES-1:0];
    wire [15:0] cap_xend   [WAVES-1:0];
    wire [15:0] cap_ystart [WAVES-1:0];
    wire [15:0] cap_yend   [WAVES-1:0];
    wire [15:0] cap_color  [WAVES-1:0];
    
    reg  [WAVES-1:0] cap_draw;
    wire [WAVES-1:0] cap_update;
    wire [0:BMPWIDTH*BMPHEIGHT*BMPBITS-1] cap_bmpout [WAVES-1:0];
    wire [WAVES-1:0] cap_load;
    wire [WAVES-1:0] cap_shift;
        
    generate
      genvar i;
      for(i=0; i < WAVES; i=i+1) begin : GENCAP
    
        button #(
            .XSTART(239-(TOPOFS+i*WVSTEP) - 28),
            .YSTART(0),
            .WIDTH(28),
            .HEIGHT(50),
            
            .XBMP(2),
            .YBMP(20),
            .BMPWIDTH(BMPWIDTH),
            .BMPHEIGHT(BMPHEIGHT),
            .BMPBITS(BMPBITS),
            
            .NUMSTATES(6),
            .STATEBITS(3),
            
            .BORDERRGB(16'b0), // no border
            
            .RSTSTATE(i==0 ? 3 : 0)
        ) cap (
            .clk(clk),
            .arstn(arstn),
            
            // touch input
            .touch(touch),
            .touchx(touchx),// screen coordinates
            .touchy(touchy),
            
            .touched(),
            .state(cap_state[i*3 +: 3]),
            .rst_state(1'b0),
            
            // drawing interface
            .update(cap_update[i]), // needs drawing update
            .draw(cap_draw[i]),
            .cnext(cnext),
            .drawdone(),
            
            .xstart(cap_xstart[i]),
            .xend  (cap_xend[i]),
            .ystart(cap_ystart[i]),
            .yend  (cap_yend[i]),
            .color (cap_color[i]),
            
            .bmpregout(cap_bmpout[i]),
            .bmpregin(bmpregin),
            .bmpreg_load(cap_load[i]),
            .bmpreg_shift(cap_shift[i]),
            
            // bitmap (columns are x (width), rows are y (height) then state 0, 1, 2, etc
            .bmp(cap_bmp)
        );

      end
    endgenerate
    
    
    // gui draw states
    localparam INIT  = 4'd0;
    localparam START = 4'd1;
    localparam LEFT  = 4'd2;
    localparam RIGHT = 4'd3;
    localparam CLOCK = 4'd4;
    localparam CONT  = 4'd5;
    localparam CAP0  = 4'd6;
    localparam CAP1  = 4'd7;
    localparam CAP2  = 4'd8;
    localparam CAP3  = 4'd9;
    localparam CAP4  = 4'd10;

    
    reg [3:0] state;
    
    always @(posedge clk or negedge arstn) begin
        if(~arstn) begin
            state <= 0;
            tft_draw <= 1'b0;
            drawdone <= 1'b1;
            start_draw <= 1'b0;
            cont_draw <= 1'b0;
            left_draw <= 1'b0;
            right_draw <= 1'b0;
            clock_draw <= 1'b0;
            cap_draw <= 0;
        end else begin
            drawdone <= 1'b0;
            tft_draw <= 1'b0;
            start_draw <= 1'b0;
            cont_draw <= 1'b0;
            left_draw <= 1'b0;
            right_draw <= 1'b0;
            clock_draw <= 1'b0;
            cap_draw <= 0;
            
            case(state)
                INIT: begin
                    drawdone <= 1'b1;
                    if(draw) begin
                        state <= START;
                        drawdone <= 1'b0;
                    end
                end
                
                START: begin
                    if(!start_update && !tft_draw || tft_done) state <= CONT;
                    else begin
                        if(start_update) start_draw <= 1'b1;
                        tft_draw <= 1'b1;
                    end
                end     
                
                CONT: begin
                    if(!cont_update && !tft_draw || tft_done) state <= LEFT;
                    else begin
                        if(cont_update) cont_draw <= 1'b1;
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
                    if(!clock_update && !tft_draw || tft_done) state <= CAP0;
                    else begin
                        if(clock_update) clock_draw <= 1'b1;
                        tft_draw <= 1'b1;
                    end
                end
                
                CAP0: begin
                    if(!cap_update[0] && !tft_draw || tft_done) state <= CAP1;
                    else begin
                        if(cap_update[0]) cap_draw[0] <= 1'b1;
                        tft_draw <= 1'b1;
                    end
                end
                
                CAP1: begin
                    if(!cap_update[1] && !tft_draw || tft_done) state <= CAP2;
                    else begin
                        if(cap_update[1]) cap_draw[1] <= 1'b1;
                        tft_draw <= 1'b1;
                    end
                end
                
                CAP2: begin
                    if(!cap_update[2] && !tft_draw || tft_done) state <= CAP3;
                    else begin
                        if(cap_update[2]) cap_draw[2] <= 1'b1;
                        tft_draw <= 1'b1;
                    end
                end
                
                CAP3: begin
                    if(!cap_update[3] && !tft_draw || tft_done) state <= CAP4;
                    else begin
                        if(cap_update[3]) cap_draw[3] <= 1'b1;
                        tft_draw <= 1'b1;
                    end
                end
                
                CAP4: begin
                    if(!cap_update[4] && !tft_draw || tft_done) state <= INIT;
                    else begin
                        if(cap_update[4]) cap_draw[4] <= 1'b1;
                        tft_draw <= 1'b1;
                    end
                end
                
                default: state <= INIT;
            endcase
            
        end
    end
    
    assign update = start_update | cont_update | left_update | right_update | clock_update | |cap_update;
    
    assign xstart = (state == START) ? start_xstart : 
                    (state == CONT)  ? cont_xstart : 
                    (state == LEFT)  ? left_xstart  :
                    (state == RIGHT) ? right_xstart : 
                    (state == CLOCK) ? clock_xstart : 
                    (state == CAP0)  ? cap_xstart[0] : 
                    (state == CAP1)  ? cap_xstart[1] : 
                    (state == CAP2)  ? cap_xstart[2] : 
                    (state == CAP3)  ? cap_xstart[3] : 
                    (state == CAP4)  ? cap_xstart[4] : 
                    16'b0;
    assign xend =   (state == START) ? start_xend :
                    (state == CONT)  ? cont_xend :
                    (state == LEFT)  ? left_xend :
                    (state == RIGHT) ? right_xend :
                    (state == CLOCK) ? clock_xend :
                    (state == CAP0)  ? cap_xend[0] : 
                    (state == CAP1)  ? cap_xend[1] : 
                    (state == CAP2)  ? cap_xend[2] : 
                    (state == CAP3)  ? cap_xend[3] : 
                    (state == CAP4)  ? cap_xend[4] : 
                    16'b0;
    assign ystart = (state == START) ? start_ystart :
                    (state == CONT)  ? cont_ystart :
                    (state == LEFT)  ? left_ystart :
                    (state == RIGHT) ? right_ystart :
                    (state == CLOCK) ? clock_ystart :
                    (state == CAP0)  ? cap_ystart[0] : 
                    (state == CAP1)  ? cap_ystart[1] : 
                    (state == CAP2)  ? cap_ystart[2] : 
                    (state == CAP3)  ? cap_ystart[3] : 
                    (state == CAP4)  ? cap_ystart[4] : 
                    16'b0;
    assign yend =   (state == START) ? start_yend :
                    (state == CONT)  ? cont_yend :
                    (state == LEFT)  ? left_yend :
                    (state == RIGHT) ? right_yend :
                    (state == CLOCK) ? clock_yend :
                    (state == CAP0)  ? cap_yend[0] : 
                    (state == CAP1)  ? cap_yend[1] : 
                    (state == CAP2)  ? cap_yend[2] : 
                    (state == CAP3)  ? cap_yend[3] : 
                    (state == CAP4)  ? cap_yend[4] : 
                    16'b0;
    assign color =  (state == START) ? start_color :
                    (state == CONT)  ? cont_color :
                    (state == LEFT)  ? left_color :
                    (state == RIGHT) ? right_color :
                    (state == CLOCK) ? clock_color :
                    (state == CAP0)  ? cap_color[0] : 
                    (state == CAP1)  ? cap_color[1] : 
                    (state == CAP2)  ? cap_color[2] : 
                    (state == CAP3)  ? cap_color[3] : 
                    (state == CAP4)  ? cap_color[4] : 
                    16'b0;

    
    // shared shift register for the button bitmaps, to save resources
    reg [0:BMPWIDTH*BMPHEIGHT*BMPBITS-1] bmpreg; // MSB to the right so we start from upper left
    
    wire bmpreg_load =  (state == START) ? start_load :
                        (state == CONT)  ? cont_load :
                        (state == LEFT)  ? left_load :
                        (state == RIGHT) ? right_load :
                        (state == CLOCK) ? clock_load :
                        (state == CAP0)  ? cap_load[0] :
                        (state == CAP1)  ? cap_load[1] :
                        (state == CAP2)  ? cap_load[2] :
                        (state == CAP3)  ? cap_load[3] :
                        (state == CAP4)  ? cap_load[4] :
                        1'b0;
                        
    wire bmpreg_shift = start_shift | cont_shift | left_shift | right_shift | clock_shift | |cap_shift;
    
    always @(posedge clk) begin
        if(bmpreg_load)
            bmpreg <= (state == START) ? start_bmpout :
                      (state == CONT)  ? cont_bmpout :
                      (state == LEFT)  ? left_bmpout :
                      (state == RIGHT) ? right_bmpout:
                      (state == CAP0)  ? cap_bmpout[0]:
                      (state == CAP1)  ? cap_bmpout[1]:
                      (state == CAP2)  ? cap_bmpout[2]:
                      (state == CAP3)  ? cap_bmpout[3]:
                      (state == CAP4)  ? cap_bmpout[4]:
                                         clock_bmpout;
        else if(bmpreg_shift)
            bmpreg <= bmpreg << BMPBITS;
    end
    
    assign bmpregin = bmpreg[BMPBITS-1:0];

endmodule
