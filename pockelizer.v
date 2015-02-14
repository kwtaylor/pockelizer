

module pockelizer (
    input clk,
    //output [5:1] led,
    
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
    output SD_CSn
);
    
    // disable all except TFT for now
    assign TS_CSn = 1'b1;
    assign SD_CSn = 1'b1;
    
    wire tft_busy;
    wire tft_done;
    reg init_tft;
    reg draw;
    reg [79:0] drawcmd;
    
    wire [15:0] xstart;
    wire [15:0] xend;
    wire [15:0] ystart;
    wire [15:0] yend;
    wire [15:0] color;
    
    assign {color, xstart, ystart, xend, yend} = drawcmd;
    
    tft_ctrl /*#(.DLY_WIDTH(5))*/ tctl (
        .clk(clk),
        
        .sclk(SCLK),
        .mosi(MOSI),
        .csn(TFT_CSn),
        .dcn(TFT_DCn),
        
        .init(init_tft),
        .draw(draw),
        
        .busy(tft_busy),
        .done(tft_done),
        
        .color(color),
        .xstart(xstart),
        .xend(xend),
        .ystart(ystart),
        .yend(yend),
        
        .curx(),
        .cury(),
        .cnext()
    );
    
    
    localparam INIT1      = 4'd0;
    localparam INIT2      = 4'd1;
    localparam INIT3      = 4'd2;
    localparam DRAWSTART  = 4'd3;
    localparam DRAWBIT0   = 4'd4;
    localparam DRAWBIT1   = 4'd5;
    localparam DRAWVERT   = 4'd6;
    localparam NEXTBIT    = 4'd7;
    localparam HALT       = 4'd8;

    reg [3:0] step = INIT1;
    reg [15:0] ctr = 16'b0;
    reg clr_ctr = 1'b1;
    
    always @(posedge clk)
        if(clr_ctr) ctr = 0;
        else ctr = ctr+1;
    
    wire ctr_max = &ctr;
    
    reg [15:0] xpos;
    reg [15:0] ypos;
    
    reg [4:0] bitstep;
    reg [3:0] wave;
    
    localparam TOPOFS  = 16'd10; // offset from top
    localparam LEFTOFS = 16'd10; // offset from left
    localparam WHEIGHT = 16'd20; // height of one wave
    localparam WWIDTH  = 16'd20; // width of one step
    localparam WVSTEP  = 16'd50; // distance to next waveform down
    localparam WHSTEPS = 15; // number of bit steps per wave
    localparam WAVES   = 5; // number of waves
    
    wire [WHSTEPS-1:0] wavedat [WAVES-1:0];
    
    assign wavedat[0] = 15'b010101010101010;
    assign wavedat[1] = 15'b111110000011111;
    assign wavedat[2] = 15'b001011101001101;
    assign wavedat[3] = 15'b111000101100111;
    assign wavedat[4] = 15'b000111010011000;
    
    // screen oriented sideways
    //
    //      <--width-->   ^
    //  ^                 height
    //  |
    //  x
    //  (0,0) y--->
    ////////////////////////////
    
    always @(posedge clk) begin
        clr_ctr <= 1'b1;
        init_tft <= 1'b0;
        draw <= 1'b0;
        
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
                    step <= DRAWSTART;
                end
            end
            
            // drawing program               R,    G,    B, xstart,   ystart,           xend,       yend
            DRAWSTART: begin drawcmd <= {5'h00,6'h00,5'h00,  16'd0,    16'd0,        16'd239,    16'd319};  // black background
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
                    if(wave == WAVES-1) step <= HALT;
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
            HALT: step <= HALT;
            
            default: begin 
                draw <= 1'b0; 
                step <= INIT1; 
            end
        endcase
    end

    
endmodule
    