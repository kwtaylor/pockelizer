

module pockelizer (
    input clk,
    input arstn,
    //output [5:1] led,
    
    input [5:0] logic_in, // 0 is the clock
    
    // SPI 
    output SCLK,
    output MOSI,
    input MISO,
    
    // TFT
    output TFT_CSn,
    output TFT_DCn,
    
    // Resistive touchscreen
    output TS_CSn,
    
    // uSD card
    output SD_CSn, 
    
    // Capacative touchscreen (i2c)
    inout scl,
    inout sda
);

    // disable all except TFT for now
    assign TS_CSn = 1'b1;
    assign SD_CSn = 1'b1;
    
    // arst sync
    reg arstn_sync, arstn_sync_r;
    
    always @(posedge clk or negedge arstn) begin
        if(!arstn) begin
            arstn_sync <= 1'b0;
            arstn_sync_r <= 1'b0;
        end else begin
            arstn_sync_r <= 1'b1;
            arstn_sync <= arstn_sync_r;
        end
    end
    
    // touch screen control
    
    wire touch;
    wire [15:0] touchx;
    wire [15:0] touchy;
    
    touch_ctrl tctrl (
        .clk(clk),
        .arstn(arstn_sync),
        
        .touch(touch),
        .touchx(touchx),
        .touchy(touchy),
        
        .scl(scl),
        .sda(sda)
    );

    //logo!
    reg uselogo = 1'b0;
    reg [8:0] logopos;
    wire [(16*20)*16-1:0] logo;

    assign logo = 
    {16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h07E0,16'hAFE5,16'hFFE0,16'hFD20,16'hF800,16'h0000,16'h0000,
     16'h0000,16'hFD20,16'hF800,16'hF81F,16'h001F,16'h07FF,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'hFFE0,16'h0000,16'hF800,16'h0000,16'h0000,
     16'h0000,16'hFD20,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'hFD20,16'h0000,16'h0000,16'h0000,
     16'h0000,16'hFD20,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,
     16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'hAFE5,16'hFFE0,16'hFD20,16'h0000,16'h0000,16'h0000,
     16'h0000,16'hFD20,16'hF800,16'hF81F,16'h001F,16'h07FF,16'h0000,16'h0000,16'h0000,16'h07E0,16'h0000,16'h0000,16'h0000,16'hF800,16'h0000,16'h0000,
     16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'hAFE5,16'hFFE0,16'hFD20,16'h0000,16'h0000,16'h0000,
     16'h0000,16'hFD20,16'hF800,16'h0000,16'h0000,16'h07FF,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,
     16'h0000,16'hFD20,16'h0000,16'hF81F,16'h0000,16'h07FF,16'h0000,16'h0000,16'h0000,16'h0000,16'hAFE5,16'hFFE0,16'hFD20,16'h0000,16'h0000,16'h0000,
     16'h0000,16'hFD20,16'h0000,16'h0000,16'h001F,16'h07FF,16'h0000,16'h0000,16'h0000,16'h07E0,16'h0000,16'h0000,16'h0000,16'hF800,16'h0000,16'h0000,
     16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h07E0,16'h0000,16'h0000,16'h0000,16'hF800,16'h0000,16'h0000,
     16'h0000,16'hFD20,16'hF800,16'hF81F,16'h001F,16'h07FF,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,
     16'h0000,16'hFD20,16'h0000,16'hF81F,16'h0000,16'h07FF,16'h0000,16'h0000,16'h0000,16'h07E0,16'hAFE5,16'hFFE0,16'hFD20,16'hF800,16'h0000,16'h0000,
     16'h0000,16'hFD20,16'h0000,16'h0000,16'h0000,16'h07FF,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'hFFE0,16'h0000,16'h0000,16'h0000,16'h0000,
     16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h07E0,16'hAFE5,16'h0000,16'hFD20,16'hF800,16'h0000,16'h0000,
     16'h0000,16'hFD20,16'hF800,16'hF81F,16'h001F,16'h07FF,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,
     16'h0000,16'h0000,16'h0000,16'hF81F,16'h0000,16'h07FF,16'h0000,16'h0000,16'h0000,16'h07E0,16'hAFE5,16'hFFE0,16'hFD20,16'hF800,16'h0000,16'h0000,
     16'h0000,16'hFD20,16'hF800,16'h0000,16'h001F,16'h0000,16'h0000,16'h0000,16'h0000,16'h07E0,16'h0000,16'hFFE0,16'h0000,16'hF800,16'h0000,16'h0000,
     16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h07E0,16'h0000,16'h0000,16'h0000,16'hF800,16'h0000,16'h0000,
     16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000,16'h0000};

     
    wire cnext;
    reg [3:0] xscale = 4'b0;
    reg [3:0] yscale = 4'b0;
    
    always @(posedge clk) begin
        if(uselogo) begin
            if(cnext) begin
                xscale <= xscale + 1'b1;
                if(xscale == 4'd14) begin
                    xscale <= 4'b0;
                    logopos <= logopos - 1'b1;
                    if((logopos & 4'hF) == 4'h0) begin
                        yscale <= yscale + 1'b1;
                        if(~&yscale)
                            logopos <= logopos + 4'd15; // wrap around 16-pixel row
                    end
                end
            end
        end else begin
            logopos <= 16*20-1;
            xscale <= 4'b0;
            yscale <= 4'b0;
        end
    
    end
    
    //gui (just one button for now)

    wire [15:0] gxstart;
    wire [15:0] gxend;
    wire [15:0] gystart;
    wire [15:0] gyend;
    wire [15:0] gcolor;
    
    reg gdraw;
    wire gupdate;
    wire gdrawdone;
    
    button #(
        .XSTART(10),
        .YSTART(10),
        .WIDTH(40),
        .HEIGHT(40),
        
        .XBMP(10),
        .YBMP(10),
        .BMPWIDTH(20),
        .BMPHEIGHT(20),
        .BMPBITS(1),
        
        .NUMSTATES(2),
        .STATEBITS(1)
    ) gui (
        .clk(clk),
        .arstn(arstn_sync),
        
        // touch input
        .touch(touch),
        .touchx(16'd239-touchx),// screen coordinates
        .touchy(16'd319-touchy),
        
        .touched(),
        .state(),
        
        // drawing interface
        .update(gupdate), // needs drawing update
        .draw(gdraw),
        .cnext(cnext),
        .drawdone(gdrawdone),
        
        .xstart(gxstart),
        .xend(gxend),
        .ystart(gystart),
        .yend(gyend),
        .color(gcolor),
        
        // bitmap (columns are x (width), rows are y (height) then state 0, 1, 2, etc
        .bmp({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b0,
              1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,
              1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,
              1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,
              1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
              1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0})
    );


    // tft control!
    wire tft_busy;
    wire tft_done;
    reg init_tft;
    reg draw;
    reg [79:0] drawcmd;
    reg drawgui;
    
    wire [15:0] xstart;
    wire [15:0] xend;
    wire [15:0] ystart;
    wire [15:0] yend;
    wire [15:0] color;
    
    wire [79:0] guicmd = {gcolor, gxstart, gystart, gxend, gyend};
    assign {color, xstart, ystart, xend, yend} = drawgui ? guicmd : drawcmd;
    
    tft_ctrl /*#(.DLY_WIDTH(5))*/ tctl (
        .clk(clk),
        .arstn(arstn_sync),
        
        .sclk(SCLK),
        .mosi(MOSI),
        .csn(TFT_CSn),
        .dcn(TFT_DCn),
        
        .init(init_tft),
        .draw(draw),
        
        .busy(tft_busy),
        .done(tft_done),
        
        .color(uselogo ? logo[({4'b0,logopos}<<4) +: 16] : color),
        .xstart(xstart),
        .xend(xend),
        .ystart(ystart),
        .yend(yend),
        
        .curx(),
        .cury(),
        .cnext(cnext)
    );
    
    
    // state machine & capture logic!
    localparam INIT1      = 4'd0;
    localparam INIT2      = 4'd1;
    localparam INIT3      = 4'd2;
    localparam DRAWSTART  = 4'd3;
    localparam DRAWBIT0   = 4'd4;
    localparam DRAWBIT1   = 4'd5;
    localparam DRAWVERT   = 4'd6;
    localparam NEXTBIT    = 4'd7;
    localparam DOCAP      = 4'd8;
    localparam DOCAP0     = 4'd9;
    localparam DRAWLOGO   = 4'd10;
    localparam WAITTOUCH  = 4'd11;
    localparam DRAWDOT    = 4'd12;
    localparam DRAWINIT   = 4'd13;
    localparam DRAWGUI    = 4'd14;
    localparam DRAWGUI2   = 4'd15;


    reg [3:0] step = INIT1;
    reg [15:0] ctr = 16'b0;
    reg clr_ctr = 1'b1;
    
    always @(posedge clk)
        if(clr_ctr) ctr = 0;
        else ctr = ctr+1;
    
    wire ctr_max = &ctr;
    
    reg [15:0] xpos;
    reg [15:0] ypos;
    
    localparam TOPOFS  = 16'd10; // offset from top
    localparam LEFTOFS = 16'd60; // offset from left
    localparam WHEIGHT = 16'd17; // height of one wave
    localparam WWIDTH  = 16'd5; // width of one step
    localparam WVSTEP  = 16'd38; // distance to next waveform down
    localparam STEP_SIZE = 6; // width of regs needed for max steps
    localparam WHSTEPS = 6'd60; // number of bit steps per wave
    localparam POSOFFS = 4'd3; // offset of capture edge from start
    localparam WAVES   = 5; // number of waves
    
    reg [STEP_SIZE-1:0] bitstep;
    reg [3:0] wave;

    reg [WHSTEPS-1:0] wavedat [WAVES-1:0];
    
    //assign wavedat[0] = 15'b010101010101010;
    //assign wavedat[1] = 15'b111110000011111;
    //assign wavedat[2] = 15'b001011101001101;
    //assign wavedat[3] = 15'b111000101100111;
    //assign wavedat[4] = 15'b000111010011000;
    
    reg docap = 1'b0;
    reg startcap, startcap_rr, startcap_r;
    reg capdone, capdone_rr, capdone_r;
    reg [STEP_SIZE-1:0] cappos;
    
    
    always @(posedge logic_in[0]) begin
        // running capture buffer
        if(startcap_r) begin
            if(cappos < WHSTEPS) begin
                wavedat[0][WHSTEPS-1] <= logic_in[1]; wavedat[0][WHSTEPS-2:0] <= wavedat[0][WHSTEPS-1:1];
                wavedat[1][WHSTEPS-1] <= logic_in[2]; wavedat[1][WHSTEPS-2:0] <= wavedat[1][WHSTEPS-1:1];
                wavedat[2][WHSTEPS-1] <= logic_in[3]; wavedat[2][WHSTEPS-2:0] <= wavedat[2][WHSTEPS-1:1];
                wavedat[3][WHSTEPS-1] <= logic_in[4]; wavedat[3][WHSTEPS-2:0] <= wavedat[3][WHSTEPS-1:1];
                wavedat[4][WHSTEPS-1] <= logic_in[5]; wavedat[4][WHSTEPS-2:0] <= wavedat[4][WHSTEPS-1:1];
                if(docap) cappos <= cappos + 1'b1;
                capdone <= 1'b0;
            end else begin
                capdone <= 1'b1;
            end
            
            // start capture at next edge
            if(logic_in[1] != wavedat[0][WHSTEPS-1]) begin
                docap <= 1'b1;
            end
        end else begin
            // reset things
            docap <= 1'b0;
            capdone <= 1'b0;
            cappos <= POSOFFS;
        end
        
        //synchronize
         startcap_r <= startcap_rr;
         startcap_rr <= startcap;
    end
    
    // screen oriented sideways
    //                          <---y (touch 0,0)
    //      <--width-->   ^           x
    //  ^                 height      |
    //  |                             v
    //  x
    //  (0,0) y--->
    ////////////////////////////
              
                   
    
    always @(posedge clk or negedge arstn_sync) begin
        if(~arstn_sync) begin
            clr_ctr <= 1'b1;
            init_tft <= 1'b0;
            draw <= 1'b0;
            startcap <= 1'b0;
            uselogo <= 1'b0;
            gdraw <= 1'b0;
            drawgui <= 1'b0;
            step <= 0;
        end else begin
            clr_ctr <= 1'b1;
            init_tft <= 1'b0;
            draw <= 1'b0;
            startcap <= 1'b0;
            uselogo <= 1'b0;
            gdraw <= 1'b0;
            drawgui <= 1'b0;
        
            // synchronize
            capdone_rr <= capdone;
            capdone_r <= capdone_rr;
            
            case(step)
                INIT1: begin // wait for counter to clear
                    if(ctr == 0) step <= 1;
                end
                INIT2: begin // delay startup
                    clr_ctr <= 1'b0;
                    if(ctr_max) begin 
                        step <= 2;
                        init_tft <= 1'b1;
                    end
                end
                INIT3: begin // wait initialize
                    if(tft_done) begin
                        step <= DRAWLOGO;
                    end
                end
                
                // drawing program               color n/a      xstart,   ystart,           xend,       yend
                DRAWLOGO : begin drawcmd <= {5'h00,6'h00,5'h00,  16'd0,    16'd0,        16'd239,    16'd319};  // logo background
                    uselogo <= 1'b1;
                    if(tft_done) begin
                        step <= WAITTOUCH;
                    end else draw <= 1'b1;
                end
                
                WAITTOUCH: begin
                    if(touch) step <= DRAWINIT;
                end  
                
                // blank screen                 R,    G,    B, xstart,   ystart,           xend,       yend
                DRAWINIT: begin drawcmd <= {5'h00,6'h00,5'h00,  16'd0,    16'd0,         16'd239,    16'd319};  // black background
                    if(tft_done) begin
                        step <= DRAWSTART;
                    end else draw <= 1'b1;
                end
                
                // wait capture
                DOCAP0: begin
                    if(!capdone_r) step <= DOCAP;
                end
                
                DOCAP: begin
                    startcap <= 1'b1;
                    if(gupdate) begin
                        gdraw <= 1'b1;
                        drawgui <= 1'b1;
                        step <= DRAWGUI;
                    end else if(capdone_r) step <= DRAWSTART;
                    else if(touch) step <= DRAWDOT;
                end
                
                // touchscreen test
                DRAWDOT: begin drawcmd <= {5'h00,6'h3f,5'h00, 16'd239-touchx, 16'd319-touchy, 16'd239-touchx, 16'd319-touchy};  // draw green dot
                    startcap <= 1'b1;
                    if(tft_done) step <= DOCAP;
                    else draw <= 1'b1;
                end
                
                DRAWGUI: begin // handshake delay
                    drawgui <= 1'b1;
                    step <= DRAWGUI2;
                end    
                
                DRAWGUI2: begin 
                    drawgui <= 1'b1;
                    if(gdrawdone) step <= DOCAP;
                    else draw <= 1'b1;
                end
                
                // drawing program               R,    G,    B, xstart,   ystart,            xend,      yend
                DRAWSTART: begin drawcmd <= {5'h00,6'h00,5'h00,  16'd0,  LEFTOFS, 16'd239 - TOPOFS,  16'd319};  // black background
                    if(tft_done) begin
                        xpos <= 16'd239 - TOPOFS;
                        ypos <= LEFTOFS;
                        bitstep <= 0;
                        wave <= 0;
                        if(wavedat[0][0]) step<=DRAWBIT1;
                        else step<=DRAWBIT0;
                    end else draw <= 1'b1;
                end
                             
                DRAWBIT0:   begin drawcmd <= {5'h1f,6'h3f,5'h1f,  xpos-WHEIGHT, ypos,  xpos-WHEIGHT, ypos+WWIDTH};  // horizontal line
                    if(tft_done) step <= NEXTBIT;
                    else draw <= 1'b1;
                end
                
                DRAWBIT1:   begin drawcmd <= {5'h1f,6'h3f,5'h1f,  xpos,         ypos,  xpos,         ypos+WWIDTH};  // horizontal line
                    if(tft_done) step <= NEXTBIT;
                    else draw <= 1'b1;
                end
                
                DRAWVERT:   begin drawcmd <= {5'h1f,6'h3f,5'h1f,  xpos-WHEIGHT, ypos,  xpos,         ypos}; // vertical line
                    if(tft_done) begin 
                        if(wavedat[wave][bitstep]) step<=DRAWBIT1;
                        else step<=DRAWBIT0;
                    end else draw <= 1'b1;
                end
                
                NEXTBIT: begin 
                    if(bitstep == WHSTEPS-1) begin
                        if(wave == WAVES-1) step <= DOCAP0;
                        else begin // next wave
                            xpos <= xpos - WVSTEP;
                            ypos <= LEFTOFS;
                            bitstep <= 0;
                            wave <= wave+1;
                            if(wavedat[wave+1][0]) step<=DRAWBIT1;
                            else step<=DRAWBIT0;
                        end
                    end else begin // next bit of wave
                        ypos <= ypos + WWIDTH;
                        bitstep <= bitstep+1;
                        if(wavedat[wave][bitstep] != wavedat[wave][bitstep+1]) step<=DRAWVERT;
                        else if(wavedat[wave][bitstep]) step<=DRAWBIT1;
                        else step<=DRAWBIT0;
                    end
                end
                
                // done (for NOW)
                //HALT: step <= HALT;
                
                default: begin 
                    draw <= 1'b0; 
                    step <= INIT1; 
                end
            endcase
        end
    end

    
endmodule
    