
module fft8_pipelined #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS  = 14
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         in_valid,

    // 8 Complex Inputs: x0 to x7 (Real and Imaginary channels)
    input  wire signed [DATA_WIDTH-1:0] x0_re, input wire signed [DATA_WIDTH-1:0] x0_im,
    input  wire signed [DATA_WIDTH-1:0] x1_re, input wire signed [DATA_WIDTH-1:0] x1_im,
    input  wire signed [DATA_WIDTH-1:0] x2_re, input wire signed [DATA_WIDTH-1:0] x2_im,
    input  wire signed [DATA_WIDTH-1:0] x3_re, input wire signed [DATA_WIDTH-1:0] x3_im,
    input  wire signed [DATA_WIDTH-1:0] x4_re, input wire signed [DATA_WIDTH-1:0] x4_im,
    input  wire signed [DATA_WIDTH-1:0] x5_re, input wire signed [DATA_WIDTH-1:0] x5_im,
    input  wire signed [DATA_WIDTH-1:0] x6_re, input wire signed [DATA_WIDTH-1:0] x6_im,
    input  wire signed [DATA_WIDTH-1:0] x7_re, input wire signed [DATA_WIDTH-1:0] x7_im,

    output reg                          out_valid,

    // 8 Complex Frequency Bins: X0 to X7 (in natural frequency order)
    output reg  signed [DATA_WIDTH-1:0] X0_re, output reg  signed [DATA_WIDTH-1:0] X0_im,
    output reg  signed [DATA_WIDTH-1:0] X1_re, output reg  signed [DATA_WIDTH-1:0] X1_im,
    output reg  signed [DATA_WIDTH-1:0] X2_re, output reg  signed [DATA_WIDTH-1:0] X2_im,
    output reg  signed [DATA_WIDTH-1:0] X3_re, output reg  signed [DATA_WIDTH-1:0] X3_im,
    output reg  signed [DATA_WIDTH-1:0] X4_re, output reg  signed [DATA_WIDTH-1:0] X4_im,
    output reg  signed [DATA_WIDTH-1:0] X5_re, output reg  signed [DATA_WIDTH-1:0] X5_im,
    output reg  signed [DATA_WIDTH-1:0] X6_re, output reg  signed [DATA_WIDTH-1:0] X6_im,
    output reg  signed [DATA_WIDTH-1:0] X7_re, output reg  signed [DATA_WIDTH-1:0] X7_im
);

    // -------------------------------------------------------------------------
    // Twiddle Factor Constants in Q1.14 (1.0 = 16384, sqrt(2)/2 = 11585)
    // -------------------------------------------------------------------------
    localparam signed [DATA_WIDTH-1:0] W0_RE = 16'sd16384;  // cos(0)
    localparam signed [DATA_WIDTH-1:0] W0_IM = 16'sd0;      // -sin(0)

    localparam signed [DATA_WIDTH-1:0] W1_RE = 16'sd11585;  // cos(pi/4)
    localparam signed [DATA_WIDTH-1:0] W1_IM = -16'sd11585; // -sin(pi/4)

    localparam signed [DATA_WIDTH-1:0] W2_RE = 16'sd0;      // cos(pi/2)
    localparam signed [DATA_WIDTH-1:0] W2_IM = -16'sd16384; // -sin(pi/2)

    localparam signed [DATA_WIDTH-1:0] W3_RE = -16'sd11585; // cos(3*pi/4)
    localparam signed [DATA_WIDTH-1:0] W3_IM = -16'sd11585; // -sin(3*pi/4)

    // =========================================================================
    // STAGE 1: 4 Butterflies, Distance = 4
    // =========================================================================
    wire signed [DATA_WIDTH-1:0] s1_0_re, s1_0_im, s1_4_re, s1_4_im;
    wire signed [DATA_WIDTH-1:0] s1_1_re, s1_1_im, s1_5_re, s1_5_im;
    wire signed [DATA_WIDTH-1:0] s1_2_re, s1_2_im, s1_6_re, s1_6_im;
    wire signed [DATA_WIDTH-1:0] s1_3_re, s1_3_im, s1_7_re, s1_7_im;

    complex_butterfly #(.DATA_WIDTH(DATA_WIDTH), .FRAC_BITS(FRAC_BITS)) bf1_0 (
        .a_re(x0_re), .a_im(x0_im), .b_re(x4_re), .b_im(x4_im),
        .w_re(W0_RE), .w_im(W0_IM),
        .x_re(s1_0_re), .x_im(s1_0_im), .y_re(s1_4_re), .y_im(s1_4_im)
    );

    complex_butterfly #(.DATA_WIDTH(DATA_WIDTH), .FRAC_BITS(FRAC_BITS)) bf1_1 (
        .a_re(x1_re), .a_im(x1_im), .b_re(x5_re), .b_im(x5_im),
        .w_re(W1_RE), .w_im(W1_IM),
        .x_re(s1_1_re), .x_im(s1_1_im), .y_re(s1_5_re), .y_im(s1_5_im)
    );

    complex_butterfly #(.DATA_WIDTH(DATA_WIDTH), .FRAC_BITS(FRAC_BITS)) bf1_2 (
        .a_re(x2_re), .a_im(x2_im), .b_re(x6_re), .b_im(x6_im),
        .w_re(W2_RE), .w_im(W2_IM),
        .x_re(s1_2_re), .x_im(s1_2_im), .y_re(s1_6_re), .y_im(s1_6_im)
    );

    complex_butterfly #(.DATA_WIDTH(DATA_WIDTH), .FRAC_BITS(FRAC_BITS)) bf1_3 (
        .a_re(x3_re), .a_im(x3_im), .b_re(x7_re), .b_im(x7_im),
        .w_re(W3_RE), .w_im(W3_IM),
        .x_re(s1_3_re), .x_im(s1_3_im), .y_re(s1_7_re), .y_im(s1_7_im)
    );

    // Pipeline Register 1 (Between Stage 1 and Stage 2)
    reg signed [DATA_WIDTH-1:0] r1_0_re, r1_0_im, r1_1_re, r1_1_im;
    reg signed [DATA_WIDTH-1:0] r1_2_re, r1_2_im, r1_3_re, r1_3_im;
    reg signed [DATA_WIDTH-1:0] r1_4_re, r1_4_im, r1_5_re, r1_5_im;
    reg signed [DATA_WIDTH-1:0] r1_6_re, r1_6_im, r1_7_re, r1_7_im;
    reg                         v1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v1 <= 1'b0;
            {r1_0_re, r1_0_im, r1_1_re, r1_1_im} <= {8*DATA_WIDTH{1'b0}};
            {r1_2_re, r1_2_im, r1_3_re, r1_3_im} <= {8*DATA_WIDTH{1'b0}};
            {r1_4_re, r1_4_im, r1_5_re, r1_5_im} <= {8*DATA_WIDTH{1'b0}};
            {r1_6_re, r1_6_im, r1_7_re, r1_7_im} <= {8*DATA_WIDTH{1'b0}};
        end else begin
            v1 <= in_valid;
            r1_0_re <= s1_0_re; r1_0_im <= s1_0_im;
            r1_1_re <= s1_1_re; r1_1_im <= s1_1_im;
            r1_2_re <= s1_2_re; r1_2_im <= s1_2_im;
            r1_3_re <= s1_3_re; r1_3_im <= s1_3_im;
            r1_4_re <= s1_4_re; r1_4_im <= s1_4_im;
            r1_5_re <= s1_5_re; r1_5_im <= s1_5_im;
            r1_6_re <= s1_6_re; r1_6_im <= s1_6_im;
            r1_7_re <= s1_7_re; r1_7_im <= s1_7_im;
        end
    end

   
    // STAGE 2: 4 Butterflies, Distance = 2
   
    wire signed [DATA_WIDTH-1:0] s2_0_re, s2_0_im, s2_2_re, s2_2_im;
    wire signed [DATA_WIDTH-1:0] s2_1_re, s2_1_im, s2_3_re, s2_3_im;
    wire signed [DATA_WIDTH-1:0] s2_4_re, s2_4_im, s2_6_re, s2_6_im;
    wire signed [DATA_WIDTH-1:0] s2_5_re, s2_5_im, s2_7_re, s2_7_im;

    complex_butterfly #(.DATA_WIDTH(DATA_WIDTH), .FRAC_BITS(FRAC_BITS)) bf2_0 (
        .a_re(r1_0_re), .a_im(r1_0_im), .b_re(r1_2_re), .b_im(r1_2_im),
        .w_re(W0_RE), .w_im(W0_IM),
        .x_re(s2_0_re), .x_im(s2_0_im), .y_re(s2_2_re), .y_im(s2_2_im)
    );

    complex_butterfly #(.DATA_WIDTH(DATA_WIDTH), .FRAC_BITS(FRAC_BITS)) bf2_1 (
        .a_re(r1_1_re), .a_im(r1_1_im), .b_re(r1_3_re), .b_im(r1_3_im),
        .w_re(W2_RE), .w_im(W2_IM),
        .x_re(s2_1_re), .x_im(s2_1_im), .y_re(s2_3_re), .y_im(s2_3_im)
    );

    complex_butterfly #(.DATA_WIDTH(DATA_WIDTH), .FRAC_BITS(FRAC_BITS)) bf2_2 (
        .a_re(r1_4_re), .a_im(r1_4_im), .b_re(r1_6_re), .b_im(r1_6_im),
        .w_re(W0_RE), .w_im(W0_IM),
        .x_re(s2_4_re), .x_im(s2_4_im), .y_re(s2_6_re), .y_im(s2_6_im)
    );

    complex_butterfly #(.DATA_WIDTH(DATA_WIDTH), .FRAC_BITS(FRAC_BITS)) bf2_3 (
        .a_re(r1_5_re), .a_im(r1_5_im), .b_re(r1_7_re), .b_im(r1_7_im),
        .w_re(W2_RE), .w_im(W2_IM),
        .x_re(s2_5_re), .x_im(s2_5_im), .y_re(s2_7_re), .y_im(s2_7_im)
    );

    // Pipeline Register 2 (Between Stage 2 and Stage 3)
    reg signed [DATA_WIDTH-1:0] r2_0_re, r2_0_im, r2_1_re, r2_1_im;
    reg signed [DATA_WIDTH-1:0] r2_2_re, r2_2_im, r2_3_re, r2_3_im;
    reg signed [DATA_WIDTH-1:0] r2_4_re, r2_4_im, r2_5_re, r2_5_im;
    reg signed [DATA_WIDTH-1:0] r2_6_re, r2_6_im, r2_7_re, r2_7_im;
    reg                         v2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v2 <= 1'b0;
            {r2_0_re, r2_0_im, r2_1_re, r2_1_im} <= {8*DATA_WIDTH{1'b0}};
            {r2_2_re, r2_2_im, r2_3_re, r2_3_im} <= {8*DATA_WIDTH{1'b0}};
            {r2_4_re, r2_4_im, r2_5_re, r2_5_im} <= {8*DATA_WIDTH{1'b0}};
            {r2_6_re, r2_6_im, r2_7_re, r2_7_im} <= {8*DATA_WIDTH{1'b0}};
        end else begin
            v2 <= v1;
            r2_0_re <= s2_0_re; r2_0_im <= s2_0_im;
            r2_1_re <= s2_1_re; r2_1_im <= s2_1_im;
            r2_2_re <= s2_2_re; r2_2_im <= s2_2_im;
            r2_3_re <= s2_3_re; r2_3_im <= s2_3_im;
            r2_4_re <= s2_4_re; r2_4_im <= s2_4_im;
            r2_5_re <= s2_5_re; r2_5_im <= s2_5_im;
            r2_6_re <= s2_6_re; r2_6_im <= s2_6_im;
            r2_7_re <= s2_7_re; r2_7_im <= s2_7_im;
        end
    end

    
    // STAGE 3: 4 Butterflies, Distance = 1
    
    wire signed [DATA_WIDTH-1:0] s3_0_re, s3_0_im, s3_1_re, s3_1_im;
    wire signed [DATA_WIDTH-1:0] s3_2_re, s3_2_im, s3_3_re, s3_3_im;
    wire signed [DATA_WIDTH-1:0] s3_4_re, s3_4_im, s3_5_re, s3_5_im;
    wire signed [DATA_WIDTH-1:0] s3_6_re, s3_6_im, s3_7_re, s3_7_im;

    complex_butterfly #(.DATA_WIDTH(DATA_WIDTH), .FRAC_BITS(FRAC_BITS)) bf3_0 (
        .a_re(r2_0_re), .a_im(r2_0_im), .b_re(r2_1_re), .b_im(r2_1_im),
        .w_re(W0_RE), .w_im(W0_IM),
        .x_re(s3_0_re), .x_im(s3_0_im), .y_re(s3_1_re), .y_im(s3_1_im)
    );

    complex_butterfly #(.DATA_WIDTH(DATA_WIDTH), .FRAC_BITS(FRAC_BITS)) bf3_1 (
        .a_re(r2_2_re), .a_im(r2_2_im), .b_re(r2_3_re), .b_im(r2_3_im),
        .w_re(W0_RE), .w_im(W0_IM),
        .x_re(s3_2_re), .x_im(s3_2_im), .y_re(s3_3_re), .y_im(s3_3_im)
    );

    complex_butterfly #(.DATA_WIDTH(DATA_WIDTH), .FRAC_BITS(FRAC_BITS)) bf3_2 (
        .a_re(r2_4_re), .a_im(r2_4_im), .b_re(r2_5_re), .b_im(r2_5_im),
        .w_re(W0_RE), .w_im(W0_IM),
        .x_re(s3_4_re), .x_im(s3_4_im), .y_re(s3_5_re), .y_im(s3_5_im)
    );

    complex_butterfly #(.DATA_WIDTH(DATA_WIDTH), .FRAC_BITS(FRAC_BITS)) bf3_3 (
        .a_re(r2_6_re), .a_im(r2_6_im), .b_re(r2_7_re), .b_im(r2_7_im),
        .w_re(W0_RE), .w_im(W0_IM),
        .x_re(s3_6_re), .x_im(s3_6_im), .y_re(s3_7_re), .y_im(s3_7_im)
    );

    
    // Pipeline Register 3 & Bit-Reversal Unscrambler (Output Layer)
    // DIF outputs are bit-reversed:
    // s3_0 -> X[0], s3_1 -> X[4], s3_2 -> X[2], s3_3 -> X[6],
    // s3_4 -> X[1], s3_5 -> X[5], s3_6 -> X[3], s3_7 -> X[7]
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            {X0_re, X0_im, X1_re, X1_im} <= {8*DATA_WIDTH{1'b0}};
            {X2_re, X2_im, X3_re, X3_im} <= {8*DATA_WIDTH{1'b0}};
            {X4_re, X4_im, X5_re, X5_im} <= {8*DATA_WIDTH{1'b0}};
            {X6_re, X6_im, X7_re, X7_im} <= {8*DATA_WIDTH{1'b0}};
        end else begin
            out_valid <= v2;
            X0_re <= s3_0_re; X0_im <= s3_0_im; // Bin 0
            X1_re <= s3_4_re; X1_im <= s3_4_im; // Bin 1
            X2_re <= s3_2_re; X2_im <= s3_2_im; // Bin 2
            X3_re <= s3_6_re; X3_im <= s3_6_im; // Bin 3
            X4_re <= s3_1_re; X4_im <= s3_1_im; // Bin 4
            X5_re <= s3_5_re; X5_im <= s3_5_im; // Bin 5
            X6_re <= s3_3_re; X6_im <= s3_3_im; // Bin 6
            X7_re <= s3_7_re; X7_im <= s3_7_im; // Bin 7
        end
    end

endmodule
