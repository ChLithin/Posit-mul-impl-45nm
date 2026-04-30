`timescale 1ns / 1ps

// =============================================================================
// tb_posit_mult_paper.v
// Testbench: posit_mult_paper (DUT) vs posit_mult PaCoGen (REF)
// Every test drives identical inputs to both and compares all outputs.
// Tests: special values, unity, short mantissa, long mantissa,
//        boundary values, 5000 random vectors.
// =============================================================================

module tb_posit_mult_paper;

parameter N  = 32;
parameter es = 2;

reg  [N-1:0] in1, in2;
reg          start;

wire [N-1:0] dut_out, ref_out;
wire         dut_inf, dut_zero, dut_done;
wire         ref_inf, ref_zero, ref_done;

posit_mult_paper_param #(.N(N),.es(es)) dut (
    .in1(in1),.in2(in2),.start(start),
    .out(dut_out),.inf(dut_inf),.zero(dut_zero),.done(dut_done)
);

posit_mult #(.N(N),.es(es)) ref_dut (
    .in1(in1),.in2(in2),.start(start),
    .out(ref_out),.inf(ref_inf),.zero(ref_zero),.done(ref_done)
);

integer pass_cnt=0, fail_cnt=0, test_num=0;

task check;
    input [N-1:0] a, b;
    input [255:0] lbl;
    begin
        in1=a; in2=b; start=1; #20;
        test_num=test_num+1;
        if (dut_out===ref_out && dut_inf===ref_inf &&
            dut_zero===ref_zero && dut_done===ref_done) begin
            pass_cnt=pass_cnt+1;
        end else begin
            fail_cnt=fail_cnt+1;
            $display("FAIL #%0d  in1=%04h in2=%04h | DUT out=%04h inf=%b zero=%b | REF out=%04h inf=%b zero=%b",
                test_num,a,b,dut_out,dut_inf,dut_zero,ref_out,ref_inf,ref_zero);
        end
        #10;
    end
endtask

integer i; reg [N-1:0] ra, rb; integer seed;

initial begin
    $dumpfile("tb_posit_mult_paper.vcd");
    $dumpvars(0,tb_posit_mult_paper);
    in1=0; in2=0; start=0; #20;

    $display("=== 1. SPECIAL VALUES ===");
    check(16'h0000,16'h0000,"zero*zero");
    check(16'h0000,16'h4000,"zero*one");
    check(16'h4000,16'h0000,"one*zero");
    check(16'h8000,16'h4000,"NaR*one");
    check(16'h4000,16'h8000,"one*NaR");
    check(16'h8000,16'h8000,"NaR*NaR");
    check(16'h8000,16'h0000,"NaR*zero");
    check(16'h0000,16'h8000,"zero*NaR");

    $display("=== 2. SIGN COMBINATIONS ===");
    check(16'h4000,16'h4000,"+1*+1");
    check(16'h4000,16'hC000,"+1*-1");
    check(16'hC000,16'h4000,"-1*+1");
    check(16'hC000,16'hC000,"-1*-1");

    $display("=== 3. SHORT MANTISSA — large regime, few PPGs active ===");
    // Large regime field → shift_rg large → ctl=00 or 01 → only top PPGs fire
    check(16'h7F00,16'h7F00,"7F00*7F00");
    check(16'h7E00,16'h7E00,"7E00*7E00");
    check(16'h7C00,16'h7C00,"7C00*7C00");
    check(16'h7800,16'h7800,"7800*7800");
    check(16'h7000,16'h7000,"7000*7000");
    check(16'h6000,16'h6000,"6000*6000");
    check(16'h7F00,16'h4000,"7F00*one");
    check(16'h4000,16'h7F00,"one*7F00");
    check(16'h8100,16'h8100,"-7F00*-7F00");
    check(16'h8100,16'h7F00,"-7F00*+7F00");
    check(16'h7C00,16'h4400,"7C00*4400");
    check(16'h6800,16'h6800,"6800*6800");

    $display("=== 4. LONG MANTISSA — small regime, all PPGs active ===");
    // Small regime → shift_rg small → ctl=11 → all 16 PPGs active
    check(16'h4001,16'h4001,"4001*4001");
    check(16'h4003,16'h4003,"4003*4003");
    check(16'h400F,16'h400F,"400F*400F");
    check(16'h401F,16'h401F,"401F*401F");
    check(16'h43FF,16'h43FF,"43FF*43FF");
    check(16'h47FF,16'h47FF,"47FF*47FF");
    check(16'h43FF,16'h7F00,"43FF*7F00");
    check(16'h7F00,16'h43FF,"7F00*43FF");
    check(16'hBC01,16'h43FF,"-long*long");
    check(16'hBC01,16'hBC01,"-long*-long");

    $display("=== 5. BOUNDARY VALUES ===");
    check(16'h7FFF,16'h7FFF,"maxpos*maxpos");
    check(16'h7FFF,16'h4000,"maxpos*one");
    check(16'h0001,16'h0001,"minpos*minpos");
    check(16'h0001,16'h4000,"minpos*one");
    check(16'h7FFF,16'h0001,"maxpos*minpos");
    check(16'h3FFF,16'h3FFF,"3FFF*3FFF");
    check(16'h41FF,16'h41FF,"41FF*41FF");
    check(16'h5555,16'h5555,"5555*5555");
    check(16'hAAAA,16'hAAAA,"AAAA*AAAA");
    check(16'h1234,16'h5678,"1234*5678");
    check(16'hFEDC,16'h1234,"FEDC*1234");

    $display("=== 6. MIXED REGIME/MANTISSA ===");
    check(16'h5000,16'h5000,"5000*5000");
    check(16'h6000,16'h4001,"6000*4001");
    check(16'h4400,16'h7800,"4400*7800");
    check(16'h5800,16'h4800,"5800*4800");
    check(16'h4200,16'h4200,"4200*4200");
    check(16'h4100,16'h4100,"4100*4100");
    check(16'h4080,16'h4080,"4080*4080");
    check(16'h4040,16'h4040,"4040*4040");

    $display("=== 7. RANDOM TESTS (5000 vectors) ===");
    seed = 32'hCAFEBABE;
    for (i=0; i<5000; i=i+1) begin
        ra = $random(seed) & 16'hFFFF;
        rb = $random(seed) & 16'hFFFF;
        in1=ra; in2=rb; start=1; #20;
        test_num=test_num+1;
        if (dut_out===ref_out && dut_inf===ref_inf &&
            dut_zero===ref_zero && dut_done===ref_done) begin
            pass_cnt=pass_cnt+1;
        end else begin
            fail_cnt=fail_cnt+1;
            if (fail_cnt<=10)
                $display("RAND FAIL #%0d: in1=%04h in2=%04h DUT=%04h REF=%04h",
                    test_num,ra,rb,dut_out,ref_out);
        end
        #10;
    end
    $display("  Random done");

    $display("==========================================");
    $display("  Total : %0d", test_num);
    $display("  Pass  : %0d", pass_cnt);
    $display("  Fail  : %0d", fail_cnt);
    if (fail_cnt==0)
        $display("  ALL PASS — paper design matches PaCoGen");
    else
        $display("  *** MISMATCHES DETECTED ***");
    $display("==========================================");
    $finish;
end

initial begin #20000000; $display("TIMEOUT"); $finish; end

endmodule

/*
// =============================================================================
// posit_mult — original PaCoGen reference (included here for self-contained TB)
// This is the UNMODIFIED original. Used only as the reference for comparison.
// =============================================================================
module posit_mult(in1, in2, start, out, inf, zero, done);

function [31:0] log2;
input reg [31:0] value;
    begin
    value = value-1;
    for (log2=0; value>0; log2=log2+1)
        value = value>>1;
    end
endfunction

parameter N = 16;
parameter Bs = log2(N);
parameter es = 3;

input [N-1:0] in1, in2;
input start;
output [N-1:0] out;
output inf, zero;
output done;

wire start0= start;
wire s1 = in1[N-1];
wire s2 = in2[N-1];
wire zero_tmp1 = |in1[N-2:0];
wire zero_tmp2 = |in2[N-2:0];
wire inf1 = in1[N-1] & (~zero_tmp1),
     inf2 = in2[N-1] & (~zero_tmp2);
wire zero1 = ~(in1[N-1] | zero_tmp1),
     zero2 = ~(in2[N-1] | zero_tmp2);
assign inf = inf1 | inf2,
       zero = zero1 & zero2;

wire rc1, rc2;
wire [Bs-1:0] regime1, regime2;
wire [es-1:0] e1, e2;
wire [N-es-1:0] mant1, mant2;
wire [N-1:0] xin1 = s1 ? -in1 : in1;
wire [N-1:0] xin2 = s2 ? -in2 : in2;
data_extract_v1 #(.N(N),.es(es)) uut_de1(.in(xin1),.rc(rc1),.regime(regime1),.exp(e1),.mant(mant1));
data_extract_v1 #(.N(N),.es(es)) uut_de2(.in(xin2),.rc(rc2),.regime(regime2),.exp(e2),.mant(mant2));

wire [N-es:0] m1 = {zero_tmp1,mant1},
              m2 = {zero_tmp2,mant2};

wire mult_s = s1 ^ s2;

wire [2*(N-es)+1:0] mult_m = m1*m2;
wire mult_m_ovf = mult_m[2*(N-es)+1];
wire [2*(N-es)+1:0] mult_mN = ~mult_m_ovf ? mult_m << 1'b1 : mult_m;

wire [Bs+1:0] r1 = rc1 ? {2'b0,regime1} : -regime1;
wire [Bs+1:0] r2 = rc2 ? {2'b0,regime2} : -regime2;
wire [Bs+es+1:0] mult_e;
add_N_Cin #(.N(Bs+es+1)) uut_add_exp ({r1,e1},{r2,e2},mult_m_ovf,mult_e);

wire [es-1:0] e_o;
wire [Bs:0] r_o;
reg_exp_op #(.es(es),.Bs(Bs)) uut_reg_ro (mult_e[es+Bs+1:0],e_o,r_o);

wire [2*N-1+3:0] tmp_o = {{N{~mult_e[es+Bs+1]}},mult_e[es+Bs+1],e_o,
    mult_mN[2*(N-es):2*(N-es)-(N-es-1)+1],
    mult_mN[2*(N-es)-(N-es-1):2*(N-es)-(N-es-1)-1],
    |mult_mN[2*(N-es)-(N-es-1)-2:0]};

wire [3*N-1+3:0] tmp1_o;
DSR_right_N_S #(.N(3*N+3),.S(Bs+1)) dsr2 (
    .a({tmp_o,{N{1'b0}}}),
    .b(r_o[Bs] ? {Bs{1'b1}} : r_o),
    .c(tmp1_o));

wire L = tmp1_o[N+4], G = tmp1_o[N+3], R = tmp1_o[N+2], St = |tmp1_o[N+1:0],
     ulp = ((G & (R | St)) | (L & G & ~(R | St)));
wire [N-1:0] rnd_ulp = {{N-1{1'b0}},ulp};

wire [N:0] tmp1_o_rnd_ulp;
add_N #(.N(N)) uut_add_ulp (tmp1_o[2*N-1+3:N+3],rnd_ulp,tmp1_o_rnd_ulp);
wire [N-1:0] tmp1_o_rnd = (r_o < N-es-2) ? tmp1_o_rnd_ulp[N-1:0] : tmp1_o[2*N-1+3:N+3];

wire [N-1:0] tmp1_oN = mult_s ? -tmp1_o_rnd : tmp1_o_rnd;
assign out = inf|zero|(~mult_mN[2*(N-es)+1]) ? {inf,{N-1{1'b0}}} : {mult_s,tmp1_oN[N-1:1]},
       done = start0;

endmodule
*/