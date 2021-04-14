module traffic_light (
    input  clk,
    input  rst,
    input  pass,
    output reg R,
    output reg G,
    output reg Y
);
//write your code here
parameter none = 2'h0;
parameter red  = 2'h1;
parameter yellow = 2'h2;
parameter green = 2'h3;

reg [14:0] count;
reg [1:0] state;
reg state_1;

initial begin
    count <= 0;
    state <= green;
    state_1 <= 1;
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        count = 0;
    end
    else if(count < 3071) begin
        if(pass & (~state_1)) begin
            count = 0;
        end
        else
            count = count + 1;
    end
    else 
        count = 0;
end

/*
always @(posedge pass or posedge rst) begin
    if(pass) begin
        if(~state_1)
            count <= 0;
    end
    if(rst)
        count <= 0;
end
*/

always @(posedge clk) begin
    if(count < 1024) begin
        state = green;
        state_1 = 1;
    end
    else if(count < 1152) begin
        state = none;
        state_1 = 0;
    end
    else if(count < 1280) begin
        state = green;
        state_1 = 0;
    end
    else if(count < 1408) begin
        state = none;
        state_1 = 0;
    end
    else if(count < 1536) begin
        state = green;
        state_1 = 0;
    end
    else if(count < 2048) begin
        state = yellow;
        state_1 = 0;
    end
    else if(count < 3072) begin
        state = red;
        state_1 = 0;
    end
end

always @(state) begin
    case(state)
        none: begin
            R = 0;
            G = 0;
            Y = 0;
            end
        red: begin
            R = 1;
            G = 0;
            Y = 0;
            end
        yellow: begin
            R = 0;
            G = 0;
            Y = 1;
            end
        green: begin
            R = 0;
            G = 1;
            Y = 0;
            end
    endcase
end

endmodule
