
module half_adder(
	input  logic A,
	input  logic B,
	output logic Sum,
	output logic Cout
	);

	
	assign Sum  = A^B;
	assign Cout = A&B;
	
	
endmodule 