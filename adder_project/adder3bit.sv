
module adder3bit(
	input  logic[2:0] A,
	input  logic[2:0] B,
	output logic[2:0] Sum,
	output logic      Cout
	);

logic [2:0] ripple;

assign ripple[0] =1'b0;

full_adder fa1(
	.A   (A[0]     ),
	.B   (B[0]     ),
	.Cin (ripple[0]),
	.Sum (Sum[0]   ),
	.Cout(ripple[1])
);	

full_adder fa2(
	.A   (A[1]     ),
	.B   (B[1]     ),
	.Cin (ripple[1]),
	.Sum (Sum[1]   ),
	.Cout(ripple[2])
);	

full_adder fa3(
	.A   (A[2]     ),
	.B   (B[2]     ),
	.Cin (ripple[2]),
	.Sum (Sum[2]   ),
	.Cout(Cout     )
);	

endmodule 