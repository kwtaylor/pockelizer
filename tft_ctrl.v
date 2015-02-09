module tft_ctrl #( parameter DLY_WIDTH = 23 )(
    input clk,
    
    //spi interface
    output sclk,
    output mosi,
    output reg csn,
    output reg dcn,
    
    input init,
    input draw,
    
    output reg busy,
    
    // draw command parameters
    input [15:0] color, // rrrr rggg gggb bbbb
    input [15:0] xstart,
    input [15:0] xend,
    input [15:0] ystart,
    input [15:0] yend,
    
    // optional interface for blitting
    // (change color input based on curx,cury)
    output reg [15:0] curx,
    output reg [15:0] cury
    
);

    reg spi_go = 0;
    wire spi_done;
    wire [7:0] spi_data;
    
    simple_spi spi (
        .clk(clk),
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
            0: color_cmds = {1'b0, `ILI9341_CASET};
            1: color_cmds = {1'b1, xstart[15:8]}; 
            2: color_cmds = {1'b1, xstart[7:0]}; 
            3: color_cmds = {1'b1, xend[15:8]}; 
            4: color_cmds = {1'b1, xend[7:0]}; 
            5: color_cmds = {1'b0, `ILI9341_PASET};
            6: color_cmds = {1'b1, ystart[15:8]}; 
            7: color_cmds = {1'b1, ystart[7:0]}; 
            8: color_cmds = {1'b1, yend[15:8]}; 
            9: color_cmds = {1'b1, yend[7:0]}; 
           10: color_cmds = {1'b0, `ILI9341_RAMWR}; 
           11: colordone = 1'b1;
        endcase
    end
    
    //////////////////////////////////
    // main state machine
    //////////////////////////////////
    
    localparam IDLE      = 3'b000;
    localparam INIT      = 3'b001;
    localparam INITDLY   = 3'b010;
    localparam COLORCMD  = 3'b011;
    localparam COLORDAT  = 3'b100;
    
    reg [2:0] state = IDLE;
    
    reg cnt_clr;
    reg [DLY_WIDTH-1:0] dly_cnt;
    
    always @(posedge clk)
        if(cnt_clr) dly_cnt <= 0;
        else dly_cnt <= dly_cnt + 1;
        
    wire max_cnt = &dly_cnt;
    
    always @(posedge clk) begin
        //defaults
        csn <= 1'b1;
        busy <= 1'b0;
        cnt_clr <= 1'b1;
        
        case(state)
            IDLE: begin
                step <= 0;
                curx <= 0;
                cury <= 0;
                spi_go <= 1'b0;
                
                if(init) begin
                    state <= INIT;
                    spi_go <= 1'b1;
                end else if(draw) begin
                    state <= COLORCMD;
                    spi_go <= 1'b1;
                end
            end
            
            INIT: begin
                csn <= 1'b0;
                busy <= 1'b1;
                
                if(initdone) begin
                    if(spi_done) state <= IDLE;
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
                
                if(colordone) begin
                    state <= COLORDAT;
                    spi_go <= 1'b1;
                    curx <= xstart;
                    cury <= ystart;
                    step <= 0;
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
                
                if(cury > yend) begin
                    if(spi_done) state <= IDLE;
                end else begin // handshake and increment
                    if(spi_done && !spi_go) begin
                        spi_go <= 1'b1;
                    end else if(spi_go && !spi_done) begin 
                        if(step == 1) begin
                            curx <= curx + 1;
                            if(curx == xend) begin
                                curx <= xstart;
                                cury <= cury + 1;
                            end
                            step <= 0;
                        end else step = step + 1;
                        spi_go <= 1'b0;
                    end
                end
            end
            
            default: state <= IDLE;
        endcase
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
                      (step == 0) ? color[15:8] : color[7:0];


endmodule