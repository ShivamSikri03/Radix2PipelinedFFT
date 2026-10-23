// ==============================================================================
// Module: complex_butterfly
// Description: Radix-2 Decimation-in-Frequency (DIF) Complex Butterfly Unit
// Arithmetic: 16-bit Signed Q1.14 Fixed-Point with 1/2 Stage-Scaling and Rounding
// Author: Shivam Sikri
// ==============================================================================

module complex_butterfly #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS  = 14
)(
    // Input Complex Sample A (Q1.14)
    input  wire signed [DATA_WIDTH-1:0] a_re,
    input  wire signed [DATA_WIDTH-1:0] a_im,

    // Input Complex Sample B (Q1.14)
    input  wire signed [DATA_WIDTH-1:0] b_re,
    input  wire signed [DATA_WIDTH-1:0] b_im,

    // Complex Twiddle Factor W = W_re + j * W_im (Q1.14)
    input  wire signed [DATA_WIDTH-1:0] w_re,
    input  wire signed [DATA_WIDTH-1:0] w_im,

    // Output Complex Sample X = (A + B) / 2
    output wire signed [DATA_WIDTH-1:0] x_re,
    output wire signed [DATA_WIDTH-1:0] x_im,

    // Output Complex Sample Y = ((A - B) * W) / 2
    output wire signed [DATA_WIDTH-1:0] y_re,
    output wire signed [DATA_WIDTH-1:0] y_im
);

    // 1. Butterfly Sum with 1-bit arithmetic right shift (1/2 scaling to prevent overflow)
    wire signed [DATA_WIDTH:0] sum_re = a_re + b_re;
    wire signed [DATA_WIDTH:0] sum_im = a_im + b_im;

    assign x_re = sum_re[DATA_WIDTH:1];
    assign x_im = sum_im[DATA_WIDTH:1];

    // 2. Butterfly Difference with 1-bit arithmetic right shift
    wire signed [DATA_WIDTH:0] diff_re = a_re - b_re;
    wire signed [DATA_WIDTH:0] diff_im = a_im - b_im;

    wire signed [DATA_WIDTH-1:0] d_re = diff_re[DATA_WIDTH:1];
    wire signed [DATA_WIDTH-1:0] d_im = diff_im[DATA_WIDTH:1];

    // 3. Complex Multiplication: (d_re + j*d_im) * (w_re + j*w_im)
    //    Prod_re = d_re * w_re - d_im * w_im
    //    Prod_im = d_re * w_im + d_im * w_re
    wire signed [31:0] p_rr = d_re * w_re;
    wire signed [31:0] p_ii = d_im * w_im;
    wire signed [31:0] p_ri = d_re * w_im;
    wire signed [31:0] p_ir = d_im * w_re;

    wire signed [32:0] mult_re = p_rr - p_ii;
    wire signed [32:0] mult_im = p_ri + p_ir;

    // 4. Truncation with rounding back to Q1.14 (add 2^(FRAC_BITS-1))
    wire signed [32:0] round_offset = 33'sd1 << (FRAC_BITS - 1);
    wire signed [32:0] rounded_re   = mult_re + round_offset;
    wire signed [32:0] rounded_im   = mult_im + round_offset;

    assign y_re = rounded_re[FRAC_BITS + DATA_WIDTH - 1 : FRAC_BITS];
    assign y_im = rounded_im[FRAC_BITS + DATA_WIDTH - 1 : FRAC_BITS];

endmodule
