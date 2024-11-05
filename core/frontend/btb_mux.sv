module btb_mux #(
    parameter int NR_ENTRIES = 8
)(
    input  logic                        clk_i,           // Clock
    input  logic                        rst_ni,          // Asynchronous reset active low
    input  logic                        flush_i,         // flush the btb
    input  logic                        debug_mode_i,
    input  logic                        checkpoint_mode_i, // swap branch predictor state
    input  logic [riscv::VLEN-1:0]      vpc_i,           // virtual PC from IF stage
    input  ariane_pkg::btb_update_t     btb_update_i,    // update btb with this information
    output ariane_pkg::btb_prediction_t [ariane_pkg::INSTR_PER_FETCH-1:0] btb_prediction_o // prediction from btb
);

    ariane_pkg::btb_prediction_t [ariane_pkg::INSTR_PER_FETCH-1:0]   btb_prediction_A, btb_prediction_B;
    ariane_pkg::btb_update_t btb_update_A, btb_update_B;

	btb #(
      .NR_ENTRIES       ( ArianeCfg.BTBEntries   )
    ) btb_A (
      .clk_i,
      .rst_ni,
      .flush_i          ( flush_bp_i       ),
      .debug_mode_i,
      .vpc_i            ( icache_vaddr_q   ),
      .btb_update_i     ( btb_update_A       ),
      .btb_prediction_o ( btb_prediction_A   )
    );

    btb #(
      .NR_ENTRIES       ( ArianeCfg.BTBEntries   )
    ) btb_B (
      .clk_i,
      .rst_ni,
      .flush_i          ( flush_bp_i       ),
      .debug_mode_i,
      .vpc_i            ( icache_vaddr_q   ),
      .btb_update_i     ( btb_update_B       ),
      .btb_prediction_o ( btb_prediction_B   )
    );

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            btb_update_A <= '0;  // Clear the input (set to zero or default value for the struct)
            btb_update_B <= '0;  // Clear the input (set to zero or default value for the struct)
        end else begin
            if (checkpoint_mode_i != 0) begin
                btb_update_B <= btb_update_i;   // Pass the input to btb_0 when mux_sel is 1
                btb_update_A <= '0;           // Set btb_update_1 to default (zero) when mux_sel is 1
            end else begin
                btb_update_B <= '0;           // Set btb_update_0 to default (zero) when mux_sel is 0
                btb_update_A <= btb_update_i;   // Pass the input to btb_1 when mux_sel is 0
            end
        end
    end

    assign btb_prediction_o = (checkpoint_mode_i) ? btb_prediction_B : btb_prediction_A;

endmodule