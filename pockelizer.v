

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
        
        .color(color),
        .xstart(xstart),
        .xend(xend),
        .ystart(ystart),
        .yend(yend),
        
        .curx(),
        .cury()
    );

    reg [3:0] step = 4'b0;
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
        draw <= 1'b1; // draw by default to make drawing program cleaner
        
        case(step)
            0: begin // wait for counter to clear
                draw <= 1'b0;
                if(ctr == 0) step <= 1;
            end
            1: begin // delay startup
                draw <= 1'b0;
                clr_ctr <= 1'b0;
                if(ctr_max) step <= 2;
            end
            2: begin // initialize display
                draw <= 1'b0;
                init_tft <= 1'b1;
                if(tft_busy) step <= 3;
            end
            3: begin // wait initialize
                if(!tft_busy) step <= 4;
                xpos <= 16'd10;
                ypos <= 16'd10;
                xdir = 0;
                ydir = 0;
            end
            
            // drawing program       R,    G,    B, xstart,     xend,         ystart,       yend
            4: begin drawcmd <= {5'd15,6'd31,5'd00, xpos,        xpos+16'd90, ypos,         ypos+16'd20};  if(!tft_busy) step<=step+1; end
            5: begin drawcmd <= {5'd15,6'd00,5'd15, xpos+16'd30, xpos+16'd50, ypos+16'd20,  ypos+16'd90};  if(!tft_busy) step<=step+1; end
            6: begin drawcmd <= {5'd00,6'd00,5'd00, xpos,        xpos+16'd90, ypos+16'd90,  ypos+16'd110}; if(!tft_busy) step<=step+1; end
            7: begin drawcmd <= {5'd00,6'd31,5'd15, xpos,        xpos+16'd90, ypos+16'd140, ypos+16'd160}; draw <= 1'b0; if(!tft_busy) step<=step+1; end
            
            // move position
            8: begin
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
                
                step <= 9;
            end 
            
            9: begin // wait for draw command to start
                if(tft_busy) step <= 4;
            end
            
            default: begin 
                draw <= 1'b0; 
                step <= 0; 
            end
        endcase
    end

    
endmodule
    