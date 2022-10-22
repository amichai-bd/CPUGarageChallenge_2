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
`define  EN_DFF(q,i,clk,en)            \
         always_ff @(posedge clk) begin\
            if (en) q <= i;            \
         end



module psm (
    input   logic       Clock,
    input   logic       Reset_N,
    input   logic [2:0] Din1,
    input   logic [2:0] Din2,
    input   logic       Start_N,
    output  logic       Ready,
    output  logic       Op1,
    output  logic       Op2,
    output  logic       Op3,
    output  logic [2:0] Dout
);


// Amichi ID: 3_085_1_391_8 -> 3 , 1 , 8
localparam TIME_OP1 = 30_000_000;
localparam TIME_OP2 = 10_000_000;
localparam TIME_OP3 = 80_000_000;

typedef enum logic [1:0] { 
    S_READY      = 2'b00,
    S_OP1        = 2'b01,
    S_OP2        = 2'b10,
    S_OP3        = 2'b11
} t_state;

logic [31:0] Counter;
logic [31:0] NextCounter;
logic       RstCount;
t_state     State;
t_state     NextState;
logic [2:0] A;
logic [2:0] B;
logic Reset;
logic Start;
assign Start = ~Start_N;
assign Reset = ~Reset_N;
//=====================================================
assign Op1  = (State == S_OP1);
assign Op2  = (State == S_OP2);
assign Op3  = (State == S_OP3);
assign Ready= (State == S_READY);
assign Dout =   Op1 ? (A | B)      :
                Op2 ? (A ^ B)      :
                Op3 ? (~((~A) & B)):
                      '0                 ; 
//=====================================================
logic SamplStart;
logic StartDiv;
`RST_DFF(SamplStart,  Start, Clock,  Reset)
assign StartDiv = Start && (!SamplStart);

//=====================================================
`RSTD_DFF(State,  NextState,      Clock,  Reset, S_READY)
`RST_DFF(Counter, NextCounter, Clock, (Reset || RstCount || StartDiv))
`EN_DFF(A, Din1, Clock, StartDiv)
`EN_DFF(B, Din2, Clock, StartDiv)

always_comb begin
    NextState = State;
    RstCount  = 1'b0;
    NextCounter = Counter + 1'b1;
    unique casez (State)
        //=====================================================
        S_READY     :   if (StartDiv) begin
                            NextState = S_OP1;
                            RstCount = 1'b1;
                        end
        //=====================================================
        S_OP1       :   if (NextCounter == TIME_OP1     ) begin
                            NextState = S_OP2;
                            RstCount = 1'b1;
                        end
        //=====================================================
        S_OP2       :   if (NextCounter == TIME_OP2    ) begin
                            NextState = S_OP3;
                            RstCount = 1'b1;
                        end
        //=====================================================
        S_OP3       :   if (NextCounter == TIME_OP3) begin
                            NextState = S_READY;
                            RstCount = 1'b1;
                        end
        //=====================================================
        default      :  NextState = State;// should not accure
    endcase    
end //always

endmodule