

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
    
    assign {color, xstart, xend, ystart, yend} = drawcmd;
    
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
    
    
    localparam INIT1   = 4'd0;
    localparam INIT2   = 4'd1;
    localparam INIT3   = 4'd2;
    localparam DRAW1   = 4'd3;
    localparam DRAW2   = 4'd4;
    localparam DRAW3   = 4'd5;
    localparam DRAW4   = 4'd6;
    localparam DRAW5   = 4'd7;
    localparam MOVE1   = 4'd8;

    reg [3:0] step = INIT1;
    reg [15:0] ctr = 16'b0;
    reg clr_ctr = 1'b1;
    
    always @(posedge clk)
        if(clr_ctr) ctr = 0;
        else ctr = ctr+1;
    
    wire ctr_max = &ctr;
    
    reg [15:0] xpos;
    reg [15:0] ypos;
    
    reg xdir;
    reg ydir;
    
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
                xpos <= 16'd10;
                ypos <= 16'd10;
                xdir = 0;
                ydir = 0;
                if(tft_done) begin
                    step <= DRAW1;
                end
            end
            
            // drawing program       R,    G,    B, xstart,     xend,         ystart,       yend
            DRAW1: begin drawcmd <= {5'd15,6'd31,5'd00, xpos,        xpos+16'd90, ypos,         ypos+16'd20};  if(tft_done) step<=step+1; else draw <= 1'b1; end
            DRAW2: begin drawcmd <= {5'd15,6'd00,5'd15, xpos+16'd30, xpos+16'd50, ypos+16'd20,  ypos+16'd90};  if(tft_done) step<=step+1; else draw <= 1'b1; end
            DRAW3: begin drawcmd <= {5'd00,6'd63,5'd00, xpos,        xpos+16'd90, ypos+16'd90,  ypos+16'd110}; if(tft_done) step<=step+1; else draw <= 1'b1; end
            DRAW4: begin drawcmd <= {5'd00,6'd31,5'd15, xpos,        xpos+16'd90, ypos+16'd140, ypos+16'd160}; if(tft_done) step<=MOVE1;  else draw <= 1'b1; end
            
            // move position
            MOVE1: begin
                if(xpos == 240-90-1) begin
                    xpos <= xpos - 1;
                    xdir <= 1;
                end else if (xpos == 0) begin
                    xpos <= xpos + 1;
                    xdir <= 0;
                end else if (xdir) begin
                    xpos <= xpos - 1;
                end else begin
                    xpos <= xpos + 1;
                end
                
                if(ypos == 320-160-1) begin
                    ypos <= ypos - 1;
                    ydir <= 1;
                end else if (ypos == 0) begin
                    ypos <= ypos + 1;
                    ydir <= 0;
                end else if (ydir) begin
                    ypos <= ypos - 1;
                end else begin
                    ypos <= ypos + 1;
                end
                
                step <= DRAW1;
            end 
            
            default: begin 
                draw <= 1'b0; 
                step <= INIT1; 
            end
        endcase
    end

    
endmodule
    