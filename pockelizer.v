

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
    {256'h0000_0000_0000_0000_0000_0000_0000_0000_0000_07E0_AFE5_FFE0_FD20_F800_0000_0000,
     256'h0000_FD20_F800_F81F_001F_07FF_0000_0000_0000_0000_0000_FFE0_0000_F800_0000_0000,
     256'h0000_FD20_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_FD20_0000_0000_0000,
     256'h0000_FD20_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000,
     256'h0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_AFE5_FFE0_FD20_0000_0000_0000,
     256'h0000_FD20_F800_F81F_001F_07FF_0000_0000_0000_07E0_0000_0000_0000_F800_0000_0000,
     256'h0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_AFE5_FFE0_FD20_0000_0000_0000,
     256'h0000_FD20_F800_0000_0000_07FF_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000,
     256'h0000_FD20_0000_F81F_0000_07FF_0000_0000_0000_0000_AFE5_FFE0_FD20_0000_0000_0000,
     256'h0000_FD20_0000_0000_001F_07FF_0000_0000_0000_07E0_0000_0000_0000_F800_0000_0000,
     256'h0000_0000_0000_0000_0000_0000_0000_0000_0000_07E0_0000_0000_0000_F800_0000_0000,
     256'h0000_FD20_F800_F81F_001F_07FF_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000,
     256'h0000_FD20_0000_F81F_0000_07FF_0000_0000_0000_07E0_AFE5_FFE0_FD20_F800_0000_0000,
     256'h0000_FD20_0000_0000_0000_07FF_0000_0000_0000_0000_0000_FFE0_0000_0000_0000_0000,
     256'h0000_0000_0000_0000_0000_0000_0000_0000_0000_07E0_AFE5_0000_FD20_F800_0000_0000,
     256'h0000_FD20_F800_F81F_001F_07FF_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000,
     256'h0000_0000_0000_F81F_0000_07FF_0000_0000_0000_07E0_AFE5_FFE0_FD20_F800_0000_0000,
     256'h0000_FD20_F800_0000_001F_0000_0000_0000_0000_07E0_0000_FFE0_0000_F800_0000_0000,
     256'h0000_0000_0000_0000_0000_0000_0000_0000_0000_07E0_0000_0000_0000_F800_0000_0000,
     256'h0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000};

     
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
    
    // tft control!
    wire tft_busy;
    wire tft_done;
    reg init_tft;
    reg draw;
    reg [79:0] drawcmd;
    reg drawgui;
    
    //gui (just one button for now)
    wire [15:0] gxstart;
    wire [15:0] gxend;
    wire [15:0] gystart;
    wire [15:0] gyend;
    wire [15:0] gcolor;
    
    reg gdraw;
    wire gtft_draw;
    wire gupdate;
    wire gdrawdone;
    wire start_state;
    reg start_rst;
    wire cont_state;
    wire [3:0] capclk_state;
    wire left_touched;
    wire right_touched;
    wire [1:0] pos_state;
    wire [WAVES*3-1:0] cap_state;
    
    //screen dimensions
    localparam XMAX    = 16'd239;
    localparam YMAX    = 16'd319;
    
    gui g (
        .clk(clk),
        .arstn(arstn_sync),
        
        // touch input
        .touch(touch),
        .touchx(XMAX-touchx),// screen coordinates
        .touchy(YMAX-touchy),
        
        // drawing interface
        .update(gupdate), // needs drawing update
        .draw(gdraw),
        .tft_draw(gtft_draw),
        .cnext(cnext),
        .tft_done(tft_done),
        .drawdone(gdrawdone),
        
        .xstart(gxstart),
        .xend(gxend),
        .ystart(gystart),
        .yend(gyend),
        .color(gcolor),
        
        .start_state(start_state),
        .start_rst(start_rst || cont_state),
        .cont_state(cont_state),
        .cont_rst(start_state),
        .left_touched(left_touched),
        .right_touched(right_touched),
        .pos_state(pos_state),
        .clock_state(capclk_state),
        .cap_state(cap_state)
        
    );

    
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
        .draw(drawgui ? gtft_draw : draw),
        
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
    localparam DRAWPOS    = 4'd9;
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
    localparam STEP_SIZE = 7; // width of regs needed for max steps
    localparam WHSTEPS = 7'd120; // number of bit steps per wave
    localparam SCSTEPS = 7'd60; // number of bit steps on screen
    localparam LPOSOFFS = 7'd3; // offset of capture edge from start (left cap)
    localparam MPOSOFFS = 7'd60; // offset of capture edge from start (mid cap)
    localparam RPOSOFFS = 7'd115; // offset of capture edge from start (right cap)
    localparam WAVES   = 5; // number of waves
    
    reg [STEP_SIZE-1:0] bitstep;
    reg [3:0] wave;

    reg [WHSTEPS-1:0] capbuf  [WAVES-1:0];
    reg [WHSTEPS-1:0] wavedat [WAVES-1:0];
    
    //assign wavedat[0] = 15'b010101010101010;
    //assign wavedat[1] = 15'b111110000011111;
    //assign wavedat[2] = 15'b001011101001101;
    //assign wavedat[3] = 15'b111000101100111;
    //assign wavedat[4] = 15'b000111010011000;
    
    reg docap = 1'b0;
    reg startcap, startcap_rr, startcap_r;
    reg capdone, capdone_rr, capdone_r, capdone_c;
    reg [STEP_SIZE-1:0] cappos;
    reg [STEP_SIZE-1:0] capstart = 0;
    reg lastlefttouch, lastrighttouch;
    reg updwav, clrupdwav;
    reg rstcapstart;
    
    localparam STEPMOVE = 5; // number of steps to move per button
    
    //cap position logic
    // simple button response for now. Later add hold-down feature TODO
    always @(posedge clk or negedge arstn_sync) begin
        if(~arstn_sync) begin
            capstart <= 0;
            lastlefttouch <= 1'b0;
            lastrighttouch <= 1'b0;
            updwav <= 1'b0;
            clrupdwav <= 1'b0;
        end else begin
            if(step == DOCAP && clrupdwav) begin
                updwav <= 1'b0;
                clrupdwav <= 1'b1;
            end else if(step != DOCAP && updwav) clrupdwav <= 1'b1;
        
            if(!updwav && left_touched && capstart >= STEPMOVE) begin
                capstart <= capstart - STEPMOVE;
                updwav <= 1'b1;
            end else if(!updwav && right_touched && capstart < WHSTEPS-SCSTEPS) begin
                capstart <= capstart + STEPMOVE;
                updwav <= 1'b1;
            end
            
            if(rstcapstart) capstart <= 0;
        end
    end
    
    // clock dividers
    // clocks are powers of 2 divisions of 50MHz
    reg [14:0] clkdiv;
    integer i;
    
    always @(posedge clk)
        clkdiv <= clkdiv+1;
        
    wire clk25M   = clkdiv[0];
    wire clk12_5M = clkdiv[1];
    wire clk6_25M = clkdiv[2];
    wire clk3_13M = clkdiv[3];
    wire clk1_5M  = clkdiv[4];
    wire clk781k  = clkdiv[5];
    wire clk390k  = clkdiv[6];
    wire clk195k  = clkdiv[7];
    wire clk98k   = clkdiv[8];
    wire clk48_8k = clkdiv[9];
    wire clk24_4k = clkdiv[10];
    wire clk12_2k = clkdiv[11];
    wire clk6k    = clkdiv[12];
    wire clk3k    = clkdiv[13];
    wire clk1_5k  = clkdiv[14];
    
    wire capclock = capclk_state == 4'hf ? clk          :
                    capclk_state == 4'he ? clk25M       :
                    capclk_state == 4'hd ? clk12_5M     :
                    capclk_state == 4'hc ? clk6_25M     :
                    capclk_state == 4'hb ? clk3_13M     :
                    capclk_state == 4'ha ? clk1_5M      :
                    capclk_state == 4'h9 ? clk781k      :
                    capclk_state == 4'h8 ? clk390k      :
                    capclk_state == 4'h7 ? clk195k      :
                    capclk_state == 4'h6 ? clk98k       :
                    capclk_state == 4'h5 ? clk48_8k     :
                    capclk_state == 4'h4 ? clk24_4k     :
                    capclk_state == 4'h3 ? clk12_2k     :
                    capclk_state == 4'h2 ? clk6k        :
                    capclk_state == 4'h1 ? ~logic_in[0] :
                                            logic_in[0] ;
                                            
    localparam CAP_DONTCARE = 3'd0;
    localparam CAP_RISING   = 3'd1;
    localparam CAP_FALLING  = 3'd2;
    localparam CAP_EITHER   = 3'd3;
    localparam CAP_LOW      = 3'd4;
    localparam CAP_HIGH     = 3'd5;
    
    reg [WAVES-1:0] cap_cond;
    
    always @(*) for(i = 0; i < WAVES; i = i+1) begin
        case(cap_state[i*3 +: 3])
            CAP_RISING:  cap_cond[i] =  logic_in[i+1] && !capbuf[i][WHSTEPS-1];
            CAP_FALLING: cap_cond[i] = !logic_in[i+1] &&  capbuf[i][WHSTEPS-1];
            CAP_EITHER:  cap_cond[i] =  logic_in[i+1] !=  capbuf[i][WHSTEPS-1];
            CAP_LOW:     cap_cond[i] = !logic_in[i+1];
            CAP_HIGH:    cap_cond[i] =  logic_in[i+1];
            default:     cap_cond[i] = 1'b1;
        endcase
    end
    
    localparam POSL = 2'd0;
    localparam POSM = 2'd1;
    localparam POSR = 2'd2;
    
    reg [1:0] pos_cap;
    reg [1:0] pos_cap_b;
    
    always @(posedge capclock) begin
        // running capture buffer
        if(startcap_r) begin
            if(cappos < WHSTEPS) begin
                for(i = 0; i < WAVES; i = i+1) begin
                    capbuf[i][WHSTEPS-1] <= logic_in[i+1]; 
                    capbuf[i][WHSTEPS-2:0] <= capbuf[i][WHSTEPS-1:1];
                end
                if(docap) cappos <= cappos + 1'b1;
                capdone <= 1'b0;
            end else begin
                capdone <= 1'b1;
                for(i = 0; i < WAVES; i = i+1)
                    wavedat[i] <= capbuf[i];
                pos_cap <= pos_cap_b;
            end
            
            // start capture when condition met
            if(&cap_cond) docap <= 1'b1;
        end else begin
            // reset things
            docap <= 1'b0;
            capdone <= 1'b0;
            cappos <= pos_state == POSM ? MPOSOFFS :
                      pos_state == POSR ? RPOSOFFS :
                                          LPOSOFFS;
            pos_cap_b <= pos_state;
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
              
    wire [STEP_SIZE-1:0] eff_pos_cap = pos_cap == POSM ? MPOSOFFS-1'b1 :
                                       pos_cap == POSR ? RPOSOFFS-1'b1 :
                                                         LPOSOFFS-1'b1;
                                                         
    reg [STEP_SIZE-1:0] user_cursor = 0;
    reg [STEP_SIZE-1:0] user_cursor_cnt;
    reg user_cursor_ena = 1'b0;
    
    reg [15:0] posctr = 0;
    wire touchinwav = touch && touchx <= TOPOFS+(WAVES-1)*WVSTEP+WHEIGHT && touchy <= YMAX-LEFTOFS;
    
    // counter to translate touch position into bitstep
    // hope this happens fast enough between touch and draw to draw in the right place :P
    always @(posedge clk) begin
        if(touchinwav || posctr > 0) begin
            if(posctr == 0) begin 
                posctr <= YMAX-touchy-LEFTOFS;
                user_cursor_cnt <= capstart;
            end else if(posctr <= WWIDTH) begin
                posctr <= 0;
                user_cursor <= user_cursor_cnt;
            end else begin
                posctr <= posctr - WWIDTH;
                user_cursor_cnt <= user_cursor_cnt + 1'b1;
            end
        end
    end
    
    always @(posedge clk or negedge arstn_sync) begin
        if(~arstn_sync) begin
            clr_ctr <= 1'b1;
            init_tft <= 1'b0;
            draw <= 1'b0;
            startcap <= 1'b0;
            uselogo <= 1'b0;
            gdraw <= 1'b0;
            drawgui <= 1'b0;
            start_rst <= 1'b0;
            rstcapstart <= 1'b0;
            step <= 0;
            capdone_c <= 1'b0;
            user_cursor_ena <= 1'b0;
        end else begin
            clr_ctr <= 1'b1;
            init_tft <= 1'b0;
            draw <= 1'b0;
            startcap <= 1'b0;
            uselogo <= 1'b0;
            gdraw <= 1'b0;
            drawgui <= 1'b0;
            start_rst <= 1'b0;
            rstcapstart <= 1'b0;
        
            // synchronize
            capdone_rr <= capdone;
            capdone_r <= capdone_rr;
            if(capdone_r && !capdone_rr) capdone_c <= 1'b1;
            
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
                DRAWLOGO : begin drawcmd <= {5'h00,6'h00,5'h00,  16'd0,    16'd0,           XMAX,       YMAX};  // logo background
                    uselogo <= 1'b1;
                    if(tft_done) begin
                        step <= WAITTOUCH;
                    end else draw <= 1'b1;
                end
                
                WAITTOUCH: begin
                    if(touch) step <= DRAWINIT;
                end  
                
                // blank screen                 R,    G,    B, xstart,   ystart,           xend,       yend
                DRAWINIT: begin drawcmd <= {5'h00,6'h00,5'h00,  16'd0,    16'd0,           XMAX,       YMAX};  // black background
                    if(tft_done) begin
                        step <= DRAWSTART;
                    end else draw <= 1'b1;
                end

                DOCAP: begin
                    if((start_state || cont_state) && !capdone_r) startcap <= 1'b1;
                    if(gupdate) begin
                        gdraw <= 1'b1;
                        drawgui <= 1'b1;
                        step <= DRAWGUI;
                    end else if(updwav) begin 
                        step <= DRAWSTART;
                    end else if(touchinwav) begin
                        step <= DRAWSTART;
                        user_cursor_ena <= 1'b1;
                    end else if(capdone_c) begin
                        capdone_c <= 1'b0;
                        step <= DRAWSTART;
                        start_rst <= 1'b1;
                        rstcapstart <= 1'b1;
                    end
                end
                
                // touchscreen test
                DRAWDOT: begin drawcmd <= {5'h00,6'h3f,5'h00, XMAX-touchx, YMAX-touchy, XMAX-touchx, YMAX-touchy};  // draw green dot
                    if((start_state || cont_state) && !capdone_r) startcap <= 1'b1;
                    if(tft_done) step <= DOCAP;
                    else draw <= 1'b1;
                end
                
                DRAWGUI: begin // handshake delay
                    drawgui <= 1'b1;
                    step <= DRAWGUI2;
                end    
                
                DRAWGUI2: begin 
                    drawgui <= 1'b1;
                    if(gdrawdone) begin
                        if(updwav) step <= DRAWSTART;
                        else step <= DOCAP;
                    end
                end
                
                // drawing program               R,    G,    B, xstart,   ystart,            xend,      yend
                DRAWSTART: begin drawcmd <= {5'h00,6'h00,5'h00, 16'd51,  LEFTOFS,   XMAX - TOPOFS,      YMAX};  // black background
                    if(tft_done) begin
                        xpos <= XMAX - TOPOFS;
                        ypos <= LEFTOFS;
                        bitstep <= capstart;
                        wave <= 0;
                        if(user_cursor_ena && user_cursor == capstart || eff_pos_cap == capstart) step<=DRAWPOS;
                        else if(wavedat[0][capstart]) step<=DRAWBIT1;
                        else step<=DRAWBIT0;
                    end else draw <= 1'b1;
                end
                
                DRAWPOS:    begin drawcmd <= (user_cursor_ena && user_cursor == bitstep)?
                                             {5'h00,6'h3f,5'h00, 16'd51, ypos, XMAX - TOPOFS, ypos}:  // green vertical line (cursor pos)
                                             {5'h00,6'h00,5'h1f, 16'd51, ypos, XMAX - TOPOFS, ypos};  // blue vertical line (capture pos)
                    if(tft_done) begin
                        if(bitstep && wavedat[0][bitstep-1] != wavedat[0][bitstep]) step<=DRAWVERT;
                        else if(wavedat[0][bitstep]) step<=DRAWBIT1;
                        else step<=DRAWBIT0;
                    end else draw <= 1'b1;
                end
                             
                DRAWBIT0:   begin drawcmd <= {5'h1f,6'h3f,5'h1f,  xpos-WHEIGHT, ypos,  xpos-WHEIGHT, ypos+WWIDTH};  // horizontal line
                    if(tft_done) begin
                        ypos <= ypos + WWIDTH;
                        bitstep <= bitstep+1;
                        step <= NEXTBIT;
                    end else draw <= 1'b1;
                end
                
                DRAWBIT1:   begin drawcmd <= {5'h1f,6'h3f,5'h1f,  xpos,         ypos,  xpos,         ypos+WWIDTH};  // horizontal line
                    if(tft_done) begin
                        ypos <= ypos + WWIDTH;
                        bitstep <= bitstep+1;
                        step <= NEXTBIT;
                    end else draw <= 1'b1;
                end
                
                DRAWVERT:   begin drawcmd <= {5'h1f,6'h3f,5'h1f,  xpos-WHEIGHT, ypos,  xpos,         ypos}; // vertical line
                    if(tft_done) begin 
                        if(wavedat[wave][bitstep]) step<=DRAWBIT1;
                        else step<=DRAWBIT0;
                    end else draw <= 1'b1;
                end
                
                NEXTBIT: begin 
                    if(bitstep == WHSTEPS-1 || bitstep == capstart+SCSTEPS) begin
                        if(wave == WAVES-1) step <= DOCAP;
                        else begin // next wave
                            xpos <= xpos - WVSTEP;
                            ypos <= LEFTOFS;
                            bitstep <= capstart;
                            wave <= wave+1;
                            if(wavedat[wave+1][capstart]) step<=DRAWBIT1;
                            else step<=DRAWBIT0;
                        end
                    end else begin // next bit of wave
                        if(wave == 0 && (user_cursor_ena && user_cursor == bitstep || eff_pos_cap == bitstep)) step<=DRAWPOS;
                        else if(wavedat[wave][bitstep-1] != wavedat[wave][bitstep]) step<=DRAWVERT;
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
    