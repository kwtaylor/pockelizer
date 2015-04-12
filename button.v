// keeps track of a button's state and generates drawing commands
module button #(
    parameter XSTART = 0, // button (touch) area
    parameter YSTART = 0,
    parameter WIDTH = 1,
    parameter HEIGHT = 1,
    parameter BACKRGB = 16'h0000, // background color
    parameter INVTOUCH = 1, // invert when touched?

    // x/y from here on are relative to xstart/ystart
    parameter XBORD = 0, // simple square border
    parameter YBORD = 0,
    parameter BORDWIDTH = WIDTH,
    parameter BORDHEIGHT = HEIGHT,
    parameter BORDERRGB = 16'hFFFF,
    
    parameter XBMP = 0, // optional bitmap showing state
    parameter YBMP = 0,
    parameter BMPWIDTH = 1,
    parameter BMPHEIGHT = 1,
    parameter BMPBITS = 1, // only supports 1,3,16
    
    parameter NUMSTATES = 1,
    parameter STATEBITS = 1
) (
    input clk,
    input arstn,
    
    // touch input
    input touch,
    input [15:0] touchx, // these need to be in screen coordinates
    input [15:0] touchy,
    
    output reg touched,
    output reg [STATEBITS-1:0] state,
    
    // drawing interface
    output reg update, // needs drawing update
    input draw,
    input cnext,
    output reg drawdone,
    
    output [15:0] xstart,
    output [15:0] xend,
    output [15:0] ystart,
    output [15:0] yend,
    output [15:0] color,
    
    // bitmap (columns are x (width), rows are y (height) then state 0, 1, 2, etc
    input [0:BMPWIDTH*BMPHEIGHT*BMPBITS*NUMSTATES-1] bmp // MSB to the right so we start from upper left
);

reg lasttouched;

// simple touch detection
always @(posedge clk) begin
    touched <= touch && touchx >= XSTART
                     && touchx <  XSTART+WIDTH
                     && touchy >= YSTART
                     && touchy <  YSTART+HEIGHT;
    lasttouched <= touched;
end

// button state
always @(posedge clk or negedge arstn) begin
    if(!arstn) begin
        state <= 0;
        update <= 1'b1;
    end else begin
        if(touched && !lasttouched) begin
            update <= 1'b1;
            if(state==NUMSTATES-1) state <= 0;
            else state <= state+1;
        end else if(!touched && lasttouched) begin
            if(INVTOUCH) update <= 1'b1;
        end
        if(draw) update <= 0;
    end
end

// draw command
reg [0:BMPWIDTH*BMPHEIGHT*BMPBITS-1] bmpreg; // MSB to the right so we start from upper left
reg [15:0] posx;
reg [15:0] posy;

wire inbmp = posx >= XBMP && posx < XBMP+BMPWIDTH &&
             posy >= YBMP && posy < YBMP+BMPWIDTH;
              
wire inbord = posx == XBORD || posx == XBORD+BORDWIDTH-1 ||
              posy == YBORD || posy == YBORD+BORDHEIGHT-1;

always @(posedge clk or negedge arstn) begin
    if(!arstn) begin
        drawdone <= 1'b1;
        posx <= 0;
        posy <= 0;
    end else if(!draw && drawdone) begin
        bmpreg <= bmp[BMPWIDTH*BMPHEIGHT*BMPBITS*state +: BMPWIDTH*BMPHEIGHT*BMPBITS];
        drawdone <= 1'b1;
        posx <= 0;
        posy <= 0;
    end else begin
        drawdone <= 1'b0;
        if(cnext) begin
            if(posx == WIDTH-1 && posy == HEIGHT-1) drawdone <= 1'b1;
            else begin
                if(posx == WIDTH-1) begin
                    posx <= 0;
                    posy <= posy + 1'b1;
                end else posx <= posx + 1'b1;
                
                if(inbmp) bmpreg <= bmpreg << BMPBITS;
            end
        end
    end
end

assign xstart = XSTART;
assign xend = XSTART+WIDTH-1;
assign ystart = YSTART;
assign yend = YSTART+HEIGHT-1;
assign color = ((INVTOUCH && touched) ? 16'hFFFF : 16'h0000) ^
               (inbord ? BORDERRGB :
                inbmp ? ((BMPBITS == 1) ? {16{bmpreg[0]}} :
                         (BMPBITS == 3) ? {{5{bmpreg[2]}},{6{bmpreg[1]}},{5{bmpreg[0]}}} :
                         bmpreg[BMPBITS-1:0]) :
                BACKRGB);

endmodule