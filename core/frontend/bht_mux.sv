module bht_mux #(
    parameter int unsigned NR_ENTRIES = 1024
)(
    input  logic                        clk_i,
    input  logic                        rst_ni,
    input  logic                        flush_i,
    input  logic                        debug_mode_i,
    input  logic						checkpoint_mode_i, // swap branch predictor state
    input  logic [riscv::VLEN-1:0]      vpc_i,
    input  ariane_pkg::bht_update_t     bht_update_i,
    // we potentially need INSTR_PER_FETCH predictions/cycle
    output ariane_pkg::bht_prediction_t [ariane_pkg::INSTR_PER_FETCH-1:0] bht_prediction_o
);

	ariane_pkg::bht_prediction_t [INSTR_PER_FETCH-1:0]   bht_prediction_A, bht_prediction_B;
	ariane_pkg::bht_update_t bht_update_A, bht_update_B;

	ariane_pkg::bht #(
      .NR_ENTRIES       ( ArianeCfg.BHTEntries   )
    ) bht_A (
      .clk_i,
      .rst_ni,
      .flush_i          ( flush_bp_i       ),
      .debug_mode_i,
      .vpc_i            ( icache_vaddr_q   ),
      .bht_update_i     ( bht_update_A       ),
      .bht_prediction_o ( bht_prediction_A   )
    );

    ariane_pkg::bht #(
      .NR_ENTRIES       ( ArianeCfg.BHTEntries   )
    ) bht_B (
      .clk_i,
      .rst_ni,
      .flush_i          ( flush_bp_i       ),
      .debug_mode_i,
      .vpc_i            ( icache_vaddr_q   ),
      .bht_update_i     ( bht_update_B       ),
      .bht_prediction_o ( bht_prediction_B   )
    );

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bht_update_A <= '0;  // Clear the input (set to zero or default value for the struct)
            bht_update_B <= '0;  // Clear the input (set to zero or default value for the struct)
        end else begin
            if (checkpoint_mode_i != 0) begin
                bht_update_B <= bht_update_i;   // Pass the input to btb_0 when mux_sel is 1
                bht_update_A <= '0;           // Set btb_update_1 to default (zero) when mux_sel is 1
            end else begin
                bht_update_B <= '0;           // Set btb_update_0 to default (zero) when mux_sel is 0
                bht_update_A <= bht_update_i;   // Pass the input to btb_1 when mux_sel is 0
            end
        end
    end

    assign bht_prediction_o = (checkpoint_mode_i) ? btb_prediction_B : btb_prediction_A;

endmodule