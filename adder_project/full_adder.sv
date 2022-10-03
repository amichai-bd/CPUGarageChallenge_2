module full_adder (
	input  logic A,
	input  logic B,
	input  logic Cin,
	output logic Sum,
	output logic Cout
	);

	logic ha1_sum, ha2_sum;
	logic ha1_carry, ha2_carry;


half_adder ha1(
	.A   (A),
	.B   (B),
	.Sum (ha1_sum),
	.Cout(ha1_carry)
);
	
half_adder ha2(
	.A   (Cin),
	.B   (ha1_sum),
	.Sum (ha2_sum),
	.Cout(ha2_carry)
);

assign Cout = ha2_carry | ha1_carry;
assign Sum = ha2_sum;
	
endmodule