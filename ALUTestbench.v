`timescale 1 ns / 1 ps
module ALUTestbench;
    reg [7:0] A, B;
    reg [2:0] S;
    wire [15:0] O;
    wire zeroFlag, carryFlag, signFlag, overflowFlag;
    ALU ALUT (A, B, S, O, zeroFlag, carryFlag, signFlag, overflowFlag);
    integer i;
    initial
        begin
            A = 8'd0;
            B = 8'd0;
            for (i = 0; i < 8; i = i + 1)
                begin
                    S = i;
                    #20;
                end
            A = 8'd5;
            B = 8'd7;
            for (i = 0; i < 8; i = i + 1)
                begin
                    S = i;
                    #20;
                end
            A = 8'd127;
            B = 8'd63;
            for (i = 0; i < 8; i = i + 1)
                begin
                    S = i;
                    #20;
                end
            A = 8'd127;
            B = 8'd200;
            for (i = 0; i < 8; i = i + 1)
                begin
                    S = i;
                    #20;
                end
            A = 8'd255;
            B = 8'd255;
            for (i = 0; i < 8; i = i + 1)
                begin
                    S = i;
                    #20;
                end
            $finish;
        end
endmodule