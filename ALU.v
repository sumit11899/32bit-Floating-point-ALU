`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////////
// Design Name   : Arithmetic Logical Unit
// Module Name   : ALU
// Target Devices: Nexys4 DDR FPGA
// Tool Versions : Vivado 2020.2
// Description   : ALU performs addition, subtraction, multiplication, AND, OR, NOT,XOR and NOP based on 8-bit Kogge-Stone Adder
//////////////////////////////////////////////////////////////////////////////////
module PreProcessingGP (input x,input y,output G,output P);
    assign G = (x & y);
    assign P = (x ^ y);
endmodule
module GrayCell (input Gikp1,input Pikp1,input Gkj,output Gij);
    assign Gij = (Gikp1 | (Pikp1 & Gkj));
endmodule
module BlackCell (input Gikp1,input Pikp1,input Gkj,input Pkj,output Gij,output Pij);
    assign Gij = (Gikp1 | (Pikp1 & Gkj));
    assign Pij = (Pikp1 & Pkj);
endmodule
module EightBitKoggeStoneAdder (input [7:0] A,input [7:0] B,input Cin,output Cout,output [7:0] S,output overflowFlag);
    wire [7:0] G0, P0, G1, P1, G2, P2, G3, P3;
    // preprocessing layer
    PreProcessingGP GP0 (A[0], B[0], G0[0], P0[0]);
    PreProcessingGP GP1 (A[1], B[1], G0[1], P0[1]);
    PreProcessingGP GP2 (A[2], B[2], G0[2], P0[2]);
    PreProcessingGP GP3 (A[3], B[3], G0[3], P0[3]);
    PreProcessingGP GP4 (A[4], B[4], G0[4], P0[4]);
    PreProcessingGP GP5 (A[5], B[5], G0[5], P0[5]);
    PreProcessingGP GP6 (A[6], B[6], G0[6], P0[6]);
    PreProcessingGP GP7 (A[7], B[7], G0[7], P0[7]);
    // carry lookahead - layer 1
    GrayCell GC10 (G0[0], P0[0], Cin, G1[0]);
    BlackCell BC11 (G0[1], P0[1], G0[0], P0[0], G1[1], P1[1]);
    BlackCell BC12 (G0[2], P0[2], G0[1], P0[1], G1[2], P1[2]);
    BlackCell BC13 (G0[3], P0[3], G0[2], P0[2], G1[3], P1[3]);
    BlackCell BC14 (G0[4], P0[4], G0[3], P0[3], G1[4], P1[4]);
    BlackCell BC15 (G0[5], P0[5], G0[4], P0[4], G1[5], P1[5]);
    BlackCell BC16 (G0[6], P0[6], G0[5], P0[5], G1[6], P1[6]);
    BlackCell BC17 (G0[7], P0[7], G0[6], P0[6], G1[7], P1[7]);
    // carry lookahead - layer 2
    GrayCell GC21 (G1[1], P1[1], Cin, G2[1]);
    GrayCell GC22 (G1[2], P1[2], G1[0], G2[2]);
    BlackCell BC23 (G1[3], P1[3], G1[1], P1[1], G2[3], P2[3]);
    BlackCell BC24 (G1[4], P1[4], G1[2], P1[2], G2[4], P2[4]);
    BlackCell BC25 (G1[5], P1[5], G1[3], P1[3], G2[5], P2[5]);
    BlackCell BC26 (G1[6], P1[6], G1[4], P1[4], G2[6], P2[6]);
    BlackCell BC27 (G1[7], P1[7], G1[5], P1[5], G2[7], P2[7]);
    // carry lookahead - layer 3
    GrayCell GC33 (G2[3], P2[3], Cin, G3[3]);
    GrayCell GC34 (G2[4], P2[4], G1[0], G3[4]);
    GrayCell GC35 (G2[5], P2[5], G2[1], G3[5]);
    GrayCell GC36 (G2[6], P2[6], G2[2], G3[6]);
    BlackCell BC37 (G2[7], P2[7], G2[3], P2[3], G3[7], P3[7]);
    // carry lookahead - layer 4
    GrayCell GC47 (G3[7], P3[7], Cin, Cout);
    // post-processing - sum bits
    assign S[0] = (Cin ^ P0[0]);
    assign S[1] = (G1[0] ^ P0[1]);
    assign S[2] = (G2[1] ^ P0[2]);
    assign S[3] = (G2[2] ^ P0[3]);
    assign S[4] = (G3[3] ^ P0[4]);
    assign S[5] = (G3[4] ^ P0[5]);
    assign S[6] = (G3[5] ^ P0[6]);
    assign S[7] = (G3[6] ^ P0[7]);
    // overflow flag
    assign overflowFlag = (G3[6] ^ Cout);
endmodule
module Adder16Bit (input [15:0] A,input [15:0] B,input Cin,output Cout,output [15:0] O,output overflowFlag);
    wire C_i;
    wire dummyOverflow;
    EightBitKoggeStoneAdder A1 (A[7:0], B[7:0], Cin, C_i, O[7:0], dummyOverflow);
    EightBitKoggeStoneAdder A2 (A[15:8], B[15:8], C_i, Cout, O[15:8], overflowFlag);
endmodule
module ALU (input [7:0] A,input [7:0] B,input [2:0] S,output reg [15:0] O,output reg zeroFlag,output reg carryFlag,output reg signFlag,output reg overflowFlag);
    parameter [2:0] Addition = 3'b000,Subtraction = 3'b001,Multiplication = 3'b010,AND = 3'b011,OR = 3'b100,NOT = 3'b101,XOR = 3'b110;
    wire carryFlag_A, overflowFlag_A, carryFlag_S, overflowFlag_S;
    wire [7:0] Add, Sub;
    wire [7:0] Ap_i, Bp_i;
    wire [7:0] Ap, Bp;
    wire [7:0] And, Or, Not, Xor;
    wire sign;
    wire dummyA, dummyB, dummyC, dummyD, dummyE, dummyF, dummyG, dummyH, dummyI, dummyJ;
    wire dummyA1, dummyB1, dummyC1, dummyD1, dummyE1, dummyF1, dummyG1, dummyH1, dummyI1, dummyJ1;
    wire [15:0] Mul, MulA, MulB, MulC, MulD, MulE, MulF, MulG, MulH, MulI;
    EightBitKoggeStoneAdder MA (A, B, 1'b0, carryFlag_A, Add, overflowFlag_A);
    EightBitKoggeStoneAdder MS1 ((~B), 8'd0, 1'b1, dummyB, Bp_i, dummyB1);
    EightBitKoggeStoneAdder MS2 (A, Bp_i, 1'b0, carryFlag_S, Sub, overflowFlag_S);
    EightBitKoggeStoneAdder MM1 ((~A), 8'd0, 1'b1, dummyA, Ap_i, dummyA1);
    assign sign = (A[7] ^ B[7]);
    assign Ap = (({8{A[7]}} & Ap_i) | (({8{~A[7]}}) & A));
    assign Bp = (({8{B[7]}} & Bp_i) | (({8{~B[7]}}) & B));
    assign MulA = {8'd0, ({8{Ap[0]}} & Bp)};
    Adder16Bit MM2 (MulA, {7'd0, ({8{Ap[1]}} & Bp), 1'b0}, 1'b0, dummyC, MulB, dummyC1);
    Adder16Bit MM3 (MulB, {6'd0, ({8{Ap[2]}} & Bp), 2'd0}, 1'b0, dummyD, MulC, dummyD1);
    Adder16Bit MM4 (MulC, {5'd0, ({8{Ap[3]}} & Bp), 3'd0}, 1'b0, dummyE, MulD, dummyE1);
    Adder16Bit MM5 (MulD, {4'd0, ({8{Ap[4]}} & Bp), 4'd0}, 1'b0, dummyF, MulE, dummyF1);
    Adder16Bit MM6 (MulE, {3'd0, ({8{Ap[5]}} & Bp), 5'd0}, 1'b0, dummyG, MulF, dummyG1);
    Adder16Bit MM7 (MulF, {2'd0, ({8{Ap[6]}} & Bp), 6'd0}, 1'b0, dummyH, MulG, dummyH1);
    Adder16Bit MM8 (MulG, {1'b0, ({8{Ap[7]}} & Bp), 7'd0}, 1'b0, dummyI, MulH, dummyI1);
    Adder16Bit MM9 ((~MulH), 16'd0, 1'b1, dummyJ, MulI, dummyJ1);
    assign Mul = (({16{sign}} & {1'b0, MulI[14:0]}) | (({16{~sign}}) & MulH));
    assign And = {8'd0, (A & B)};
    assign Or = {8'd0, (A | B)};
    assign Not = {8'd0, (~A)};
    assign Xor = {8'd0, (A ^ B)};
    always @ (*)
        begin
            case (S)
                Addition:
                    begin
                        O = {8'd0, Add};
                        zeroFlag = (~|Add);
                        carryFlag = carryFlag_A;
                        signFlag = Add[7];
                        overflowFlag = overflowFlag_A;
                    end
                Subtraction:
                    begin
                        O = {8'd0, Sub};
                        zeroFlag = (~|Sub);
                        carryFlag = carryFlag_S;
                        signFlag = Sub[7];
                        overflowFlag = overflowFlag_S;
                    end
                Multiplication:
                    begin
                        O = Mul;
                        zeroFlag = (~|Mul);
                        carryFlag = 1'b0;
                        signFlag = Mul[14];
                        overflowFlag = 1'b0;
                    end
                AND:
                    begin
                        O = And;
                        zeroFlag = (~|And);
                        carryFlag = 1'b0;
                        signFlag = And[7];
                        overflowFlag = 1'b0;
                    end
                OR:
                    begin
                        O = Or;
                        zeroFlag = (~|Or);
                        carryFlag = 1'b0;
                        signFlag = Or[7];
                        overflowFlag = 1'b0;
                    end
                NOT:
                    begin
                        O = Not;
                        zeroFlag = (~|Not);
                        carryFlag = 1'b0;
                        signFlag = Not[7];
                        overflowFlag = 1'b0;
                    end
                XOR:
                    begin
                        O = Xor;
                        zeroFlag = (~|Xor);
                        carryFlag = 1'b0;
                        signFlag = Xor[7];
                        overflowFlag = 1'b0;
                    end
                default:
                    begin
                        O = 16'd0;
                        zeroFlag = 1'b0;
                        carryFlag = 1'b0;
                        signFlag = 1'b0;
                        overflowFlag = 1'b0;
                    end
            endcase
        end
endmodule