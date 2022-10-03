`define  RST_DFF(q,i,clk,rst)          \
         always_ff @(posedge clk) begin\
            if (rst) q <='0;           \
            else     q <= i;           \
         end
`define  RSTD_DFF(q,i,clk,rst,data)    \
         always_ff @(posedge clk) begin\
            if (rst) q <= data;        \
            else     q <= i;           \
         end


module traffic_light (
    input   logic Clock,
    input   logic Reset,
    output  logic Red,
    output  logic Yellow,
    output  logic Green
);

localparam TIME_RED           = 3;
localparam TIME_GREEN         = 3;
localparam TIME_YELLOW        = 3;
localparam TIME_RED_YELLOW    = 3;

typedef enum logic [1:0] { 
    S_RED           = 2'b00,
    S_GREEN         = 2'b01,
    S_YELLOW        = 2'b10,
    S_RED_YELLOW    = 2'b11
} t_state;


logic [9:0] Counter;
logic [9:0] NextCounter;
logic       RstCount;
t_state     State;
t_state     NextState;

`RSTD_DFF(State,   NextState,   Clock, Reset, S_RED)
`RST_DFF(Counter, NextCounter, Clock, Reset || RstCount)
always_comb begin
    NextState = State;
    RstCount = 1'b0;
    NextCounter = Counter + 1'b1;
    unique casez (State)
        //=====================================================
        S_RED        :  if (Counter > TIME_RED       ) begin
                            NextState = S_RED_YELLOW;
                            RstCount = 1'b1;
                        end
        //=====================================================
        S_GREEN      :  if (Counter > TIME_GREEN     ) begin
                            NextState = S_YELLOW;
                            RstCount = 1'b1;
                        end
        //=====================================================
        S_YELLOW     :  if (Counter > TIME_YELLOW    ) begin
                            NextState = S_RED;
                            RstCount = 1'b1;
                        end
        //=====================================================
        S_RED_YELLOW :  if (Counter > TIME_RED_YELLOW) begin
                            NextState = S_GREEN;
                            RstCount = 1'b1;
                        end
        //=====================================================
        default      :  NextState = State;// should not accure
    endcase    
end //always

assign Red      = (State == S_RED)    | (State == S_RED_YELLOW);
assign Yellow   = (State == S_YELLOW) | (State == S_RED_YELLOW);
assign Green    = (State == S_GREEN);

endmodule