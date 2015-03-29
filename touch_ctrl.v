// talk to FT6206 capacative touch screen via i2c

module touch_ctrl #(
    parameter ADDR = 7'h38, // FT6206 i2c address
    //(50MHz/(5*200kHZ)-1 = 49)
    // FT6206 says up to 400kHz... 200 seems safe in case input
    // clock is actually 100MHz.
    parameter SCALE = 16'd49,
    // threshold, grabbed from Adafruit code
    parameter THRESH = 8'd128
)(
    input clk,
    input arstn,
    
    output reg touch,
    output reg [15:0] touchx,
    output reg [15:0] touchy,
    
    // i2c interface
    inout scl,
    inout sda
);

    reg [15:0] touchx_hold;
    reg [15:0] touchy_hold;
    reg [2:0] touch_byte; // 0 = touch, 1 = xh, 2 = xl, 3 = yh, 4 = yl
    reg touch_hold;

    reg  [2:0] adr;
    reg  [7:0] dat_i;
    wire [7:0] dat_o;
    reg  we;
    reg  cyc;
    wire ack;
    
    wire scl_pad_o, scl_padoen_o;
    wire sda_pad_o, sda_padoen_o;

    assign sda = sda_padoen_o ? 1'bz : sda_pad_o;
    assign scl = scl_padoen_o ? 1'bz : scl_pad_o;

    i2c_master_top i2c
    (
        .wb_clk_i(clk),
        .wb_rst_i(1'b0), // this one's active high
        .arst_i(arstn),  // this one's active low

        .wb_adr_i(adr),
        .wb_dat_i(dat_i),
        .wb_dat_o(dat_o),
        .wb_we_i(we),
        .wb_stb_i(1'b1),
        .wb_cyc_i(cyc),
        .wb_ack_o(ack),
        .wb_inta_o(),

        .scl_pad_i(scl),
        .scl_pad_o(scl_pad_o),
        .scl_padoen_o(scl_padoen_o),
        .sda_pad_i(sda),
        .sda_pad_o(sda_pad_o),
        .sda_padoen_o(sda_padoen_o)
    );
    
    reg [5:0] state = 6'b0;
    
    // opencores i2c controller regs
    localparam I2C_PRERLO = 3'd0;
    localparam I2C_PRERHI = 3'd1;
    localparam I2C_CTR    = 3'd2;
    localparam I2C_TXR    = 3'd3;
    localparam I2C_RXR    = 3'd3;
    localparam I2C_CR     = 3'd4;
    localparam I2C_SR     = 3'd4;
    
    // CR register commands
    localparam CMD_STA  = 8'b1000_0000;
    localparam CMD_STO  = 8'b0100_0000;
    localparam CMD_RD   = 8'b0010_0000;
    localparam CMD_WR   = 8'b0001_0000;
    localparam CMD_NACK = 8'b0000_1000;
    localparam CMD_IACK = 8'b0000_0001;
    
    // RX register status
    localparam ST_ACK = 8'b1000_0000;
    localparam ST_BSY = 8'b0100_0000;
    localparam ST_AL  = 8'b0010_0000;
    localparam ST_TIP = 8'b0000_0010;
    localparam ST_IF  = 8'b0000_0001;
    
    // FT6206 regs
    localparam FT6206_NTOUCH = 8'h02;
    localparam FT6206_T1_XHI = 8'h03;
    localparam FT6206_T1_XLO = 8'h04;
    localparam FT6206_T1_YHI = 8'h05;
    localparam FT6206_T1_YLO = 8'h06;
    localparam FT6206_THRESH = 8'h80;
    
    always @(posedge clk or negedge arstn) begin
        if(!arstn) begin
            state <= 0;
            adr <= 3'b0;
            dat_i <= 8'b0;
            we <= 1'b0;
            cyc <= 1'b0;
            touch <= 1'b0;
            touchx <= 16'b0;
            touchy <= 16'b0;
            touch_byte <= 0;
            touch_hold <= 0;
            touchx_hold <= 16'b0;
            touchy_hold <= 16'b0;
        end else begin
            adr <= 3'b0;
            dat_i <= 8'b0;
            we <= 1'b0;
            cyc <= 1'b0;
            case (state)
                0:  // idle init
                    if(~ack) state <= 1;

                1: // i2c Clock Prescale lo-byte 
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b1;
                        adr <= I2C_PRERLO;
                        dat_i <= SCALE[7:0];
                    end else state <= state+1;
                    
                2: // i2c Clock Prescale hi-byte
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b1;
                        adr <= I2C_PRERHI;
                        dat_i <= SCALE[15:8];
                    end else state <= state+1;
                    
                3: // i2c EN
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b1;
                        adr <= I2C_CTR;
                        dat_i <= 8'h80;
                    end else state <= state+1;
                    
                4: // i2c Read Status Reg to clear anything
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b0;
                        adr <= I2C_SR;
                    end else state <= state+1;
                    
                    
                5: // WRITE THRESHOLD: set slave address, WR
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b1;
                        adr <= I2C_TXR;
                        dat_i <= {ADDR, 1'b0};
                    end else state <= state+1;
                    
                6: // WRITE THRESHOLD: (saddress) generate start, write
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b1;
                        adr <= I2C_CR;
                        dat_i <= CMD_STA | CMD_WR;
                    end else state <= state+1;
                    
                7: // WRITE THRESHOLD: (saddress) wait for ~TIP
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b0;
                        adr <= I2C_SR;
                    end else begin
                        if(dat_o & ST_TIP) state <= state; // wait for complete
                        else if(dat_o & ST_ACK) state <= state-1; // redo if no ack
                        else state <= state+1;
                    end
                    
                    
                8: // WRITE THRESHOLD: set data address
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b1;
                        adr <= I2C_TXR;
                        dat_i <= FT6206_THRESH;
                    end else state <= state+1;
                    
                9: // WRITE THRESHOLD: (daddress) write
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b1;
                        adr <= I2C_CR;
                        dat_i <= CMD_WR;
                    end else state <= state+1;
                    
                10: // WRITE THRESHOLD: (daddress) wait for ~TIP
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b0;
                        adr <= I2C_SR;
                    end else begin
                        if(dat_o & ST_TIP) state <= state; // wait for complete
                        else state <= state+1;
                    end
                    
                    
                11: // WRITE THRESHOLD: set data
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b1;
                        adr <= I2C_TXR;
                        dat_i <= THRESH;
                    end else state <= state+1;
                    
                12: // WRITE THRESHOLD: (data) write, stop
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b1;
                        adr <= I2C_CR;
                        dat_i <= CMD_STO | CMD_WR;
                    end else state <= state+1;
                    
                13: // WRITE THRESHOLD: (data) wait for ~TIP
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b0;
                        adr <= I2C_SR;
                    end else begin
                        if(dat_o & ST_TIP) state <= state; // wait for complete
                        else state <= state+1;
                    end
                    
                    
                14: // READ TOUCHES: set slave address, WR
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b1;
                        adr <= I2C_TXR;
                        dat_i <= {ADDR, 1'b0};
                    end else state <= state+1;
                    
                15: // READ TOUCHES: (saddress) generate start, write
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b1;
                        adr <= I2C_CR;
                        dat_i <= CMD_STA | CMD_WR;
                    end else state <= state+1;
                    
                16: // READ TOUCHES: (saddress) wait for ~TIP
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b0;
                        adr <= I2C_SR;
                    end else begin
                        if(dat_o & ST_TIP) state <= state; // wait for complete
                        else if(dat_o & ST_ACK) state <= state-1; // redo if no ack
                        else state <= state+1;
                    end
                    
                    
                17: // READ TOUCHES: set data address
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b1;
                        adr <= I2C_TXR;
                        dat_i <= FT6206_NTOUCH;
                    end else state <= state+1;
                    
                18: // READ TOUCHES: (daddress) write, stop
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b1;
                        adr <= I2C_CR;
                        dat_i <= CMD_STO | CMD_WR;
                    end else state <= state+1;
                    
                19: // READ TOUCHES: (daddress) wait for ~TIP
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b0;
                        adr <= I2C_SR;
                    end else begin
                        if(dat_o & ST_TIP) state <= state; // wait for complete
                        else state <= state+1;
                    end
                    
                    
                20: // READ TOUCHES: set slave address, RD
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b1;
                        adr <= I2C_TXR;
                        dat_i <= {ADDR, 1'b1};
                    end else state <= state+1;
                    
                21: // READ TOUCHES: (saddress) generate start, write
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b1;
                        adr <= I2C_CR;
                        dat_i <= CMD_STA | CMD_WR;
                    end else state <= state+1;
                    
                22: // READ TOUCHES: (saddress) wait for ~TIP
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b0;
                        adr <= I2C_SR;
                    end else begin
                        if(dat_o & ST_TIP) state <= state; // wait for complete
                        else if(dat_o & ST_ACK) state <= state-1; // redo if no ack
                        else state <= state+1;
                    end
                    
                    
                23: // READ TOUCHES: (data) read, nack, stop
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b1;
                        adr <= I2C_CR;
                        if(touch_byte == 3'd4) // nack on last byte
                            dat_i <= CMD_STO | CMD_NACK | CMD_RD;
                        else
                            dat_i <= CMD_RD;
                    end else state <= state+1;
                    
                24: // READ TOUCHES: (data) wait for ~TIP
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b0;
                        adr <= I2C_SR;
                    end else begin
                        if(dat_o & ST_TIP) state <= state; // wait for complete
                        else state <= state+1;
                    end
                    
                25: // READ TOUCHES: (data) read data
                    if(~ack) begin
                        cyc <= 1'b1;
                        we <= 1'b0;
                        adr <= I2C_RXR;
                    end else begin
                        touch_byte <= touch_byte+1;
                        state <= 23; // continue read
                        case(touch_byte)
                            3'd0: touch_hold <= (dat_o == 2'b01 || dat_o == 2'b10); // accept 1 or 2 touches
                            3'd1: touchx_hold[15:8] <= {4'b0, dat_o[3:0]};
                            3'd2: touchx_hold[7:0]  <= dat_o[7:0];
                            3'd3: touchy_hold[15:8] <= {4'b0, dat_o[3:0]};
                            3'd4: begin
                                touch <= touch_hold;
                                touchx <= touchx_hold;
                                touchy <= {touchy_hold[15:8], dat_o[7:0]};
                                touch_byte <= 0;
                                state <= 14; // loop forever!
                            end
                            default: begin
                                touch_byte <= 0;
                                state <= 14;
                            end
                        endcase
                    end
                    
                
                default: state <= 0;
            endcase
        end
    end

endmodule
    