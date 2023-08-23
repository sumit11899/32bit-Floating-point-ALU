`timescale 1 ns / 1 ps
module Testbench8BitKoggeStoneAdder;
    reg [7:0] A, B;
    reg Cin;
    wire Cout, overflowFlag;
    wire [7:0] S;
    EightBitKoggeStoneAdder EBKSAT (A, B, Cin, Cout, S, overflowFlag);
    initial
        begin
            $monitor ($time, ": A = %b, B = %b, Cin = %b, Cout = %b, S = %b", A, B, Cin, Cout, S);
            A = 8'd0;
            B = 8'd0;
            Cin = 1'b0;
            #5 Cin = 1'b1;
            #5 A = 8'b10010110;
            B = 8'b11001010;
            Cin = 1'b0;
            #5 Cin = 1'b1;
            #5 A = 8'b00100111;
            B = 8'b10011011;
            Cin = 1'b0;
            #5 Cin = 1'b1;
            #5 $finish;
        end
endmodule