module simple_spi #(
    parameter CLK_DIV = 2, // if clk is 50Mhz, 2 will produce ~8.3Mhz
    parameter CLK_DIV_BITS = 2
) (
    input clk,
    
    // chip select is controlled externally
    // no read right now, only write
    output reg sclk,
    output mosi,
    
    input go,
    output reg done = 1'b1,
    input [7:0] data_in
);

reg [2:0] dbit = 2'b0;
reg [7:0] shift_reg;
reg [CLK_DIV_BITS-1:0] cnt;

assign mosi = shift_reg[7];

always @(posedge clk) begin
    if(!done) begin
        if(cnt == CLK_DIV) begin
            cnt <= 0;
            sclk <= ~sclk;
            if(sclk) begin // falling edge, update data bit
                shift_reg <= {shift_reg[6:0], 1'b0};
                dbit <= dbit-1;
                if(dbit == 0) done <= 1'b1;
            end
        end else
            cnt <= cnt+1;
    end else if(go) begin
        dbit <= 3'd7;
        shift_reg <= data_in;
        done <= 1'b0;
        cnt <= 0;
        sclk <= 1'b0;
    end
end

endmodule
