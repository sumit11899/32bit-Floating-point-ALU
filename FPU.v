`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////////
// Design Name   : Floating Point Unit
// Module Name   : FPU
// Target Devices: Nexys4 DDR FPGA
// Tool Versions : Vivado 2020.2
// Description   : FPU performs addition, subtraction, multiplication and division based on already-implemented ALU
//////////////////////////////////////////////////////////////////////////////////
module FPU (input clock,input reset,input [31:0] A,input [31:0] B,input [1:0] S,output reg [31:0] O,output reg done);
    // FPU-related operations
    parameter [1:0] Addition = 2'b00,Subtraction = 2'b01,Multiplication = 2'b10,Division = 2'b11;
    wire [31:0] add, sub, mul, div; // outputs
    wire doneA, doneS, doneM, doneD;
    FPUAdder FPUA (clock, reset, A, B, add, doneA);
    FPUSubtractor FPUS (clock, reset, A, B, sub, doneS);
    FPUMultiplier FPUM (A, B, mul, doneM);
    FPUDivider FPUD (clock, reset, A, B, div, doneD);
    always @ (*)
        begin
            case (S)
                Addition:
                    begin
                        O <= add;
                        done <= doneA;
                    end
                Subtraction:
                    begin
                        O <= sub;
                        done <= doneS;
                    end
                Multiplication:
                    begin
                        O <= mul;
                        done <= doneM;
                    end
                Division:
                    begin
                        O <= div;
                        done <= doneD;
                    end
            endcase
        end
endmodule
module FPUAdder (input clock,input reset,input [31:0] A,input [31:0] B,output [31:0] O,output reg done);
    // ALU-related operations
    parameter [2:0] ADD = 3'b000,SUB = 3'b001,MUL = 3'b010,AND = 3'b011,OR = 3'b100,NOT = 3'b101,XOR = 3'b110;
    wire S_A, S_B, H_A, H_B; // sign bits, hidden bits
    wire [7:0] E_A, E_B;     // exponents
    wire [7:0] E_B_i;
    wire [15:0] E_diff;      // difference in exponents
    reg [15:0] E_diff_i;
    wire [15:0] E_diff_j, E_diff_abs;
    wire [23:0] F_A, F_B;    // mantissae
    wire [23:0] F_A_i, F_A_j;
    reg [23:0] F_B_i;
    wire zero, carry, sign, overflow;        // ALU flags
    wire dummy1, dummy2, dummy3, dummy4;
    wire dummy5, dummy6, dummy7, dummy8;
    wire dummy9, dummy10, dummy11, dummy12;
    wire dummy13, dummy14, dummy15, dummy16;
    wire dummy17, dummy18, dummy19, dummy20;
    wire [31:0] A_i, B_i, B_j;               // intermediate A and B
    wire [23:0] F_B_2c;                      // 2's complement of B
    wire [23:0] sumAB, sumAB_i, sumAB_j, sumAB_2c, sumAB_yc; // sum of A and B (or 2's complement of B)
    wire dummy21, dummy22, dummy23, dummy31;
    wire [7:0] dummy24, dummy25, dummy26, dummy27;
    wire [7:0] dummy28, dummy29, dummy30, dummy47;
    wire dummy32, dummy33, dummy34, dummy35;
    wire dummy36, dummy37, dummy38, dummy39;
    wire dummy40, dummy41, dummy42, dummy43;
    wire dummy44, dummy45, dummy46, dummy48;
    wire carrySumAB;                                // denotes carry out for sum of A and B (or 2s complement of B)
    wire signAB;                                    // denotes whether A and B have the same sign or not
    wire dummy49, dummy50, dummy51, dummy52;
    wire dummy53, dummy54, dummy55, dummy56;
    wire dummy57, dummy58, dummy59, dummy60;
    wire dummy61, dummy62, dummy63, dummy64;
    wire dummy65, dummy66, dummy67, dummy68;
    wire dummy75, dummy76, dummy77, dummy78;
    wire [7:0] dummy69, dummy70, dummy71, dummy72, dummy73, dummy74;
    wire [23:0] diffFAB;                        // difference of mantissae of A and B
    wire AgB, BgA;                              // |A| > |B| or |B| > |A|
    wire signGtr;                               // sign of the number greater in magnitude
    reg [7:0] count;
    wire [15:0] count_i;
    wire [7:0] dummy79, dummy80, dummy81;
    wire dummy82, dummy83, dummy84, dummy85;
    wire dummy86, dummy87, dummy88, dummy89;
    wire dummy90, dummy91, dummy92, dummy93;
    wire dummy94, dummy95, dummy96, dummy97;
    reg [23:0] sumAB_reg;
    wire [7:0] E_inr, E_sub;
    wire [7:0] dummy106, dummy107;
    wire dummy98, dummy99, dummy100, dummy101;
    wire dummy102, dummy103, dummy104, dummy105;
    wire dummy108, dummy109, dummy110, dummy111;
    wire [3:0] dummyi [0:50];
    wire [7:0] dummy8i [0:50];
    wire isZero, isZeroA, iszeroB; // if either input is 0.0
    reg signal, moved;
    assign isZeroA = (~|A[30:0]);
    assign isZeroB = (~|B[30:0]);
    assign isZero = (((A[31] ^ B[31]) & (~|(A[30:0] ^ B[30:0]))) | ((~A[31]) & (~B[31]) & (~|A[30:0]) & (~|B[30:0])));
    ALU expDiff1Adder (A[30:23], B[30:23], SUB, E_diff, zero, carry, sign, overflow);
    assign A_i = (({32{~carry}} & B) | ({32{carry}} & A));
    assign B_i = (({32{~carry}} & A) | ({32{carry}} & B));
    assign S_A = A_i[31];
    assign S_B = B_i[31];
    assign E_A = A_i[30:23];
    assign E_B = B_i[30:23];
    assign H_A = (|E_A);
    assign H_B = (|E_B);
    assign F_A = {H_A, A_i[22:0]};
    assign F_B = {H_B, B_i[22:0]};
    ALU expDiff2Adder (E_A, E_B, SUB, E_diff_abs, dummy108, dummy109, dummy110, dummy111);
    ALU expAddDiffAdder (E_B, E_diff_abs[7:0], ADD, {dummy24, E_B_i}, dummy1, dummy2, dummy3, dummy4);
    ALU dcrEdiffAdder (E_diff_i[7:0], 8'd1, SUB, E_diff_j, dummy5, dummy6, dummy7, dummy8);
    always @ (posedge clock or negedge reset)
        begin
            if (~reset)
                begin
                    F_B_i <= F_B;
                    E_diff_i <= E_diff_abs;
                    signal <= 1'b0;
                end
            else
                begin
                    if (|E_diff_i[7:0])
                        begin
                            F_B_i[23:0] <= {1'b0, F_B_i[23:1]};
                            E_diff_i[7:0] <= E_diff_j[7:0];
                        end
                    else
                        signal <= 1'b1;
                end
        end
    // now normalized values are {S_A, E_A, F_A[22:0]} and {S_B, E_B_i, F_B_i[22:0]}
    assign signAB = (A[31] ^ B[31]);
    ALU twosCplB1Adder ({~F_B_i[7], ~F_B_i[6], ~F_B_i[5], ~F_B_i[4], ~F_B_i[3], ~F_B_i[2], ~F_B_i[1], ~F_B_i[0]}, 8'd1, ADD, {dummy25, F_B_2c[7:0]}, dummy9, dummy10, dummy11, dummy12);
    ALU twosCplB2Adder ({~F_B_i[15], ~F_B_i[14], ~F_B_i[13], ~F_B_i[12], ~F_B_i[11], ~F_B_i[10], ~F_B_i[9], ~F_B_i[8]}, {7'd0, dummy10}, ADD, {dummy26, F_B_2c[15:8]}, dummy13, dummy14, dummy15, dummy16);
    ALU twosCplB3Adder ({~F_B_i[23], ~F_B_i[22], ~F_B_i[21], ~F_B_i[20], ~F_B_i[19], ~F_B_i[18], ~F_B_i[17], ~F_B_i[16]}, {7'd0, dummy14}, ADD, {dummy27, F_B_2c[23:16]}, dummy17, dummy18, dummy19, dummy20);
    assign B_j = (({24{signAB}} & F_B_2c[23:0]) | ({24{~signAB}} & F_B_i[23:0]));
    ALU addAB1Adder (A_i[7:0], B_j[7:0], ADD, {dummy28, sumAB[7:0]}, dummy21, dummy22, dummy23, dummy31);
    ALU addAB2Adder (A_i[15:8], B_j[15:8], ADD, {dummy29, sumAB_i[15:8]}, dummy32, dummy33, dummy34, dummy35);
    ALU addAB3Adder (sumAB_i[15:8], {7'd0, dummy22}, ADD, {dummy30, sumAB[15:8]}, dummy36, dummy37, dummy38, dummy39);
    ALU addAB4Adder ({H_A, A_i[22:16]}, B_j[23:16], ADD, {dummy47, sumAB_i[23:16]}, dummy40, dummy41, dummy42, dummy43);
    ALU addAB5Adder (sumAB_i[23:16], {7'd0, dummy33}, ADD, {dummy8i[0], sumAB_j[23:16]}, dummy44, dummy45, dummy46, dummy48);
    ALU addAB6Adder (sumAB_j[23:16], {7'd0, dummy36}, ADD, {dummy8i[1], sumAB[23:16]}, dummyi[0][3], dummyi[0][2], dummyi[0][1], dummyi[0][0]);
    assign carrySumAB = dummy41;
    ALU FDiff1Adder (F_A[7:0], F_B_i[7:0], SUB, {dummy69, diffFAB[7:0]}, dummy49, dummy50, dummy51, dummy52);
    ALU FDiff2Adder (F_A[15:8], {7'd0, dummy50}, SUB, {dummy70, F_A_i[15:8]}, dummy53, dummy54, dummy55, dummy56);
    ALU FDiff3Adder (F_A_i[15:8], F_B_i[15:8], SUB, {dummy71, diffFAB[15:8]}, dummy57, dummy58, dummy59, dummy60);
    ALU FDiff4Adder (F_A[23:16], {7'd0, dummy54}, SUB, {dummy72, F_A_i[23:16]}, dummy61, dummy62, dummy63, dummy64);
    ALU FDiff5Adder (F_A_i[23:16], {7'd0, dummy58}, SUB, {dummy73, F_A_j[23:16]}, dummy65, dummy66, dummy67, dummy68);
    ALU FDiff6Adder (F_A_j[23:16], F_B_i[23:16], SUB, {dummy74, diffFAB[23:16]}, dummy75, dummy76, dummy77, dummy78);
    assign AgB = ((|E_diff_abs) | ((~E_diff_abs) & (~dummy109) & (~(dummy62 | dummy66 | dummy76))));
    assign BgA = (~AgB);
    assign signGtr = (((~signAB) & S_A) | (signAB & ((AgB & S_A) | (BgA & S_B))));
    ALU twosCplS1Adder ({~sumAB[7], ~sumAB[6], ~sumAB[5], ~sumAB[4], ~sumAB[3], ~sumAB[2], ~sumAB[1], ~sumAB[0]}, 8'd1, ADD, {dummy79, sumAB_2c[7:0]}, dummy82, dummy83, dummy84, dummy85);
    ALU twosCplS2Adder ({~sumAB[15], ~sumAB[14], ~sumAB[13], ~sumAB[12], ~sumAB[11], ~sumAB[10], ~sumAB[9], ~sumAB[8]}, {7'd0, dummy83}, ADD, {dummy80, sumAB_2c[15:8]}, dummy86, dummy87, dummy88, dummy89);
    ALU twosCplS3Adder ({~sumAB[23], ~sumAB[22], ~sumAB[21], ~sumAB[20], ~sumAB[19], ~sumAB[18], ~sumAB[17], ~sumAB[16]}, {7'd0, dummy87}, ADD, {dummy81, sumAB_2c[23:16]}, dummy90, dummy91, dummy92, dummy93);
    ALU countInrAdder (count, 8'd1, ADD, count_i, dummy94, dummy95, dummy96, dummy97);
    always @ (posedge clock or negedge reset)
        begin
            if (~reset)
                begin
                    count <= 8'd0;
                    moved <= 1'b0;
                    done <= 1'b0;
                    sumAB_reg <= 24'd16777215;
                end
            else
                begin
                    if (signal & (~moved))
                        begin
                            sumAB_reg <= sumAB;
                            moved <= 1'b1;
                        end
                    else if ((~sumAB_reg[23]) & (~isZeroA) & (~isZeroB))
                        begin
                            sumAB_reg <= {sumAB_reg[22:0], 1'b0};
                            count <= count_i[7:0];
                        end
                    else if (~&sumAB_reg)
                        done <= 1'b1;
                end
        end
    assign sumAB_yc = {1'b1, sumAB[23:1]};
    ALU addExpAdder (E_B_i, 8'd1, ADD, {dummy106, E_inr}, dummy98, dummy99, dummy100, dummy101);
    ALU subExpAdder (E_B_i, count, SUB, {dummy107, E_sub}, dummy102, dummy103, dummy104, dummy105);
    assign O[31] = (((~signAB) & S_A) | (signAB & signGtr));
    assign O[30:23] = (({8{isZero}} & 8'd0) | ({8{~isZero}} & ({8{signAB}} & ((({8{carrySumAB}} & E_sub) | ({8{~carrySumAB}} & E_B_i))) | ({8{~signAB}} & (({8{carrySumAB}} & E_inr) | ({8{~carrySumAB}} & E_B_i))))));
    assign O[22:0] = (({23{isZero}} & 23'd0) | ({23{~isZero}} & (({23{signAB}} & (({23{carrySumAB}} & sumAB_reg[22:0]) | ({23{~carrySumAB}} & (({23{sumAB[23]}} & sumAB_2c[22:0]) | ({23{~sumAB[23]}} & sumAB[22:0]))))) | ({23{~signAB}} & (({23{carrySumAB}} & sumAB_yc[22:0]) | ({23{~carrySumAB}} & sumAB[22:0]))))));
endmodule
module FPUSubtractor (input clock,input reset,input [31:0] A,input [31:0] B,output [31:0] O,output done);
    FPUAdder SubAddSubtractor (clock, reset, A, {~B[31], B[30:0]}, O, done);
endmodule
module FPUMultiplier (input [31:0] A,input [31:0] B,output [31:0] O,output done);
    // ALU-related operations
    parameter [2:0] ADD = 3'b000,SUB = 3'b001,MUL = 3'b010,AND = 3'b011,OR = 3'b100,NOT = 3'b101,XOR = 3'b110;
    wire isZeroA, isZeroB, isZero;
    wire H_A, H_B;
    wire [23:0] F_A, F_B;
    wire [3:0] dummyk [0:1];
    wire [7:0] dummy1, dummy2, dummy3, dummy4;
    wire [7:0] E_B_b, E_S, E_S_i;
    wire [3:0] dummyj [0:2];
    wire [3:0] dummyF [63:0];
    wire [1:0] dummyM [15:0];
    wire [13:0] multiplicand [15:0];
    wire [15:0] mul1_i, mul1, carry2;
    wire [15:0] mul2_i, mul2_j, mul2_k, mul2_l, mul2, carry3_i, carry3_j, carry3_k, carry3;
    wire [15:0] mul3_i, mul3_j, mul3_k, mul3_l, mul3_m, mul3_n, mul3, carry4_i, carry4_j, carry4_k, carry4_l, carry4_m, carry4;
    wire [15:0] mul4_i, mul4_j, mul4_k, mul4_l, mul4_m, mul4_n, mul4, carry5_i, carry5_j, carry5_k, carry5_l, carry5_m, carry5;
    wire [15:0] mul5_i, mul5_j, mul5_k, mul5_l, mul5, carry6_i, carry6_j, carry6_k, carry6;
    wire [15:0] mul6_i, mul6_j, mul6;
    wire [3:0] dummyi [0:50];
    wire [47:0] mul;
    assign isZeroA = (~|A[30:0]);
    assign isZeroB = (~|B[30:0]);
    assign isZero = (isZeroA | isZeroB);
    assign H_A = (|A[30:23]);
    assign H_B = (|B[30:23]);
    assign F_A = {H_A, A[22:0]};
    assign F_B = {H_B, B[22:0]};
    ALU expSubBiasMultiplier (B[30:23], 8'd127, SUB, {dummy1, E_B_b}, dummyk[0][3], dummyk[0][2], dummyk[0][1], dummyk[0][0]);
    ALU expAddMultiplier (A[30:23], E_B_b, ADD, {dummy2, E_S}, dummyk[1][3], dummyk[1][2], dummyk[1][1], dummyk[1][0]);
    ALU manMul11Multiplier ({1'b0, F_A[6:0]}, {1'b0, F_B[6:0]}, MUL, {dummyM[0], multiplicand[0]}, dummyF[0][3], dummyF[0][2], dummyF[0][1], dummyF[0][0]);
    ALU manMul12Multiplier ({1'b0, F_A[6:0]}, {1'b0, F_B[13:7]}, MUL, {dummyM[1], multiplicand[1]}, dummyF[1][3], dummyF[1][2], dummyF[1][1], dummyF[1][0]);
    ALU manMul13Multiplier ({1'b0, F_A[6:0]}, {1'b0, F_B[20:14]}, MUL, {dummyM[2], multiplicand[2]}, dummyF[2][3], dummyF[2][2], dummyF[2][1], dummyF[2][0]);
    ALU manMul14Multiplier ({1'b0, F_A[6:0]}, {5'd0, F_B[23:21]}, MUL, {dummyM[3], multiplicand[3]}, dummyF[3][3], dummyF[3][2], dummyF[3][1], dummyF[3][0]);
    ALU manMul21Multiplier ({1'b0, F_A[13:7]}, {1'b0, F_B[6:0]}, MUL, {dummyM[4], multiplicand[4]}, dummyF[4][3], dummyF[4][2], dummyF[4][1], dummyF[4][0]);
    ALU manMul22Multiplier ({1'b0, F_A[13:7]}, {1'b0, F_B[13:7]}, MUL, {dummyM[5], multiplicand[5]}, dummyF[5][3], dummyF[5][2], dummyF[5][1], dummyF[5][0]);
    ALU manMul23Multiplier ({1'b0, F_A[13:7]}, {1'b0, F_B[20:14]}, MUL, {dummyM[6], multiplicand[6]}, dummyF[6][3], dummyF[6][2], dummyF[6][1], dummyF[6][0]);
    ALU manMul24Multiplier ({1'b0, F_A[13:7]}, {5'd0, F_B[23:21]}, MUL, {dummyM[7], multiplicand[7]}, dummyF[7][3], dummyF[7][2], dummyF[7][1], dummyF[7][0]);
    ALU manMul31Multiplier ({1'b0, F_A[20:14]}, {1'b0, F_B[6:0]}, MUL, {dummyM[8], multiplicand[8]}, dummyF[8][3], dummyF[8][2], dummyF[8][1], dummyF[8][0]);
    ALU manMul32Multiplier ({1'b0, F_A[20:14]}, {1'b0, F_B[13:7]}, MUL, {dummyM[9], multiplicand[9]}, dummyF[9][3], dummyF[9][2], dummyF[9][1], dummyF[9][0]);
    ALU manMul33Multiplier ({1'b0, F_A[20:14]}, {1'b0, F_B[20:14]}, MUL, {dummyM[10], multiplicand[10]}, dummyF[10][3], dummyF[10][2], dummyF[10][1], dummyF[10][0]);
    ALU manMul34Multiplier ({1'b0, F_A[20:14]}, {5'd0, F_B[23:21]}, MUL, {dummyM[11], multiplicand[11]}, dummyF[11][3], dummyF[11][2], dummyF[11][1], dummyF[11][0]);
    ALU manMul41Multiplier ({5'd0, F_A[23:21]}, {1'b0, F_B[6:0]}, MUL, {dummyM[12], multiplicand[12]}, dummyF[12][3], dummyF[12][2], dummyF[12][1], dummyF[12][0]);
    ALU manMul42Multiplier ({5'd0, F_A[23:21]}, {1'b0, F_B[13:7]}, MUL, {dummyM[13], multiplicand[13]}, dummyF[13][3], dummyF[13][2], dummyF[13][1], dummyF[13][0]);
    ALU manMul43Multiplier ({5'd0, F_A[23:21]}, {1'b0, F_B[20:14]}, MUL, {dummyM[14], multiplicand[14]}, dummyF[14][3], dummyF[14][2], dummyF[14][1], dummyF[14][0]);
    ALU manMul44Multiplier ({5'd0, F_A[23:21]}, {5'd0, F_B[23:21]}, MUL, {dummyM[15], multiplicand[15]}, dummyF[15][3], dummyF[15][2], dummyF[15][1], dummyF[15][0]);
    assign mul[6:0] = multiplicand[0][6:0];
    ALU mulAdd11Multiplier ({1'b0, multiplicand[0][13:7]}, {1'b0, multiplicand[1][6:0]}, ADD, mul1_i, dummyi[0][3], dummyi[0][2], dummyi[0][1], dummyi[0][0]);
    ALU mulAdd12Multiplier ({1'b0, mul1_i[6:0]}, {1'b0, multiplicand[4][6:0]}, ADD, mul1, dummyi[1][3], dummyi[1][2], dummyi[1][1], dummyi[1][0]);
    ALU mulAdd1CMultiplier ({7'd0, mul1_i[7]}, {7'd0, mul1[7]}, ADD, carry2, dummyi[2][3], dummyi[2][2], dummyi[2][1], dummyi[2][0]);
    assign mul[13:7] = mul1[6:0];
    ALU mulAdd21Multiplier (carry2[7:0], {1'b0, multiplicand[1][13:7]}, ADD, mul2_i, dummyi[3][3], dummyi[3][2], dummyi[3][1], dummyi[3][0]);
    ALU mulAdd22Multiplier ({1'b0, mul2_i[6:0]}, {1'b0, multiplicand[2][6:0]}, ADD, mul2_j, dummyi[4][3], dummyi[4][2], dummyi[4][1], dummyi[4][0]);
    ALU mulAdd23Multiplier ({1'b0, mul2_j[6:0]}, {1'b0, multiplicand[4][13:7]}, ADD, mul2_k, dummyi[5][3], dummyi[5][2], dummyi[5][1], dummyi[5][0]);
    ALU mulAdd24Multiplier ({1'b0, mul2_k[6:0]}, {1'b0, multiplicand[5][6:0]}, ADD, mul2_l, dummyi[6][3], dummyi[6][2], dummyi[6][1], dummyi[6][0]);
    ALU mulAdd25Multiplier ({1'b0, mul2_l[6:0]}, {1'b0, multiplicand[8][6:0]}, ADD, mul2, dummyi[7][3], dummyi[7][2], dummyi[7][1], dummyi[7][0]);
    ALU mulAdd2C1Multiplier ({7'd0, mul2_i[7]}, {7'd0, mul2_j[7]}, ADD, carry3_i, dummyi[8][3], dummyi[8][2], dummyi[8][1], dummyi[8][0]);
    ALU mulAdd2C2Multiplier (carry3_i[7:0], {7'd0, mul2_k[7]}, ADD, carry3_j, dummyi[9][3], dummyi[9][2], dummyi[9][1], dummyi[9][0]);
    ALU mulAdd2C3Multiplier (carry3_j[7:0], {7'd0, mul2_l[7]}, ADD, carry3_k, dummyi[10][3], dummyi[10][2], dummyi[10][1], dummyi[10][0]);
    ALU mulAdd2C4Multiplier (carry3_k[7:0], {7'd0, mul2[7]}, ADD, carry3, dummyi[11][3], dummyi[11][2], dummyi[11][1], dummyi[11][0]);
    assign mul[20:14] = mul2[6:0];
    ALU mulAdd31Multiplier (carry3[7:0], {1'b0, multiplicand[2][13:7]}, ADD, mul3_i, dummyi[12][3], dummyi[12][2], dummyi[12][1], dummyi[12][0]);
    ALU mulAdd32Multiplier ({1'b0, mul3_i[6:0]}, {1'b0, multiplicand[3][6:0]}, ADD, mul3_j, dummyi[13][3], dummyi[13][2], dummyi[13][1], dummyi[13][0]);
    ALU mulAdd33Multiplier ({1'b0, mul3_j[6:0]}, {1'b0, multiplicand[5][13:7]}, ADD, mul3_k, dummyi[14][3], dummyi[14][2], dummyi[14][1], dummyi[14][0]);
    ALU mulAdd34Multiplier ({1'b0, mul3_k[6:0]}, {1'b0, multiplicand[6][6:0]}, ADD, mul3_l, dummyi[15][3], dummyi[15][2], dummyi[15][1], dummyi[15][0]);
    ALU mulAdd35Multiplier ({1'b0, mul3_l[6:0]}, {1'b0, multiplicand[8][13:7]}, ADD, mul3_m, dummyi[16][3], dummyi[16][2], dummyi[16][1], dummyi[16][0]);
    ALU mulAdd36Multiplier ({1'b0, mul3_m[6:0]}, {1'b0, multiplicand[9][6:0]}, ADD, mul3_n, dummyi[17][3], dummyi[17][2], dummyi[17][1], dummyi[17][0]);
    ALU mulAdd37Multiplier ({1'b0, mul3_n[6:0]}, {1'b0, multiplicand[12][6:0]}, ADD, mul3, dummyi[18][3], dummyi[18][2], dummyi[18][1], dummyi[18][0]);
    ALU mulAdd3C1Multiplier ({7'd0, mul3_i[7]}, {7'd0, mul3_j[7]}, ADD, carry4_i, dummyi[19][3], dummyi[19][2], dummyi[19][1], dummyi[19][0]);
    ALU mulAdd3C2Multiplier (carry4_i[7:0], {7'd0, mul3_k[7]}, ADD, carry4_j, dummyi[20][3], dummyi[20][2], dummyi[20][1], dummyi[20][0]);
    ALU mulAdd3C3Multiplier (carry4_j[7:0], {7'd0, mul3_l[7]}, ADD, carry4_k, dummyi[21][3], dummyi[21][2], dummyi[21][1], dummyi[21][0]);
    ALU mulAdd3C4Multiplier (carry4_k[7:0], {7'd0, mul3_m[7]}, ADD, carry4_l, dummyi[22][3], dummyi[22][2], dummyi[22][1], dummyi[22][0]);
    ALU mulAdd3C5Multiplier (carry4_l[7:0], {7'd0, mul3_n[7]}, ADD, carry4_m, dummyi[23][3], dummyi[23][2], dummyi[23][1], dummyi[23][0]);
    ALU mulAdd3C6Multiplier (carry4_m[7:0], {7'd0, mul3[7]}, ADD, carry4, dummyi[24][3], dummyi[24][2], dummyi[24][1], dummyi[24][0]);
    assign mul[27:21] = mul3[6:0];
    ALU mulAdd41Multiplier (carry4[7:0], {5'd0, multiplicand[3][9:7]}, ADD, mul4_i, dummyi[25][3], dummyi[25][2], dummyi[25][1], dummyi[25][0]);
    ALU mulAdd42Multiplier ({1'b0, mul4_i[6:0]}, {1'b0, multiplicand[6][13:7]}, ADD, mul4_j, dummyi[26][3], dummyi[26][2], dummyi[26][1], dummyi[26][0]);
    ALU mulAdd43Multiplier ({1'b0, mul4_j[6:0]}, {1'b0, multiplicand[7][6:0]}, ADD, mul4_k, dummyi[27][3], dummyi[27][2], dummyi[27][1], dummyi[27][0]);
    ALU mulAdd44Multiplier ({1'b0, mul4_k[6:0]}, {1'b0, multiplicand[9][13:7]}, ADD, mul4_l, dummyi[28][3], dummyi[28][2], dummyi[28][1], dummyi[28][0]);
    ALU mulAdd45Multiplier ({1'b0, mul4_l[6:0]}, {1'b0, multiplicand[10][6:0]}, ADD, mul4_m, dummyi[29][3], dummyi[29][2], dummyi[29][1], dummyi[29][0]);
    ALU mulAdd46Multiplier ({1'b0, mul4_m[6:0]}, {5'd0, multiplicand[12][9:7]}, ADD, mul4_n, dummyi[30][3], dummyi[30][2], dummyi[30][1], dummyi[30][0]);
    ALU mulAdd47Multiplier ({1'b0, mul4_n[6:0]}, {1'b0, multiplicand[13][6:0]}, ADD, mul4, dummyi[31][3], dummyi[31][2], dummyi[31][1], dummyi[31][0]);
    ALU mulAdd4C1Multiplier ({7'd0, mul4_i[7]}, {7'd0, mul4_j[7]}, ADD, carry5_i, dummyi[32][3], dummyi[32][2], dummyi[32][1], dummyi[32][0]);
    ALU mulAdd4C2Multiplier (carry5_i[7:0], {7'd0, mul4_k[7]}, ADD, carry5_j, dummyi[33][3], dummyi[33][2], dummyi[33][1], dummyi[33][0]);
    ALU mulAdd4C3Multiplier (carry5_j[7:0], {7'd0, mul4_l[7]}, ADD, carry5_k, dummyi[34][3], dummyi[34][2], dummyi[34][1], dummyi[34][0]);
    ALU mulAdd4C4Multiplier (carry5_k[7:0], {7'd0, mul4_m[7]}, ADD, carry5_l, dummyi[35][3], dummyi[35][2], dummyi[35][1], dummyi[35][0]);
    ALU mulAdd4C5Multiplier (carry5_l[7:0], {7'd0, mul4_n[7]}, ADD, carry5_m, dummyi[36][3], dummyi[36][2], dummyi[36][1], dummyi[36][0]);
    ALU mulAdd4C6Multiplier (carry5_m[7:0], {7'd0, mul4[7]}, ADD, carry5, dummyi[37][3], dummyi[37][2], dummyi[37][1], dummyi[37][0]);
    assign mul[34:28] = mul4[6:0];
    ALU mulAdd51Multiplier (carry5[7:0], {5'd0, multiplicand[7][9:7]}, ADD, mul5_i, dummyi[38][3], dummyi[38][2], dummyi[38][1], dummyi[38][0]);
    ALU mulAdd52Multiplier ({1'b0, mul5_i[6:0]}, {1'b0, multiplicand[10][13:7]}, ADD, mul5_j, dummyi[39][3], dummyi[39][2], dummyi[39][1], dummyi[39][0]);
    ALU mulAdd53Multiplier ({1'b0, mul5_j[6:0]}, {1'b0, multiplicand[11][6:0]}, ADD, mul5_k, dummyi[40][3], dummyi[40][2], dummyi[40][1], dummyi[40][0]);
    ALU mulAdd54Multiplier ({1'b0, mul5_k[6:0]}, {5'd0, multiplicand[13][9:7]}, ADD, mul5_l, dummyi[41][3], dummyi[41][2], dummyi[41][1], dummyi[41][0]);
    ALU mulAdd55Multiplier ({1'b0, mul5_l[6:0]}, {1'b0, multiplicand[14][6:0]}, ADD, mul5, dummyi[42][3], dummyi[42][2], dummyi[42][1], dummyi[42][0]);
    ALU mulAdd5C1Multiplier ({7'd0, mul5_i[7]}, {7'd0, mul5_j[7]}, ADD, carry6_i, dummyi[43][3], dummyi[43][2], dummyi[43][1], dummyi[43][0]);
    ALU mulAdd5C2Multiplier (carry6_i[7:0], {7'd0, mul5_k[7]}, ADD, carry6_j, dummyi[44][3], dummyi[44][2], dummyi[44][1], dummyi[44][0]);
    ALU mulAdd5C3Multiplier (carry6_j[7:0], {7'd0, mul5_l[7]}, ADD, carry6_k, dummyi[45][3], dummyi[45][2], dummyi[45][1], dummyi[45][0]);
    ALU mulAdd5C4Multiplier (carry6_k[7:0], {7'd0, mul5[7]}, ADD, carry6, dummyi[46][3], dummyi[46][2], dummyi[46][1], dummyi[46][0]);
    assign mul[41:35] = mul5[6:0];
    ALU mulAdd61Multiplier (carry6[7:0], {5'd0, multiplicand[11][9:7]}, ADD, mul6_i, dummyi[47][3], dummyi[47][2], dummyi[47][1], dummyi[47][0]);
    ALU mulAdd62Multiplier ({1'b0, mul6_i[6:0]}, {5'd0, multiplicand[14][9:7]}, ADD, mul6_j, dummyi[48][3], dummyi[48][2], dummyi[48][1], dummyi[48][0]);
    ALU mulAdd63Multiplier ({1'b0, mul6_j[6:0]}, {2'd0, multiplicand[15][5:0]}, ADD, mul6, dummyi[49][3], dummyi[49][2], dummyi[49][1], dummyi[49][0]);
    assign mul[47:42] = mul6[6:0];
    ALU expInrMultiplier (E_S, 8'd1, ADD, {dummy3, E_S_i}, dummyi[50][3], dummyi[50][2], dummyi[50][1], dummyi[50][0]);
    assign O[31] = (A[31] ^ B[31]);
    assign O[30:23] = (({8{isZero}} & 8'd0) | ({8{~isZero}} & (({8{mul[47]}} & E_S_i) | ({8{~mul[47]}} & E_S))));
    assign O[22:0] = (({23{mul[47]}} & mul[46:24]) | ({23{~mul[47]}} & mul[45:23]));
    assign done = (mul[46] | mul[47] | isZero);
endmodule
module FPUDivider (input clock,input reset,input [31:0] A,input [31:0] B,output reg [31:0] O,output reg done);
    // ALU-related operations
    parameter [2:0] ADD = 3'b000,SUB = 3'b001,MUL = 3'b010,AND = 3'b011,OR = 3'b100,NOT = 3'b101,XOR = 3'b110;
    wire isZeroA, isZeroB;
    wire H_A, H_B;
    wire [7:0] E_A, E_B;
    wire [23:0] F_A, F_B;
    wire [3:0] dummyi [0:8];
    reg [5:0] count;
    wire [5:0] count_i;
    wire [9:0] dummyc;
    reg [47:0] dividend;
    reg [47:0] divisor;
    wire [47:0] divisor_2c;
    reg [47:0] R;
    wire [47:0] diff, diff_i, diff_j, diff_k, diff_l, diff_m;
    wire [47:0] sum, sum_i, sum_j, sum_k, sum_l, sum_m;
    wire [3:0] dummyj [0:43];
    wire [7:0] dummy8i [0:50];
    wire [7:0] E_S_b, E_S, E_S_d;
    reg signal;
    assign isZeroA = (~|A[30:0]);
    assign isZeroB = (~|B[30:0]);
    assign H_A = (|A[30:23]);
    assign H_B = (|B[30:23]);
    assign E_A = (A[30:23]);
    assign E_B = (A[30:23]);
    assign F_A = {H_A, A[22:0]};
    assign F_B = {H_B, B[22:0]};
    ALU expSubDivider (A[30:23], B[30:23], SUB, {dummy8i[0], E_S_b}, dummyi[0][3], dummyi[0][2], dummyi[0][1], dummyi[0][0]);
    ALU expAddBiasDivider (E_S_b, 8'd127, ADD, {dummy8i[1], E_S}, dummyi[1][3], dummyi[1][2], dummyi[1][1], dummyi[1][0]);
    ALU expDcrDivider (E_S, 8'd1, SUB, {dummy8i[2], E_S_d}, dummyi[2][3], dummyi[2][2], dummyi[2][1], dummyi[2][0]);
    ALU twosCplDivisor1Divider ({~divisor[7], ~divisor[6], ~divisor[5], ~divisor[4], ~divisor[3], ~divisor[2], ~divisor[1], ~divisor[0]}, 8'd1, ADD, {dummy8i[3], divisor_2c[7:0]},  dummyi[3][3], dummyi[3][2], dummyi[3][1], dummyi[3][0]);
    ALU twosCplDivisor2Divider ({~divisor[15], ~divisor[14], ~divisor[13], ~divisor[12], ~divisor[11], ~divisor[10], ~divisor[9], ~divisor[8]}, {7'd0, dummyi[3][2]}, ADD, {dummy8i[4], divisor_2c[15:8]},  dummyi[4][3], dummyi[4][2], dummyi[4][1], dummyi[4][0]);
    ALU twosCplDivisor3Divider ({~divisor[23], ~divisor[22], ~divisor[21], ~divisor[20], ~divisor[19], ~divisor[18], ~divisor[17], ~divisor[16]}, {7'd0, dummyi[4][2]}, ADD, {dummy8i[5], divisor_2c[23:16]},  dummyi[5][3], dummyi[5][2], dummyi[5][1], dummyi[5][0]);
    ALU twosCplDivisor4Divider ({~divisor[31], ~divisor[30], ~divisor[29], ~divisor[28], ~divisor[27], ~divisor[26], ~divisor[25], ~divisor[24]}, {7'd0, dummyi[5][2]}, ADD, {dummy8i[6], divisor_2c[31:24]},  dummyi[6][3], dummyi[6][2], dummyi[6][1], dummyi[6][0]);
    ALU twosCplDivisor5Divider ({~divisor[39], ~divisor[38], ~divisor[37], ~divisor[36], ~divisor[35], ~divisor[34], ~divisor[33], ~divisor[32]}, {7'd0, dummyi[6][2]}, ADD, {dummy8i[7], divisor_2c[39:32]},  dummyi[7][3], dummyi[7][2], dummyi[7][1], dummyi[7][0]);
    ALU twosCplDivisor6Divider ({~divisor[47], ~divisor[46], ~divisor[45], ~divisor[44], ~divisor[43], ~divisor[42], ~divisor[41], ~divisor[40]}, {7'd0, dummyi[7][2]}, ADD, {dummy8i[8], divisor_2c[47:40]},  dummyi[8][3], dummyi[8][2], dummyi[8][1], dummyi[8][0]);
    ALU diff1Divider (R[7:0], divisor_2c[7:0], ADD, {dummy8i[9], diff[7:0]}, dummyj[1][3], dummyj[1][2], dummyj[1][1], dummyj[1][0]);
    ALU diff2Divider (R[15:8], divisor_2c[15:8], ADD, {dummy8i[10], diff_i[15:8]}, dummyj[2][3], dummyj[2][2], dummyj[2][1], dummyj[2][0]);
    ALU diff3Divider (diff_i[15:8], {7'd0, dummyj[1][2]}, ADD, {dummy8i[11], diff[15:8]}, dummyj[3][3], dummyj[3][2], dummyj[3][1], dummyj[3][0]);
    ALU diff4Divider (R[23:16], divisor_2c[23:16], ADD, {dummy8i[12], diff_i[23:16]}, dummyj[4][3], dummyj[4][2], dummyj[4][1], dummyj[4][0]);
    ALU diff5Divider (diff_i[23:16], {7'd0, dummyj[2][2]}, ADD, {dummy8i[13], diff_j[23:16]}, dummyj[5][3], dummyj[5][2], dummyj[5][1], dummyj[5][0]);
    ALU diff6Divider (diff_j[23:16], {7'd0, dummyj[3][2]}, ADD, {dummy8i[14], diff[23:16]}, dummyj[6][3], dummyj[6][2], dummyj[6][1], dummyj[6][0]);
    ALU diff7Divider (R[31:24], divisor_2c[31:24], ADD, {dummy8i[15], diff_i[31:24]}, dummyj[7][3], dummyj[7][2], dummyj[7][1], dummyj[7][0]);
    ALU diff8Divider (diff_i[31:24], {7'd0, dummyj[4][2]}, ADD, {dummy8i[16], diff_j[31:24]}, dummyj[8][3], dummyj[8][2], dummyj[8][1], dummyj[8][0]);
    ALU diff9Divider (diff_j[31:24], {7'd0, dummyj[5][2]}, ADD, {dummy8i[17], diff_k[31:24]}, dummyj[9][3], dummyj[9][2], dummyj[9][1], dummyj[9][0]);
    ALU diff10Divider (diff_k[31:24], {7'd0, dummyj[6][2]}, ADD, {dummy8i[18], diff[31:24]}, dummyj[10][3], dummyj[10][2], dummyj[10][1], dummyj[10][0]);
    ALU diff11Divider (R[39:32], divisor_2c[39:32], ADD, {dummy8i[19], diff_i[39:32]}, dummyj[11][3], dummyj[11][2], dummyj[11][1], dummyj[11][0]);
    ALU diff12Divider (diff_i[39:32], {7'd0, dummyj[7][2]}, ADD, {dummy8i[20], diff_j[39:32]}, dummyj[12][3], dummyj[12][2], dummyj[12][1], dummyj[12][0]);
    ALU diff13Divider (diff_j[39:32], {7'd0, dummyj[8][2]}, ADD, {dummy8i[21], diff_k[39:32]}, dummyj[13][3], dummyj[13][2], dummyj[13][1], dummyj[13][0]);
    ALU diff14Divider (diff_k[39:32], {7'd0, dummyj[9][2]}, ADD, {dummy8i[22], diff_l[39:32]}, dummyj[14][3], dummyj[14][2], dummyj[14][1], dummyj[14][0]);
    ALU diff15Divider (diff_l[39:32], {7'd0, dummyj[10][2]}, ADD, {dummy8i[23], diff[39:32]}, dummyj[15][3], dummyj[15][2], dummyj[15][1], dummyj[15][0]);
    ALU diff16Divider (R[47:40], divisor_2c[47:40], ADD, {dummy8i[24], diff_i[47:40]}, dummyj[16][3], dummyj[16][2], dummyj[16][1], dummyj[16][0]);
    ALU diff17Divider (diff_i[47:40], {7'd0, dummyj[11][2]}, ADD, {dummy8i[25], diff_j[47:40]}, dummyj[17][3], dummyj[17][2], dummyj[17][1], dummyj[17][0]);
    ALU diff18Divider (diff_j[47:40], {7'd0, dummyj[12][2]}, ADD, {dummy8i[26], diff_k[47:40]}, dummyj[18][3], dummyj[18][2], dummyj[18][1], dummyj[18][0]);
    ALU diff19Divider (diff_k[47:40], {7'd0, dummyj[13][2]}, ADD, {dummy8i[27], diff_l[47:40]}, dummyj[19][3], dummyj[19][2], dummyj[19][1], dummyj[19][0]);
    ALU diff20Divider (diff_l[47:40], {7'd0, dummyj[14][2]}, ADD, {dummy8i[28], diff_m[47:40]}, dummyj[20][3], dummyj[20][2], dummyj[20][1], dummyj[20][0]);
    ALU diff21Divider (diff_m[47:40], {7'd0, dummyj[15][2]}, ADD, {dummy8i[29], diff[47:40]}, dummyj[21][3], dummyj[21][2], dummyj[21][1], dummyj[21][0]);
    ALU sum1Divider (R[7:0], divisor[7:0], ADD, {dummy8i[30], sum[7:0]}, dummyj[22][3], dummyj[22][2], dummyj[22][1], dummyj[22][0]);
    ALU sum2Divider (R[15:8], divisor[15:8], ADD, {dummy8i[31], sum_i[15:8]}, dummyj[23][3], dummyj[23][2], dummyj[23][1], dummyj[23][0]);
    ALU sum3Divider (sum_i[15:8], {7'd0, dummyj[22][2]}, ADD, {dummy8i[32], sum[15:8]}, dummyj[24][3], dummyj[24][2], dummyj[24][1], dummyj[24][0]);
    ALU sum4Divider (R[23:16], divisor[23:16], ADD, {dummy8i[33], sum_i[23:16]}, dummyj[25][3], dummyj[25][2], dummyj[25][1], dummyj[25][0]);
    ALU sum5Divider (sum_i[23:16], {7'd0, dummyj[23][2]}, ADD, {dummy8i[34], sum_j[23:16]}, dummyj[26][3], dummyj[26][2], dummyj[26][1], dummyj[26][0]);
    ALU sum6Divider (sum_j[23:16], {7'd0, dummyj[24][2]}, ADD, {dummy8i[35], sum[23:16]}, dummyj[27][3], dummyj[27][2], dummyj[27][1], dummyj[27][0]);
    ALU sum7Divider (R[31:24], divisor[31:24], ADD, {dummy8i[36], sum_i[31:24]}, dummyj[28][3], dummyj[28][2], dummyj[28][1], dummyj[28][0]);
    ALU sum8Divider (sum_i[31:24], {7'd0, dummyj[25][2]}, ADD, {dummy8i[37], sum_j[31:24]}, dummyj[29][3], dummyj[29][2], dummyj[29][1], dummyj[29][0]);
    ALU sum9Divider (sum_j[31:24], {7'd0, dummyj[26][2]}, ADD, {dummy8i[38], sum_k[31:24]}, dummyj[30][3], dummyj[30][2], dummyj[30][1], dummyj[30][0]);
    ALU sum10Divider (sum_k[31:24], {7'd0, dummyj[27][2]}, ADD, {dummy8i[39], sum[31:24]}, dummyj[31][3], dummyj[31][2], dummyj[31][1], dummyj[31][0]);
    ALU sum11Divider (R[39:32], divisor[39:32], ADD, {dummy8i[40], sum_i[39:32]}, dummyj[32][3], dummyj[32][2], dummyj[32][1], dummyj[32][0]);
    ALU sum12Divider (sum_i[39:32], {7'd0, dummyj[28][2]}, ADD, {dummy8i[41], sum_j[39:32]}, dummyj[33][3], dummyj[33][2], dummyj[33][1], dummyj[33][0]);
    ALU sum13Divider (sum_j[39:32], {7'd0, dummyj[29][2]}, ADD, {dummy8i[42], sum_k[39:32]}, dummyj[34][3], dummyj[34][2], dummyj[34][1], dummyj[34][0]);
    ALU sum14Divider (sum_k[39:32], {7'd0, dummyj[30][2]}, ADD, {dummy8i[43], sum_l[39:32]}, dummyj[35][3], dummyj[35][2], dummyj[35][1], dummyj[35][0]);
    ALU sum15Divider (sum_l[39:32], {7'd0, dummyj[31][2]}, ADD, {dummy8i[44], sum[39:32]}, dummyj[36][3], dummyj[36][2], dummyj[36][1], dummyj[36][0]);
    ALU sum16Divider (R[47:40], divisor[47:40], ADD, {dummy8i[45], sum_i[47:40]}, dummyj[37][3], dummyj[37][2], dummyj[37][1], dummyj[37][0]);
    ALU sum17Divider (sum_i[47:40], {7'd0, dummyj[32][2]}, ADD, {dummy8i[46], sum_j[47:40]}, dummyj[38][3], dummyj[38][2], dummyj[38][1], dummyj[38][0]);
    ALU sum18Divider (sum_j[47:40], {7'd0, dummyj[33][2]}, ADD, {dummy8i[47], sum_k[47:40]}, dummyj[39][3], dummyj[39][2], dummyj[39][1], dummyj[39][0]);
    ALU sum19Divider (sum_k[47:40], {7'd0, dummyj[34][2]}, ADD, {dummy8i[48], sum_l[47:40]}, dummyj[40][3], dummyj[40][2], dummyj[40][1], dummyj[40][0]);
    ALU sum20Divider (sum_l[47:40], {7'd0, dummyj[35][2]}, ADD, {dummy8i[49], sum_m[47:40]}, dummyj[41][3], dummyj[41][2], dummyj[41][1], dummyj[41][0]);
    ALU sum21Divider (sum_m[47:40], {7'd0, dummyj[36][2]}, ADD, {dummy8i[50], sum[47:40]}, dummyj[42][3], dummyj[42][2], dummyj[42][1], dummyj[42][0]);
    ALU countDcrDivider ({2'd0, count}, 8'd1, SUB, {dummyc, count_i}, dummyj[43][3], dummyj[43][2], dummyj[43][1], dummyj[43][0]);
    always @ (posedge clock or negedge reset)
        begin
            if (~reset)
                begin
                    dividend = {F_A, 24'd0};
                    divisor = {24'd0, F_B};
                    R = 48'd0;
                    R = {R[46:0], dividend[47]};
                    dividend = {dividend[46:0], 1'b0};
                    count = 6'd46;
                    signal = 1'b0;
                    done = 1'b0;
                end
            else if ((|count) & (~isZeroA) & (~isZeroB))
                begin
                    if (~R[47])
                        R = diff;
                    else
                        R = sum;
                    if (~R[47])
                        dividend[0] = 1'b1;
                    else
                        dividend[0] = 1'b0;
                    R = {R[46:0], dividend[47]};
                    dividend = {dividend[46:0], 1'b0};
                    count = count_i;
                end
            else if (~signal)
                begin
                    R = {R[46:0], dividend[47]};
                    dividend = {dividend[46:0], 1'b0};
                    signal = 1'b1;
                end

            else
                done = 1'b1;
        end
    always @ (*)
        begin
            O[31] <= (A[31] ^ B[31]);
            if (isZeroA & (~isZeroB))
                O[30:0] <= 31'd0;
            else if ((~isZeroA) & isZeroB)
                begin
                    O[30:23] <= 8'd255;
                    O[22:0] <= 23'd0;
                end
            else if (isZeroA & isZeroB)
                begin
                    O[30:23] <= 8'd255;
                    O[22:0] <= 23'd127;
                end
            else
                begin
                    if (~dividend[24])
                        begin
                            O[30:23] <= E_S_d;
                            O[22:0] <= dividend[22:0];
                        end
                    else
                        begin
                            O[30:23] <= E_S;
                            O[22:0] <= dividend[23:1];
                        end
                end
        end
endmodule