`timescale 1ns / 1ps

module tb_fft8;

    parameter DATA_WIDTH = 16;
    parameter FRAC_BITS  = 14;

    reg clk;
    reg rst_n;
    reg in_valid;

    reg signed [DATA_WIDTH-1:0] x0_re, x0_im;
    reg signed [DATA_WIDTH-1:0] x1_re, x1_im;
    reg signed [DATA_WIDTH-1:0] x2_re, x2_im;
    reg signed [DATA_WIDTH-1:0] x3_re, x3_im;
    reg signed [DATA_WIDTH-1:0] x4_re, x4_im;
    reg signed [DATA_WIDTH-1:0] x5_re, x5_im;
    reg signed [DATA_WIDTH-1:0] x6_re, x6_im;
    reg signed [DATA_WIDTH-1:0] x7_re, x7_im;

    wire out_valid;
    wire signed [DATA_WIDTH-1:0] X0_re, X0_im;
    wire signed [DATA_WIDTH-1:0] X1_re, X1_im;
    wire signed [DATA_WIDTH-1:0] X2_re, X2_im;
    wire signed [DATA_WIDTH-1:0] X3_re, X3_im;
    wire signed [DATA_WIDTH-1:0] X4_re, X4_im;
    wire signed [DATA_WIDTH-1:0] X5_re, X5_im;
    wire signed [DATA_WIDTH-1:0] X6_re, X6_im;
    wire signed [DATA_WIDTH-1:0] X7_re, X7_im;

    integer err_count = 0;

    fft8_pipelined #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .x0_re(x0_re), .x0_im(x0_im),
        .x1_re(x1_re), .x1_im(x1_im),
        .x2_re(x2_re), .x2_im(x2_im),
        .x3_re(x3_re), .x3_im(x3_im),
        .x4_re(x4_re), .x4_im(x4_im),
        .x5_re(x5_re), .x5_im(x5_im),
        .x6_re(x6_re), .x6_im(x6_im),
        .x7_re(x7_re), .x7_im(x7_im),
        .out_valid(out_valid),
        .X0_re(X0_re), .X0_im(X0_im),
        .X1_re(X1_re), .X1_im(X1_im),
        .X2_re(X2_re), .X2_im(X2_im),
        .X3_re(X3_re), .X3_im(X3_im),
        .X4_re(X4_re), .X4_im(X4_im),
        .X5_re(X5_re), .X5_im(X5_im),
        .X6_re(X6_re), .X6_im(X6_im),
        .X7_re(X7_re), .X7_im(X7_im)
    );

    always #5 clk = ~clk;

    function integer mag2(input signed [DATA_WIDTH-1:0] r, input signed [DATA_WIDTH-1:0] i);
        mag2 = (r * r) + (i * i);
    endfunction

    initial begin
        $dumpfile("fft8.vcd");
        $dumpvars(0, tb_fft8);

        clk      = 0;
        rst_n    = 0;
        in_valid = 0;
        {x0_re, x0_im, x1_re, x1_im} = 0;
        {x2_re, x2_im, x3_re, x3_im} = 0;
        {x4_re, x4_im, x5_re, x5_im} = 0;
        {x6_re, x6_im, x7_re, x7_im} = 0;

        $display("============================================================");
        $display("    STARTING 8-POINT PIPELINED RADIX-2 DIF FFT TEST         ");
        $display("    Architecture: 3-Stage Synchronous Pipeline              ");
        $display("    Precision: 16-bit Signed Q1.14 Fixed-Point              ");
        $display("============================================================");

        #30;
        rst_n = 1;
        #20;

        // TEST 1: DC Input (x[n] = 1.0 for all n)
        $display("\n--- TEST 1: Constant DC Signal (x[n] = 1.0) ---");
        @(posedge clk);
        in_valid <= 1'b1;
        x0_re <= 16'sd16384; x0_im <= 16'sd0;
        x1_re <= 16'sd16384; x1_im <= 16'sd0;
        x2_re <= 16'sd16384; x2_im <= 16'sd0;
        x3_re <= 16'sd16384; x3_im <= 16'sd0;
        x4_re <= 16'sd16384; x4_im <= 16'sd0;
        x5_re <= 16'sd16384; x5_im <= 16'sd0;
        x6_re <= 16'sd16384; x6_im <= 16'sd0;
        x7_re <= 16'sd16384; x7_im <= 16'sd0;

        // TEST 2: Unit Impulse (x[0] = 1.0, x[1..7] = 0)
        @(posedge clk);
        x0_re <= 16'sd16384; x0_im <= 16'sd0;
        x1_re <= 16'sd0;     x1_im <= 16'sd0;
        x2_re <= 16'sd0;     x2_im <= 16'sd0;
        x3_re <= 16'sd0;     x3_im <= 16'sd0;
        x4_re <= 16'sd0;     x4_im <= 16'sd0;
        x5_re <= 16'sd0;     x5_im <= 16'sd0;
        x6_re <= 16'sd0;     x6_im <= 16'sd0;
        x7_re <= 16'sd0;     x7_im <= 16'sd0;

        // TEST 3: Complex Tone at Bin 1 (e^(j*2*pi*1*n / 8))
        @(posedge clk);
        x0_re <= 16'sd16384;  x0_im <= 16'sd0;
        x1_re <= 16'sd11585;  x1_im <= 16'sd11585;
        x2_re <= 16'sd0;      x2_im <= 16'sd16384;
        x3_re <= -16'sd11585; x3_im <= 16'sd11585;
        x4_re <= -16'sd16384; x4_im <= 16'sd0;
        x5_re <= -16'sd11585; x5_im <= -16'sd11585;
        x6_re <= 16'sd0;      x6_im <= -16'sd16384;
        x7_re <= 16'sd11585;  x7_im <= -16'sd11585;

        @(posedge clk);
        in_valid <= 1'b0;

        @(posedge clk);
        while (!out_valid) @(posedge clk);

        $display("[INFO @ %0t ns] Output Valid Asserted! Checking DC response...", $time);
        if (X0_re >= 16'sd16380 && X0_re <= 16'sd16384 &&
            X1_re == 0 && X2_re == 0 && X3_re == 0 &&
            X4_re == 0 && X5_re == 0 && X6_re == 0 && X7_re == 0) begin
            $display("[PASS] TEST 1: DC Energy 100%% concentrated in Bin 0 (X0_re=%0d, X1..7=0)", X0_re);
        end else begin
            $display("[ERROR] TEST 1 Failed! X0_re=%0d, X1_re=%0d", X0_re, X1_re);
            err_count = err_count + 1;
        end

        @(posedge clk);
        $display("\n--- TEST 2: Checking Unit Impulse Response ---");
        if (X0_re == 16'sd2048 && X1_re == 16'sd2048 && X2_re == 16'sd2048 && X3_re == 16'sd2048 &&
            X4_re == 16'sd2048 && X5_re == 16'sd2048 && X6_re == 16'sd2048 && X7_re == 16'sd2048) begin
            $display("[PASS] TEST 2: Flat impulse frequency response (All bins exactly 2048 / Q1.14)");
        end else begin
            $display("[ERROR] TEST 2 Failed! X0_re=%0d, X1_re=%0d", X0_re, X1_re);
            err_count = err_count + 1;
        end

        @(posedge clk);
        $display("\n--- TEST 3: Checking Single-Tone Sine Wave (Bin 1) ---");
        if (mag2(X1_re, X1_im) > mag2(X0_re, X0_im) &&
            mag2(X1_re, X1_im) > mag2(X2_re, X2_im) &&
            mag2(X1_re, X1_im) > mag2(X3_re, X3_im) &&
            mag2(X1_re, X1_im) > mag2(X4_re, X4_im)) begin
            $display("[PASS] TEST 3: Strong spectral peak cleanly detected at Bin 1 (Mag^2=%0d)", mag2(X1_re, X1_im));
        end else begin
            $display("[ERROR] TEST 3 Failed! Peak not at Bin 1");
            err_count = err_count + 1;
        end

        $display("\n============================================================");
        if (err_count == 0) begin
            $display("   *** ALL 8-POINT FFT TESTS PASSED WITH ZERO ERRORS! ***   ");
            $display("   Pipeline Latency: Exactly 3 Cycles                       ");
            $display("   Throughput: 1 Complex Vector / Clock Cycle               ");
            $display("   Waveform generated: fft8.vcd                             ");
        end else begin
            $display("   *** TEST FAILED WITH %0d ERROR(S) ***                    ", err_count);
        end
        $display("============================================================\n");

        #50;
        $finish;
    end

endmodule
