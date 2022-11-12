`define  DFF(q,i,clk)              \
         always_ff @(posedge clk)  \
            q<=i;

`define  EN_DFF(q,i,clk,en)        \
         always_ff @(posedge clk)  \
            if(en) q<=i;

`define  RST_DFF(q,i,clk,rst)           \
         always_ff @(posedge clk) begin \
            if (rst) q <='0;            \
            else     q <= i;            \
         end

`define  EN_RST_DFF(q,i,clk,en,rst)     \
         always_ff @(posedge clk)       \
            if (rst)    q <='0;         \
            else if(en) q <= i;



                
module grid (
    input    logic         clk,
    input    logic         resetN,
    input    logic [9:0]   SW,
    input    logic [31:0]  pxl_x,
    input    logic [31:0]  pxl_y,
    input    logic [11:0]  Wheel,
    input    logic         A,
    input    logic         B,
    input    logic         Select,
    input    logic         Start,
    input    logic         Right,
    input    logic         Left,
    input    logic         Up,
    input    logic         Down,
    output   logic [15:0]  GenCount,
    output   logic [3:0]   Red,
    output   logic [3:0]   Green,
    output   logic [3:0]   Blue,
    output   logic         Draw
);

`undef VERY_SMALL_GRID
`undef SMALL_GRID
`undef BIG_GRID
`define VERY_SMALL_GRID 
//`define SMALL_GRID 
//`define BIG_GRID 

localparam BASE_WAIT_TIME = 'h4_0000;

`ifdef SMALL_GRID
    localparam GRID_MSB = 4;
    localparam ROW_MSB  = 14;
    localparam COL_MSB  = 19;
`elsif  VERY_SMALL_GRID
    localparam GRID_MSB = 5;
    localparam ROW_MSB  = 7;
    localparam COL_MSB  = 9;
`elsif BIG_GRID
    localparam GRID_MSB = 3;//3;
    localparam ROW_MSB  = 29;//29;
    localparam COL_MSB  = 39;//39;
`endif


localparam O = 1'b0;
localparam X = 1'b1;

logic                             draw_line;
logic [0:ROW_MSB] [0:COL_MSB]     next_alive;
logic [0:ROW_MSB] [0:COL_MSB]     alive     ;
logic [0:ROW_MSB] [0:COL_MSB]     cursor;



logic [3:0]      set_cell;
logic            set_cursor;
logic            reset;
logic [99:0]     shift_reset;

assign reset = ~resetN;



assign draw_line = (pxl_x[GRID_MSB:0]==4'b0) || (pxl_y[GRID_MSB:0]==4'b0);
assign Draw = 1'b1;
assign Red  = draw_line  ? 4'h0     : 
              set_cursor ? 4'hf     :
                           set_cell ;
                                     
assign Green = draw_line  ? 4'h0     : 
               set_cursor ? 4'h0     :
                           set_cell ;
                                     
assign Blue     = draw_line  ? 4'h0     : 
                  set_cursor ? 4'h0     :
                               set_cell ;

assign set_cell   = {4{!alive[ pxl_y[31:GRID_MSB+1] ] [ pxl_x[31:GRID_MSB+1] ]}};
assign set_cursor =    cursor[ pxl_y[31:GRID_MSB+1] ] [ pxl_x[31:GRID_MSB+1] ];


logic [29:0] cycle_count;
logic        reset_count;
logic        enable_gen;

logic [5:0]   x_pos;
logic [26:0]  pre_x_pos;
logic [26:0]  x_next_pos;

logic [4:0]   y_pos;
logic [25:0]  pre_y_pos;
logic [25:0]  y_next_pos;



int count;
always_comb begin
    next_alive = alive;
	 count = 0;
	if(enable_gen && (Wheel[11:8] != '0) ) begin
        for(int row = 0; row<ROW_MSB+1; row++) begin
            for(int col = 0; col<COL_MSB+1; col++) begin
       		    if((row == '0 )||(col == 0) || (row == ROW_MSB) || (col == COL_MSB)) begin
       		        next_alive[row][col] = 1'b0;
				end else begin 
                	count =     alive[row-1][col-1] +// top left
                	            alive[row-1][col  ] +// top 
                	            alive[row-1][col+1] +// top right
                	            alive[row  ][col-1] +// left
                	            alive[row  ][col+1] +// right
                	            alive[row+1][col-1] +// bottom left
                	            alive[row+1][col  ] +// bottom
                	            alive[row+1][col+1]; // bottom right
                	if(alive[row][col]) begin
                	    next_alive[row][col] = (count == 2) ? 1'b1 : // Cell dont Change
                	                           (count == 3) ? 1'b1 : // Cell Dont Change
                	                                          1'b0 ; // Kill Cell
                	end else begin //cell was dead
                	    next_alive[row][col] = (count == 3) ? 1'b1 : // new cell born
                	                                          1'b0 ; // do nothing
                	end//if else
                end//if else
            end//for col
        end//for row
	end//enable gen

    if(shift_reset[99] || reset) begin
        next_alive = '0;
    `ifdef SMALL_GRID  //0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19
        next_alive[1]  = {O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[2]  = {O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[3]  = {O, O, O, O, O, X, X, X, O, O, O, X, O, O, O, X, O, O, O, X};
        next_alive[4]  = {O, O, O, O, X, O, O, O, O, O, X, O, X, O, O, X, X, O, X, X};
        next_alive[5]  = {O, O, O, O, X, O, O, O, O, X, O, O, O, X, O, X, O, X, O, X};
        next_alive[6]  = {O, O, O, O, X, O, X, X, O, X, X, X, X, X, O, X, O, O, O, X};
        next_alive[7]  = {O, O, O, O, X, O, O, X, O, X, O, O, O, X, O, X, O, O, O, X};
        next_alive[8]  = {O, O, O, O, O, X, X, X, O, X, O, O, O, X, O, X, O, O, O, X};
        next_alive[9]  = {O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[10] = {O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[11] = {O, O, O, O, O, O, O, O, O, O, O, O, X, X, O, O, X, X, X, X};
        next_alive[12] = {O, O, O, O, O, O, O, O, O, O, O, X, O, O, X, O, X, O, O, O};
        next_alive[13] = {O, O, O, O, O, O, O, O, O, O, O, X, O, O, X, O, X, X, X, O};
        next_alive[14] = {O, O, O, O, O, O, O, O, O, O, O, X, O, O, X, O, X, O, O, O};
    `elsif VERY_SMALL_GRID// 1  2  3  4  5  6  7  8  9
    if(SW[0]) begin
        next_alive[1]  = {O, O, X, O, O, O, O, O, O, O};
        next_alive[2]  = {O, O, O, X, O, O, O, O, O, O};
        next_alive[3]  = {O, X, X, X, O, O, O, O, O, O};
        next_alive[4]  = {O, O, O, O, O, O, O, O, O, O};
        next_alive[5]  = {O, O, O, O, O, O, O, O, O, O};
        next_alive[6]  = {O, O, O, O, O, O, O, O, O, O};
        next_alive[7]  = {O, O, O, O, O, O, O, O, O, O};
    end else begin
        next_alive[1]  = {O, O, O, O, O, O, O, O, O, O};
        next_alive[2]  = {O, X, X, X, X, X, X, X, X, O};
        next_alive[3]  = {O, X, O, O, O, O, O, O, X, O};
        next_alive[4]  = {O, X, O, X, X, X, X, O, O, O};
        next_alive[5]  = {O, O, X, O, O, O, O, X, O, O};
        next_alive[6]  = {O, X, O, X, X, X, X, O, X, O};
        next_alive[7]  = {O, O, O, O, O, O, O, O, O, O};
    end
    `elsif BIG_GRID   //  0 1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39
        next_alive[1]  = {O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[2]  = {O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[3]  = {O, O, O, O, O, X, X, X, O, O, O, X, O, O, O, X, O, O, O, X, O, X, X, X, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[4]  = {O, O, O, O, X, O, O, O, O, O, X, O, X, O, O, X, X, O, X, X, O, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[5]  = {O, O, O, O, X, O, O, O, O, X, O, O, O, X, O, X, O, X, O, X, O, X, X, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[6]  = {O, O, O, O, X, O, X, X, O, X, X, X, X, X, O, X, O, O, O, X, O, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[7]  = {O, O, O, O, X, O, O, X, O, X, O, O, O, X, O, X, O, O, O, X, O, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[8]  = {O, O, O, O, O, X, X, X, O, X, O, O, O, X, O, X, O, O, O, X, O, X, X, X, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[9]  = {O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[10] = {O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[11] = {O, O, O, O, O, O, O, O, O, O, O, O, X, X, O, O, X, X, X, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[12] = {O, O, O, O, O, O, O, O, O, O, O, X, O, O, X, O, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[13] = {O, O, O, O, O, O, O, O, O, O, O, X, O, O, X, O, X, X, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[14] = {O, O, O, O, O, O, O, O, O, O, O, X, O, O, X, O, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[15] = {O, O, O, O, O, O, O, O, O, O, O, X, O, O, X, O, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[16] = {O, O, O, O, O, O, O, O, O, O, O, O, X, X, O, O, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[17] = {O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[18] = {O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[19] = {O, O, O, O, O, X, O, O, O, O, X, X, X, O, X, X, X, X, O, X, X, X, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[20] = {O, O, O, O, O, X, O, O, O, O, O, X, O, O, X, O, O, O, O, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[21] = {O, O, O, O, O, X, O, O, O, O, O, X, O, O, X, X, X, O, O, X, X, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[22] = {O, O, O, O, O, X, O, O, O, O, O, X, O, O, X, O, O, O, O, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[23] = {O, O, O, O, O, X, O, O, O, O, O, X, O, O, X, O, O, O, O, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[24] = {O, O, O, O, O, X, X, X, X, O, X, X, X, O, X, O, O, O, O, X, X, X, X, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[25] = {O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[26] = {O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[27] = {O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[28] = {O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
        next_alive[29] = {O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O, O};
    `endif
    end

	if(A)  next_alive[y_pos][x_pos] = 1'b1;
	if(B)  next_alive[y_pos][x_pos] = 1'b0;
end


assign shift_reset[0] = reset;
`DFF(shift_reset[99:1], shift_reset[98:0], clk)



//==============================
//used for timing a new_gen
//==============================
assign reset_count = (cycle_count > (BASE_WAIT_TIME>>Wheel[11:8]));
`RST_DFF(cycle_count, cycle_count + 30'h1, clk, (reset || reset_count))


//==============================
// Count Generations
//==============================
`EN_RST_DFF(GenCount, GenCount + 30'h1, clk, reset_count, reset)

//=================
// Move cursor using joystick
//=================
assign x_next_pos = Left  && (x_pos != '0     ) ? pre_x_pos - 5'h1 :
                    Right && (x_pos != COL_MSB) ? pre_x_pos + 5'h1 :
                                                  pre_x_pos;
assign y_next_pos = Up    && (y_pos != '0     ) ? pre_y_pos - 5'h1 :
                    Down  && (y_pos != ROW_MSB) ? pre_y_pos + 5'h1 :
                           						  pre_y_pos;

`RST_DFF(pre_x_pos, x_next_pos , clk, (reset))
`RST_DFF(pre_y_pos, y_next_pos , clk, (reset))

assign x_pos = pre_x_pos[26:21];
assign y_pos = pre_y_pos[25:21];

always_comb begin
    cursor = '0;
    cursor[y_pos][x_pos]  = 1'b1;



    //test Wheel
    cursor[0][Wheel[11:8]] = 1'b1;
end


assign enable_gen = (cycle_count==30'b0);
`DFF(alive, next_alive, clk)


endmodule 