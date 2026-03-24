`timescale 1ns/1ps

module tb;
    reg clk, rst;

    riscky_alu dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        @(posedge clk);
        #1 rst = 0;
        repeat(30) @(posedge clk);
        $finish;
    end
endmodule
